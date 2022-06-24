with
    src_mls_ags as(
        select *
        from {{ ref('src_mls_ags') }}
    )

    ,dim_agent_HS as(
        select *
        from {{ ref('dim_agent_HS') }}
    )

    ,src_tc_agent_subscription_tier as(
        select *
        from {{ ref('src_tc_agent_subscription_tier') }}
    )

    ,src_tc_user_agent_subscription_tier as(
        select *
        from {{ ref('src_tc_user_agent_subscription_tier') }}
    )

    ,src_tc_user as(
        select *
        from {{ ref('src_tc_user') }}
    )

    ,src_tc_user_role as(
        select *
        from {{ ref('src_tc_user_role') }}
    )

    ,MLS_combined as(
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
            ,tc.email as tc_email
            ,tc.first_login as tc_first_login
            ,tc.autopay_date as tc_autopay_date
            ,ast.name as tc_membership_type
            ,uast.price as membership_price
            ,uast.end_date as membership_end_date

        from
            src_mls_ags as agt  -- 2.7M rows, key, mlsid are unique identifiers

            -- this is to limit the number of agents, takes it down to 282k rows
            join (
                select distinct
                    top 1000  -- comment out this line when done testing
                    agt.id
                from
                    working.listings_current list
                    join src_mls_ags as agt
                        on list.listagent_id = agt.id
                        and ifnull(upper(agt._fivetran_deleted), 'FALSE') = 'FALSE'
            ) l
                on agt.id = l.id

            left join dim_agent_HS hb  -- 75k rows, contact_id is unique id

                -- individual combination of name, state, city are similar and zip matches
                on (
                    jarowinkler_similarity(trim(lower(agt.fullname)), trim(lower(concat(hb.first_name, ' ', hb.last_name)))) >= 90
                    and trim(lower(regexp_replace(agt.postalcode, '[^0-9]'))) = trim(lower(regexp_replace(hb.zip, '[^0-9]')))
                )

                -- emails are similar
                or jarowinkler_similarity(trim(lower(agt.email)), trim(lower(hb.email))) >= 98

                -- phone numbers match
                or(
                    (
                        case
                            when left(regexp_replace(agt.directphone, '[^0-9]'), 1) = '1' then ltrim(regexp_replace(agt.directphone, '[^0-9]'), 1)
                            else regexp_replace(agt.directphone, '[^0-9]')
                            end =
                        case
                            when left(regexp_replace(hb.mobile_phone_number, '[^0-9]'), 1) = '1' then ltrim(regexp_replace(hb.mobile_phone_number, '[^0-9]'), 1)
                            when regexp_replace(hb.mobile_phone_number, '[^0-9]') like '0000%' then null
                            else regexp_replace(hb.mobile_phone_number, '[^0-9]')
                            end
                        or
                        case
                            when left(regexp_replace(agt.mobilephone, '[^0-9]'), 1) = '1' then ltrim(regexp_replace(agt.mobilephone, '[^0-9]'), 1)
                            else regexp_replace(agt.mobilephone, '[^0-9]')
                            end =
                        case
                            when left(regexp_replace(hb.mobile_phone_number, '[^0-9]'), 1) = '1' then ltrim(regexp_replace(hb.mobile_phone_number, '[^0-9]'), 1)
                            when regexp_replace(hb.mobile_phone_number, '[^0-9]') like '0000%' then null
                            else regexp_replace(hb.mobile_phone_number, '[^0-9]')
                            end
                    )
                  )

            left join src_tc_user tc -- id is unique identifier
                join (select distinct user_id from src_tc_user_role where role_id in(4, 5)) ur
                    on tc.id = ur.user_id
                on hb.transactly_id = tc.id
            -- user_agent_subscription_tier has dups, this is to find the most recent record
            left join(
                select a.*
                from
                    src_user_agent_subscastription_tier a
                    join (select user_id, max(start_date) start_date from src_tc_user_agent_subscription_tier group by user_id) b
                        on a.user_id = b.user_id
                        and a.start_date = b.start_date
            ) uast on tc.id = uast.user_id
            left join src_tc_agent_subscription_tier on ast.id = uast.agent_subscription_tier_id

            -- this is to get who the assigned TC agent is to the user since both users and agents are in the same table
            left join src_tc_user assigned on tc.assigned_transactly_tc_id = assigned.id

        where
            ifnull(upper(agt._fivetran_deleted), 'FALSE') = 'FALSE'
    )

    -- hubspot agents who aren't in the MLS
    ,unique_hb_agents as(
    -- there are about 4 tc_id's that have dups
    -- looks like the reason is due to there being duplicate working.mls_hubspot_agent.transactly_id - two different agents with the same transactly id
    -- in other words it's a source error in Hubspot
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
            ,tc.email as tc_email
            ,tc.first_login as tc_first_login
            ,tc.autopay_date as tc_autopay_date
            ,ast.name as tc_membership_type
            ,uast.price as membership_price
            ,uast.end_date as membership_end_date
        from
            dim_agent_HS a
            left join src_tc_user tc
                join (select distinct user_id from src_tc_user_role where role_id in(4, 5)) ur
                    on tc.id = ur.user_id
                on a.transactly_id = tc.id
            -- user_agent_subscription_tier has dups, this is to find the most recent record
            left join(
                select a.*
                from
                    src_tc_user_agent_subscription_tier a
                    join (select user_id, max(start_date) start_date from src_tc_user_agent_subscription_tier group by user_id) b
                        on a.user_id = b.user_id
                        and a.start_date = b.start_date
            ) uast on tc.id = uast.user_id
            left join src_tc_agent_subscription_tier ast on ast.id = uast.agent_subscription_tier_id
            left join MLS_combined b on a.contact_id = b.HB_contact_id

            -- this is to get who the assigned TC agent is to the user since both users and agents are in the same table
            left join src_tc_user assigned on tc.assigned_transactly_tc_id = assigned.id
        where
            b.hb_contact_id is null
    )

    -- Transactly agents who aren't in Hubspot/MLS
    ,unique_tc_agents as(
        select
            tc.*
            ,concat(tc.first_name, ' ', tc.last_name) as TC_fullname
            ,assigned.id as TC_assigned_user_id
            ,concat(assigned.first_name, ' ', assigned.last_name) as TC_assigned_name
            ,assigned.email as tc_email
            ,tc.first_login as tc_first_login
            ,tc.autopay_date as tc_autopay_date
            ,ast.name as tc_membership_type
            ,uast.price as membership_price
            ,uast.end_date as membership_end_date
        from
            src_tc_user tc  -- desc table dev.working.mls_hubspot_agent
            join (select distinct user_id from src_tc_user_role where role_id in(4, 5)) ur on tc.id = ur.user_id
            -- user_agent_subscription_tier has dups, this is to find the most recent record
            left join(
                select a.*
                from
                    src_tc_user_agent_subscription_tier a
                    join (select user_id, max(start_date) start_date from src_tc_user_agent_subscription_tier group by user_id) b
                        on a.user_id = b.user_id
                        and a.start_date = b.start_date
            ) uast on tc.id = uast.user_id
            left join src_tc_agent_subscription_tier ast on ast.id = uast.agent_subscription_tier_id
            left join dim_agent_HS a on a.transactly_id = tc.id
            left join src_tc_user assigned on tc.assigned_transactly_tc_id = assigned.id
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
            ,hb.tc_email
            ,hb.tc_first_login
            ,hb.tc_autopay_date
            ,hb.tc_membership_type
            ,hb.membership_price
            ,hb.membership_end_date
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
            ,tc.tc_email
            ,tc.tc_first_login
            ,tc.tc_autopay_date
            ,tc.tc_membership_type
            ,tc.membership_price
            ,tc.membership_end_date
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

union select '0', '0', '0', '0', '0', '0', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null
