-- dim_agent

/*
use prod.dimensional;
use stage.dimensional;
use dev.dimensional;
*/


--Dim_Agent_sp

-- create or replace procedure working.Dim_Agent_sp()
--     returns string not null
--     language javascript
-- 	execute as caller
--     as
--     $$
--
--     table_name = 'Dim_Agent';
--
--     //delete from target if record isn't in source
--     var set_query = `
--
--     merge into dimensional.Dim_Agent as target
--     using(
--
--         with maxUpdate as(
--             select
--                 key
--                 ,mlsid
--                 ,max(updated_at) as updated_at
--             from fivetran.production_mlsfarm2_public.ags
--             group by key, mlsid
--         )
--
--         select
--             target.key
--             ,target.agentMLSID
--         from
--             dimensional.dim_Agent target
--             left join(
--                 select
--                     agt.key
--                     ,agt.mlsID as agentMLSID
--                     ,agt.fullName
--                     ,agt.Email as agentEmail
--                     ,agt.MobilePhone as agentCellPhone
--                     ,agt.OfficePhone as agentOfficePhone
--                     ,agt.Address as agentAddress
--                     ,agt.City as agentCity
--                     ,agt.StateOrProvince as agentState
--                     ,agt.PostalCode as agentZipCode
--                 from
--                     fivetran.production_mlsfarm2_public.ags agt
--                     join maxUpdate mu
--                         on agt.key = mu.key
--                         and agt.mlsid = mu.mlsid
--                         and agt.updated_at = mu.updated_at
--                     -- this is to limit the number of agents we bring in
--                     join fivetran.production_mlsfarm2_public.listings l
--                         on l.listagent_id = agt.id
--                         and ifnull(upper(l._fivetran_deleted), 'FALSE') = 'FALSE'
--                 where
--                     ifnull(upper(agt._fivetran_deleted), 'FALSE') = 'FALSE'
--                     and l.calculated_date_on >= '1/1/2022'
--
--                 union select '0', '0', null, null, null, null, null, null, null, null
--
--             ) source
--                 on target.key = source.key
--                 and target.agentMLSID = source.agentMLSID
--
--         where
--             source.key is null
--             and source.agentMLSID is null
--
--     ) as source
--         on target.key = source.key
--         and target.agentMLSID = source.agentMLSID
--
--     when matched then delete
--
--     `;
--
--     var query_statement = snowflake.createStatement( {sqlText: set_query} );
--     var query_run = query_statement.execute();
--
--
--
--
--     // update or insert into target
--     var set_query = `
--
--     merge into dimensional.Dim_Agent as target
--     using(


create or replace table dimensional.dim_agent as

        with

            MLS_combined as(
                select
                    -- unique ids
                    agt.id
                    ,agt.key as MLS_key
                    ,agt.MLSID as MLS_ID
                    ,hb.contact_id as HB_contact_id
                    ,tc.id as tc_id

                    -- matching
                    ,jarowinkler_similarity(trim(lower(agt.fullname)), trim(lower(concat(hb.first_name, ' ', hb.last_name)))) pct_similar
                    ,editdistance(trim(lower(agt.fullname)), trim(lower(concat(hb.first_name, ' ', hb.last_name)))) name_distance

                    ----------------------------------------
                    -- comparison fields
                    ,agt.fullname as MLS_fullname
                    ,concat(hb.first_name, ' ', hb.last_name) as HB_fullname
                    ,concat(tc.first_name, ' ', tc.last_name) as TC_fullname
                    ----
                    ,agt.email as MLS_email
                    ,hb.email as HB_email
                    ----
                    ,agt.city as MLS_city
                    ,hb.city as HB_city
                    ----
                    ,agt.stateorprovince as MLS_state
                    ,hb.state_province as HB_state
                    ----
                    ,agt.postalcode as MLS_zip
                    ,hb.zip as HB_zip
                    ----
                    ,case
                        when left(regexp_replace(agt.directphone, '[^0-9]'), 1) = '1'
                        then ltrim(regexp_replace(agt.directphone, '[^0-9]'), 1)
                        else regexp_replace(agt.directphone, '[^0-9]')
                        end as MLS_direct_phone
                    ,case
                        when left(regexp_replace(agt.mobilephone, '[^0-9]'), 1) = '1'
                        then ltrim(regexp_replace(agt.mobilephone, '[^0-9]'), 1)
                        else regexp_replace(agt.mobilephone, '[^0-9]')
                        end as MLS_cell_phone
                    ,case
                        when left(regexp_replace(hb.mobile_phone_number, '[^0-9]'), 1) = '1'
                        then ltrim(regexp_replace(hb.mobile_phone_number, '[^0-9]'), 1)
                        else regexp_replace(hb.mobile_phone_number, '[^0-9]')
                        end as hb_phone
                    ----
                    ,case when agt.OfficePhone = '' then null else agt.officePhone end as MLS_agent_Office_Phone
                    ,agt.Address as MLS_agent_Address
                    ----------------------------------------

                    -- MLS
                    ,agt.source as MLS_source
                    ,agt.mainOfficeMLSID as MLS_main_office_MLS_ID
                    ,agt.officeMLSID as MLS_office_MLS_ID
                    ,agt.brokerMLSID as MLS_broker_MLS_ID

                    -- Hubspot
                    ,hb.original_sales_rep as hb_original_sales_rep
                    ,hb.brokerage_growth_manager as hb_brokerage_growth_manager
                    ,hb.contact_owner as hb_contact_owner
                    ,hb.created_date as hb_created_date
                    ,(case when hb.contact_id is not null then 1 else 0 end) as transactly_can_access
                    ,hb.type as hb_type

                    -- Transactly
                    ,tc.join_date as tc_join_date
                    ,tc.is_active as tc_is_active
                    ,tc.is_tc_client as tc_is_tc_client
                    ,tc.assigned_transactly_tc_id as tc_assigned_transactly_tc_id
                    ,tc.last_online_date as tc_last_online_date
                    ,assigned.id as TC_assigned_user_id
                    ,concat(assigned.first_name, ' ', assigned.last_name) as TC_assigned_name

                from
                    (select * from fivetran.production_mlsfarm2_public.ags) agt  -- 2.7M rows, key, mlsid are unique identifiers

                    -- this is to limit the number of agents, takes it down to 282k rows
                    join (
                        select distinct
                            agt.id
                        from
                            working.listings_current list
                            join fivetran.production_mlsfarm2_public.ags agt
                                on list.listagent_id = agt.id
                                and ifnull(upper(agt._fivetran_deleted), 'FALSE') = 'FALSE'
                    ) l
                        on agt.id = l.id

                    left join (select * from dev.working.mls_hubspot_agent) hb  -- 75k rows, contact_id is unique id

                        -- individual combination of name, state, city are similar and zip matches
                        on (
                            jarowinkler_similarity(trim(lower(agt.fullname)), trim(lower(concat(hb.first_name, ' ', hb.last_name)))) >= 90
        --                     and jarowinkler_similarity(trim(lower(agt.stateorprovince)), trim(lower(hb.state_province))) >= 94
        --                     and jarowinkler_similarity(trim(lower(agt.city)), trim(lower(hb.city))) >= 94
                            and trim(lower(regexp_replace(agt.postalcode, '[^0-9]'))) = trim(lower(regexp_replace(hb.zip, '[^0-9]')))
                        )

        --                 -- concatenated name, city, state are similar and the zip matches or is null
        --                 or(
        --                     jarowinkler_similarity(
        --                         concat(
        --                             trim(lower(agt.fullname))
        --                             ,trim(lower(agt.city))
        --                             ,trim(lower(agt.stateorprovince))
        --                         )
        --                         ,concat(
        --                             trim(lower(concat(hb.first_name, ' ', hb.last_name)))
        --                             ,trim(lower(hb.city))
        --                             ,trim(lower(hb.state_province))
        --                         )
        --                     ) >= 95
        --                     and(
        --                         jarowinkler_similarity(
        --                         trim(lower(regexp_replace(agt.postalcode, '[^0-9]'))),
        --                         trim(lower(regexp_replace(hb.zip, '[^0-9]')))
        --                         ) = 100
        --                     )
        --                 )

                        -- emails are similar
                        or jarowinkler_similarity(trim(lower(agt.email)), trim(lower(hb.email))) >= 98

                        -- phone numbers match and the zip codes match or are null
                        or(
                            (
                                case
                                    when left(regexp_replace(agt.directphone, '[^0-9]'), 1) = '1' then ltrim(regexp_replace(agt.directphone, '[^0-9]'), 1)
                                    else regexp_replace(agt.directphone, '[^0-9]')
                                    end =
                                case
                                    when left(regexp_replace(hb.mobile_phone_number, '[^0-9]'), 1) = '1' then ltrim(regexp_replace(hb.mobile_phone_number, '[^0-9]'), 1)
                                    else regexp_replace(hb.mobile_phone_number, '[^0-9]')
                                    end
                                or
                                case
                                    when left(regexp_replace(agt.mobilephone, '[^0-9]'), 1) = '1' then ltrim(regexp_replace(agt.mobilephone, '[^0-9]'), 1)
                                    else regexp_replace(agt.mobilephone, '[^0-9]')
                                    end =
                                case
                                    when left(regexp_replace(hb.mobile_phone_number, '[^0-9]'), 1) = '1' then ltrim(regexp_replace(hb.mobile_phone_number, '[^0-9]'), 1)
                                    else regexp_replace(hb.mobile_phone_number, '[^0-9]')
                                    end
                            )
        --                     and(
        --                         jarowinkler_similarity(
        --                             trim(lower(regexp_replace(agt.postalcode, '[^0-9]')))
        --                             ,trim(lower(regexp_replace(hb.zip, '[^0-9]')))
        --                         ) = 100
        --                     )
                        )

                    left join fivetran.TRANSACTLY_APP_PRODUCTION_REC_ACCOUNTS.user tc on hb.transactly_id = tc.id  -- id is unique identifier
                    left join fivetran.TRANSACTLY_APP_PRODUCTION_REC_ACCOUNTS.user assigned on tc.assigned_transactly_tc_id = assigned.id  -- this is to get who the assigned TC agent is to the user since both users and agents are in the same table

                where
                    ifnull(upper(agt._fivetran_deleted), 'FALSE') = 'FALSE'
            )

            -- hubspot agents who aren't in the MLS
            ,unique_hb_agents as(
                select
                    a.*
                    ,tc.id
                    ,tc.join_date
                    ,tc.is_active
                    ,tc.is_tc_client
                    ,tc.assigned_transactly_tc_id
                    ,tc.last_online_date
                    ,concat(tc.first_name, ' ', tc.last_name) as TC_fullname
                    ,assigned.id as TC_assigned_user_id
                    ,concat(assigned.first_name, ' ', assigned.last_name) as TC_assigned_name
                from
                    dev.working.mls_hubspot_agent a
                    left join FIVETRAN.TRANSACTLY_APP_PRODUCTION_REC_ACCOUNTS.user tc on a.transactly_id = tc.id
                    left join MLS_combined b on a.contact_id = b.HB_contact_id
                    left join fivetran.TRANSACTLY_APP_PRODUCTION_REC_ACCOUNTS.user assigned on tc.assigned_transactly_tc_id = assigned.id
                where
                    b.hb_contact_id is null
            )

            -- Transactly agents who aren't in Hubspot/MLS
            ,unique_tc_agents as(
                select
                    u.*
                    ,concat(u.first_name, ' ', u.last_name) as TC_fullname
                    ,assigned.id as TC_assigned_user_id
                    ,concat(assigned.first_name, ' ', assigned.last_name) as TC_assigned_name
                from
                    FIVETRAN.TRANSACTLY_APP_PRODUCTION_REC_ACCOUNTS.user u  -- desc table dev.working.mls_hubspot_agent
                    left join dev.working.mls_hubspot_agent a on a.transactly_id = u.id
                    left join fivetran.TRANSACTLY_APP_PRODUCTION_REC_ACCOUNTS.user assigned on u.assigned_transactly_tc_id = assigned.id
                where a.transactly_id is null
            )

            ,combine_all as(
                -- MLS combination agents
                select * from MLS_combined

                -- Hubspot agents that aren't in the MLS
                union all select
                    -- unique ids
                    null as id
                    ,null as MLS_key
                    ,null as MLS_ID
                    ,hb.contact_id as HB_contact_id
                    ,hb.id as tc_id

                    -- matching
                    ,null as pct_similar
                    ,null as name_distance

                    ----------------------------------------
                    -- comparison fields
                    ,null as MLS_fullname
                    ,concat(hb.first_name, ' ', hb.last_name) as HB_fullname
                    ,hb.TC_fullname
                    ----
                    ,null as MLS_email
                    ,hb.email as HB_email
                    ----
                    ,null as MLS_city
                    ,hb.city as HB_city
                    ----
                    ,null as MLS_state
                    ,hb.state_province as HB_state
                    ----
                    ,null as MLS_zip
                    ,hb.zip as HB_zip
                    ----
                    ,null as MLS_direct_phone
                    ,null as MLS_cell_phone
                    ,null as hb_phone
                    ----
                    ,null as MLS_agent_Office_Phone
                    ,null as MLS_agent_Address
                    ----------------------------------------

                    -- MLS
                    ,null as MLS_source
                    ,null as MLS_main_office_MLS_ID
                    ,null as MLS_office_MLS_ID
                    ,null as MLS_broker_MLS_ID

                    -- Hubspot
                    ,hb.original_sales_rep as hb_original_sales_rep
                    ,hb.brokerage_growth_manager as hb_brokerage_growth_manager
                    ,hb.contact_owner as hb_contact_owner
                    ,hb.created_date as hb_created_date
                    ,(case when hb.contact_id is not null then 1 else 0 end) as transactly_can_access
                    ,hb.type as hb_type

                    -- Transactly
                    ,hb.join_date as tc_join_date
                    ,hb.is_active as tc_is_active
                    ,hb.is_tc_client as tc_is_tc_client
                    ,hb.assigned_transactly_tc_id as tc_assigned_transactly_tc_id
                    ,hb.last_online_date as tc_last_online_date
                    ,hb.TC_assigned_user_id
                    ,hb.TC_assigned_name
                from unique_hb_agents hb

                -- Transactly agents who aren't in Hubspot/MLS
                union all select
                    -- unique ids
                    null as id
                    ,null as MLS_key
                    ,null as MLS_ID
                    ,null as HB_contact_id
                    ,tc.id as tc_id

                    -- matching
                    ,null as pct_similar
                    ,null as name_distance

                    ----------------------------------------
                    -- comparison fields
                    ,null as MLS_fullname
                    ,null as HB_fullname
                    ,tc.TC_fullname
                    ----
                    ,null as MLS_email
                    ,null as HB_email
                    ----
                    ,null as MLS_city
                    ,null as HB_city
                    ----
                    ,null as MLS_state
                    ,null as HB_state
                    ----
                    ,null as MLS_zip
                    ,null as HB_zip
                    ----
                    ,null as MLS_direct_phone
                    ,null as MLS_cell_phone
                    ,null as hb_phone
                    ----
                    ,null as MLS_agent_Office_Phone
                    ,null as MLS_agent_Address
                    ----------------------------------------

                    -- MLS
                    ,null as MLS_source
                    ,null as MLS_main_office_MLS_ID
                    ,null as MLS_office_MLS_ID
                    ,null as MLS_broker_MLS_ID

                    -- Hubspot
                    ,null as hb_original_sales_rep
                    ,null as hb_brokerage_growth_manager
                    ,null as hb_contact_owner
                    ,null as hb_created_date
                    ,null as transactly_can_access
                    ,null as hb_type

                    -- Transactly
                    ,tc.join_date as tc_join_date
                    ,tc.is_active as tc_is_active
                    ,tc.is_tc_client as tc_is_tc_client
                    ,tc.assigned_transactly_tc_id as tc_assigned_transactly_tc_id
                    ,tc.last_online_date as tc_last_online_date
                    ,tc.TC_assigned_user_id
                    ,tc.TC_assigned_name
                from unique_tc_agents tc
            )

        select
            working.seq_dim_agent.nextval as agent_pk
            ,ca.*
            ,case
                when tc_id is not null then 'client'
                when hb_contact_id is not null and tc_id is null then 'prospect'
                when mls_ID is not null and hb_contact_id is null and tc_id is null then 'mls only'
                else '?'
                end as client_indicator
        from
            combine_all ca

     union select '0', '0', '0', '0', '0', '0', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null




--     ) source
--         on target.MLS_key = source.MLS_key
--         and target.MLS_ID = source.MLS_ID
--
--     when matched
--         and(
--             ifnull(target.fullname, '1') <> ifnull(source.fullname, '1')
--             or ifnull(target.agentEmail, '1') <> ifnull(source.agentEmail, '1')
--             or ifnull(target.agentCellPhone, '1') <> ifnull(source.agentCellPhone, '1')
--             or ifnull(target.agentofficephone, '1') <> ifnull(source.agentofficephone, '1')
--             or ifnull(target.agentDirectPhone, '1') <> ifnull(source.agentDirectPhone, '1')
--             or ifnull(target.agentaddress, '1') <> ifnull(source.agentAddress, '1')
--             or ifnull(target.agentcity, '1') <> ifnull(source.agentcity, '1')
--             or ifnull(target.agentstate, '1') <> ifnull(source.agentstate, '1')
--             or ifnull(target.agentzipcode, '1') <> ifnull(source.agentzipcode, '1')
--             or ifnull(target.StateLicense, '1') <> ifnull(source.StateLicense, '1')
--             or ifnull(target.source, '1') <> ifnull(source.source, '1')
--             or ifnull(target.AOR, '1') <> ifnull(source.AOR, '1')
--             or ifnull(target.mainOfficeMLSID, '1') <> ifnull(source.mainOfficeMLSID, '1')
--             or ifnull(target.officeMLSID, '1') <> ifnull(source.officeMLSID, '1')
--             or ifnull(target.brokerMLSID, '1') <> ifnull(source.brokerMLSID, '1')
--         )
--         then update set
--             target.fullname = source.fullname
--             ,target.agentemail = source.agentEmail
--             ,target.agentcellphone = source.agentcellphone
--             ,target.agentofficephone = source.agentofficephone
--             ,target.agentDirectPhone = source.agentDirectPhone
--             ,target.agentaddress = source.agentAddress
--             ,target.agentcity = source.agentCity
--             ,target.agentstate = source.agentState
--             ,target.agentzipcode = source.agentZipCode
--             ,target.StateLicense = source.StateLicense
--             ,target.source = source.source
--             ,target.AOR = source.AOR
--             ,target.mainOfficeMLSID = source.mainOfficeMLSID
--             ,target.officeMLSID = source.officeMLSID
--             ,target.brokerMLSID = source.brokerMLSID
--             ,target.update_datetime = current_timestamp()
--
--     when not matched then
--         insert(agent_pk, key, agentmlsid, fullname, agentemail, agentcellphone, agentofficephone, agentDirectPhone, agentaddress, agentcity, agentstate, agentzipcode, statelicense, source, aor, mainOfficeMLSID, officeMLSID, brokerMLSID, update_datetime)
--         values(working.seq_dim_agent.nextval, source.key, source.agentmlsid, source.fullname, source.agentemail, source.agentcellphone, source.agentofficephone, source.agentDirectPhone, source.agentaddress, source.agentcity, source.agentstate, source.agentzipcode, source.statelicense, source.source, source.aor, source.mainOfficeMLSID, source.officeMLSID, source.brokerMLSID, current_timestamp)
--
--     `;
--
--     var query_statement = snowflake.createStatement( {sqlText: set_query} );
--     var query_run = query_statement.execute();
--
--     result = "Complete!";
--     return result;
--
--     $$;



/*

truncate table dim_agent;
call working.dim_agent_sp();
create or replace table load.dim_agent as select * from dimensional.dim_agent;
select top 100 * from load.dim_agent;

*/
