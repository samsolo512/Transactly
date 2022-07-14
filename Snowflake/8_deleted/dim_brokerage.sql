-- dim_brokerage.sql

-- /*
-- use prod.dimensional;
-- use stage.dimensional;
-- use dev.dimensional;
-- */
--
--
-- --Dim_Brokerage_sp
--
-- select * from dimensional.dim_brokerage;
--
--
-- -- dim_brokerage
-- -- 59k rows, 50 sec
-- -- using MLS IDs ~200 dups not counting nulls, 2.3k null dups
-- create or replace procedure working.Dim_Brokerage_sp()
--     returns string not null
--     language javascript
--     execute as caller
-- as
-- $$
--
-- table_name = 'Dim_Brokerage';
--
-- //delete from target if record isn't in source
-- var set_query = `
--
-- merge into dimensional.Dim_Brokerage as target
-- using(
--
--     select
--         target.key
--         ,target.officeMLSID
--     from
--         dimensional.dim_Brokerage target
--         left join(
--             select
--                 mls.key
--                 ,mls.mlsID as officeMLSID
--                 ,mls.Name as officeName
--                 ,mls.OriginatingSystemName
--                 ,mls.Address as officeAddress
--                 ,mls.City as officeCity
--                 ,mls.stateOrProvince
--                 ,mls.postalCode
--                 ,mls.phone
--                 ,mls.source
--                 ,mls.mlsID
--             from
--                 fivetran.production_mlsfarm2_public.ofs mls
--                 join minCreated mc
--                     on mls.key = mc.key
--                     and mls.MLSID = mc.MLSID
--                     and mls.updated_at = mc.updated_at
--                     and mls.created_at = mc.created_at
--                 -- this is to limit the number of brokerages we bring in
--                 join fivetran.production_mlsfarm2_public.ags ags
--                     on ags.officemlsid = mls.mlsid
--                     and ags._fivetran_deleted = 'FALSE'
--                 join fivetran.production_mlsfarm2_public.listings l
--                     on l.listagent_id = ags.id
--                     and l._fivetran_deleted = 'FALSE'
--             where
--                 mls._fivetran_deleted = 'FALSE'
--                 and l.calculated_date_on >= '1/1/2022'
--
--             union select '0', '0', null, null, null, null, null, null, null, null, null
--
--     ) source
--         on target.key = source.key
--         and target.officeMLSID = source.officeMLSID
--
--     where
--         source.key is null
--         and source.officeMLSID is null
--
-- ) as source
--     on target.key = source.key
--     and target.officeMLSID = source.officeMLSID
--
-- when matched then delete
--
-- `;
--
-- var query_statement = snowflake.createStatement( {sqlText: set_query} );
-- var query_run = query_statement.execute();
--
--
--
-- // update or insert into target
-- var set_query = `
--
-- -- 15m refresh
-- merge into dim_brokerage as target
-- using(




create or replace table dimensional.dim_brokerage as

with

    MLS_combined as(
        select
            -- unique ids
            mls.id
            ,mls.key as MLS_key
            ,mls.mlsid as MLS_ID
            ,hb.company_id as hb_company_id  -- select top 10 * from dimensional.dim_brokerage;
            ,tc.id as tc_id

            -- matching
            ,jarowinkler_similarity(
                concat(
                    trim(lower(mls.name))
                    ,trim(lower(mls.city))
                    ,trim(lower(mls.stateorprovince))
                )
                ,concat(
                    trim(lower(hb.company_name))
                    ,trim(lower(hb.city))
                    ,trim(lower(hb.state))
                )
            ) pct_similar
            ,editdistance(trim(lower(mls.name)), trim(lower(hb.company_name))) name_distance

            ----------------------------------------
            -- comparison fields
            ,mls.name as MLS_name
            ,hb.company_name as hb_name
            ,tc.name as TC_company_name
            ----
            ,mls.source as MLS_source
            ,hb.mls_id as hb_MLS_id
            ----
            ,mls.url as MLS_url
            ,hb.website_url as hb_url
            ----
            ,case
                when left(regexp_replace(mls.phone, '[^0-9]'), 1) = '1'
                then ltrim(regexp_replace(mls.phone, '[^0-9]'), 1)
                else regexp_replace(mls.phone, '[^0-9]')
                end as MLS_phone
            ,case
                when left(regexp_replace(hb.phone_number, '[^0-9]'), 1) = '1'
                then ltrim(regexp_replace(hb.phone_number, '[^0-9]'), 1)
                else regexp_replace(hb.phone_number, '[^0-9]')
                end as hb_phone
            ----
            ,mls.Address as MLS_street
            ,concat(hb.street_address_1, ' ', hb.street_address_2) as hb_street
            ----
            ,mls.city as MLS_city
            ,hb.city as hb_city
            ----
            ,mls.stateOrProvince as MLS_state
            ,hb.state as hb_state
            ----
            ,mls.postalCode as MLS_zip
            ,hb.postal_code as hb_zip
            ----------------------------------------

            -- MLS
            ,mls.brokerMLSID
            ,mls.mainOfficeMLSID
            ,mls.ManagerMLSID
            ,mls.status
            ,mls.ca
            ,mls.ua
            ,mls.i1
            ,mls.modificationTimestamp

            -- Hubspot
            ,concat(srn.firstname, ' ', srn.lastname) as originalSalesRepName
            ,concat(bgm.firstname, ' ', bgm.lastname) as brokerageGrowthManagerName
            ,concat(cs.firstname, ' ', cs.lastname) as assignedCSRepName
            ,hb.recentDealAmount
            ,hb.recentCloseDate
            ,hb.contractEffectiveDate
            ,hb.officeSubscriptionPlan
--             ,hb.officeSubscriptionRenewalDate
            ,hb.brokerageOnboardingDate
            ,hb.principalBrokerEmail
--             ,hb.billingContactName
            ,hb.lastEngagementDate
--             ,hb.canWeSendEmailsToAgents
            ,hb.companyDomainName
            ,hb.mls_system_name as hb_MLS_System_name

            -- Transactly
            ,tc.name as tc_officeName
            ,tc.parent_office_id as tc_parentOfficeID
--             ,tc.parentOfficeName
--             ,tc.officeActiveIndicator
--             ,tc.first_user_created

from
            (select * from fivetran.production_mlsfarm2_public.ofs ofs) mls  -- select id, count(1) from fivetran.production_mlsfarm2_public.ofs group by id order by count(1) desc

            -- this is to limit the number of brokerages, takes it down to 57k rows
            join (
                select distinct ofs.id
                from
                    dev.working.listings_current list
                    join fivetran.production_mlsfarm2_public.ofs ofs
                        on list.listoffice_id = ofs.id
                        and ifnull(upper(ofs._fivetran_deleted), 'FALSE') = 'FALSE'

            ) l
                on mls.id = l.id

            left join dev.working.mls_hubspot_brokerage hb  --2.4k rows, company_id is unique id

                -- when the mls id's match exactly
                on trim(lower(mls.mlsid)) = trim(lower(hb.mls_id))

                -- individual combination of name, state, office, city, and zip codes match
                or(
                    jarowinkler_similarity(trim(lower(mls.stateorprovince)), trim(lower(hb.state))) >= 93
                    and jarowinkler_similarity(trim(lower(mls.Name)), trim(lower(hb.company_name))) >= 93
                    and jarowinkler_similarity(trim(lower(mls.City)), trim(lower(hb.city))) >= 94
                    and jarowinkler_similarity(
                        trim(lower(regexp_replace(mls.postalcode, '[^0-9]'))),
                        trim(lower(regexp_replace(hb.postal_code, '[^0-9]')))
                    ) = 100
                )

                -- concatenated name, city, state are similar and zip codes match
                or(
                    jarowinkler_similarity(
                        concat(
                            trim(lower(mls.Name))
                            ,trim(lower(mls.City))
                            ,trim(lower(mls.stateorprovince))
                        )
                        ,concat(
                            trim(lower(hb.company_name))
                            ,trim(lower(hb.city))
                            ,trim(lower(hb.state))
                        )
                    ) >= 93
                    and jarowinkler_similarity(
                            trim(lower(regexp_replace(mls.postalcode, '[^0-9]'))),
                            trim(lower(regexp_replace(hb.postal_code, '[^0-9]')))
                    ) = 100
                )

                -- the websites are similar
                or jarowinkler_similarity(trim(lower(mls.url)), trim(lower(hb.website_url))) >= 98

                -- the phone numbers match and the zip codes match
                or (
                    case
                        when left(regexp_replace(mls.phone, '[^0-9]'), 1) = '1'
                            then ltrim(regexp_replace(mls.phone, '[^0-9]'), 1)
                        else regexp_replace(mls.phone, '[^0-9]')
                        end =
                    case
                        when left(regexp_replace(hb.phone_number, '[^0-9]'), 1) = '1'
                            then ltrim(regexp_replace(hb.phone_number, '[^0-9]'), 1)
                        else regexp_replace(hb.phone_number, '[^0-9]')
                        end
                    and jarowinkler_similarity(
                            trim(lower(regexp_replace(mls.postalcode, '[^0-9]'))),
                            trim(lower(regexp_replace(hb.postal_code, '[^0-9]')))
                    ) = 100
                )

            left join HUBSPOT_EXTRACT.V2_DAILY.owners bgm on hb.brokeragegrowthmanager = bgm.ownerid
            left join HUBSPOT_EXTRACT.V2_DAILY.owners cs on (case when hb.assigned_cs_rep = '' then null else hb.assigned_cs_rep end) = cs.ownerid
            left join HUBSPOT_EXTRACT.V2_DAILY.owners srn on (case when hb.originalsalesrep = '' then null else hb.originalsalesrep end) = srn.ownerid

            left join FIVETRAN.TRANSACTLY_APP_PRODUCTION_REC_ACCOUNTS.OFFICE tc  -- 263 rows, id is unique id
                on jarowinkler_similarity(trim(lower(tc.name)), trim(lower(hb.company_name))) >= 93
    )

    -- hubspot agents who aren't in the MLS
    ,unique_hb_brokerage as(
        select
            a.*
            ,tc.id
            ,tc.name
            ,tc.parent_office_id
            ,concat(bgm.firstname, ' ', bgm.lastname) as brokerageGrowthManagerName
            ,concat(srn.firstname, ' ', srn.lastname) as originalSalesRepName
            ,concat(cs.firstname, ' ', cs.lastname) as assignedCSRepName
        from
            dev.working.mls_hubspot_brokerage a
            left join FIVETRAN.TRANSACTLY_APP_PRODUCTION_REC_ACCOUNTS.office tc
                on jarowinkler_similarity(trim(lower(tc.name)), trim(lower(a.company_name))) >= 93
            left join MLS_combined b on a.company_id = b.HB_company_id
            left join HUBSPOT_EXTRACT.V2_DAILY.owners bgm on a.brokeragegrowthmanager = bgm.ownerid
            left join HUBSPOT_EXTRACT.V2_DAILY.owners cs on (case when a.assigned_cs_rep = '' then null else a.assigned_cs_rep end) = cs.ownerid
            left join HUBSPOT_EXTRACT.V2_DAILY.owners srn on (case when a.originalsalesrep = '' then null else a.originalsalesrep end) = srn.ownerid
        where
            b.HB_company_id is null
    )-- desc table dev.working.mls_hubspot_brokerage

    -- Transactly brokerage who aren't in Hubspot/MLS
    ,unique_tc_brokerage as(
        select t.*
        from
            FIVETRAN.TRANSACTLY_APP_PRODUCTION_REC_ACCOUNTS.office t
            left join dev.working.mls_hubspot_brokerage h
                on jarowinkler_similarity(trim(lower(t.name)), trim(lower(h.company_name))) >= 93
        where h.company_name is null
    )

    ,combine_all as(
        -- MLS combination agents
        select * from MLS_combined

        -- Hubspot agents that aren't in the MLS
        union all select
            -- unique ids
            null as ID
            ,null as MLS_key
            ,null as MLS_ID
            ,hb.company_id as hb_company_id
            ,hb.id as tc_id

            -- matching
            ,null as pct_similar
            ,null as name_distance

            ----------------------------------------
            -- comparison fields
            ,null as MLS_name
            ,hb.company_name as hb_name
            ,hb.name as TC_company_name
            ----
            ,null as MLS_source
            ,hb.mls_id as hb_MLS_id
            ----
            ,null as MLS_url
            ,hb.website_url as hb_url
            ----
            ,null as MLS_phone
            ,case
                when left(regexp_replace(hb.phone_number, '[^0-9]'), 1) = '1'
                then ltrim(regexp_replace(hb.phone_number, '[^0-9]'), 1)
                else regexp_replace(hb.phone_number, '[^0-9]')
                end as hb_phone
            ----
            ,null as MLS_street
            ,concat(hb.street_address_1, ' ', hb.street_address_2) as hb_street
            ----
            ,null as MLS_city
            ,hb.city as hb_city
            ----
            ,null as MLS_state
            ,hb.state as hb_state
            ----
            ,null as MLS_zip
            ,hb.postal_code as hb_zip
            ----------------------------------------

            -- MLS
            ,null as brokerMLSID
            ,null as mainOfficeMLSID
            ,null as ManagerMLSID
            ,null as status
            ,null as ca
            ,null as ua
            ,null as i1
            ,null as modificationTimestamp

            -- Hubspot
            ,hb.originalSalesRepName
            ,hb.brokerageGrowthManagerName
            ,hb.assignedCSRepName
            ,hb.recentDealAmount
            ,hb.recentCloseDate
            ,hb.contractEffectiveDate
            ,hb.officeSubscriptionPlan
--             ,hb.officeSubscriptionRenewalDate
            ,hb.brokerageOnboardingDate
            ,hb.principalBrokerEmail
--             ,hb.billingContactName
            ,hb.lastEngagementDate
--             ,hb.canWeSendEmailsToAgents
            ,hb.companyDomainName
            ,hb.mls_system_name as hb_MLS_System_name

            -- Transactly
            ,hb.name as tc_officeName
            ,hb.parent_office_id as tc_parentOfficeID

        from unique_hb_brokerage hb

        -- Transactly agents who aren't in Hubspot/MLS
        union all select
            -- unique ids
            null as ID
            ,null as MLS_key
            ,null as MLS_ID
            ,null as hb_company_id
            ,tc.id as tc_id

            -- matching
            ,null as pct_similar
            ,null as name_distance

            ----------------------------------------
            -- comparison fields
            ,null as MLS_name
            ,null as hb_name
            ,tc.name as TC_company_name
            ----
            ,null as MLS_source
            ,null as hb_MLS_id
            ----
            ,null as MLS_url
            ,null as hb_url
            ----
            ,null as MLS_phone
            ,null as hb_phone
            ----
            ,null as MLS_street
            ,null as hb_street
            ----
            ,null as MLS_city
            ,null as hb_city
            ----
            ,null as MLS_state
            ,null as hb_state
            ----
            ,null as MLS_zip
            ,null as hb_zip
            ----------------------------------------

            -- MLS
            ,null as brokerMLSID
            ,null as mainOfficeMLSID
            ,null as ManagerMLSID
            ,null as status
            ,null as ca
            ,null as ua
            ,null as i1
            ,null as modificationTimestamp

            -- Hubspot
            ,null as originalSalesRep
            ,null as brokerageGrowthManager
            ,null as assigned_cs_rep
            ,null as recentDealAmount
            ,null as recentCloseDate
            ,null as contractEffectiveDate
            ,null as officeSubscriptionPlan
--             ,null as officeSubscriptionRenewalDate
            ,null as brokerageOnboardingDate
            ,null as principalBrokerEmail
--             ,null as billingContactName
            ,null as lastEngagementDate
--             ,null as canWeSendEmailsToAgents
            ,null as companyDomainName
            ,null as hb_MLS_System_name

            -- Transactly
            ,tc.name as tc_officeName
            ,tc.parent_office_id as tc_parentOfficeID

        from unique_tc_brokerage tc
    )

    select
        working.seq_dim_brokerage.nextval as brokerage_pk
        ,ca.*
        ,case
            when tc_id is not null then 'client'
            when hb_company_id is not null and tc_id is null then 'prospect'
            when mls_id is not null and hb_company_id is null and tc_id is null then 'MLS only'
            else '?'
            end as client_indicator
    from
        combine_all ca


    union select '0', '0', '0', '0', '0', '0', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null
;

-- select * from dim_brokerage where id = '0';



-- ) source
--     on target.MLS_key = source.MLS_key
--     and target.mainOfficeMLSID = source.mainOfficeMLSID
--
-- when matched
--     and(
--         ifnull(target.officeName, '1') <> ifnull(source.officeName, '1')
--         or ifnull(target.originatingsystemname, '1') <> ifnull(source.originatingsystemname, '1')
--         or ifnull(target.officeaddress, '1') <> ifnull(source.officeAddress, '1')
--         or ifnull(target.officecity, '1') <> ifnull(source.officeCity, '1')
--         or ifnull(target.stateorprovince, '1') <> ifnull(source.stateorprovince, '1')
--         or ifnull(target.postalcode, '1') <> ifnull(source.postalcode, '1')
--         or ifnull(target.phone, '1') <> ifnull(source.phone, '1')
--         or ifnull(target.source, '1') <> ifnull(source.source, '1')
--         or ifnull(target.url, '1') <> ifnull(source.url, '1')
--         or ifnull(target.mlsID, '1') <> ifnull(source.mlsID, '1')
--     )
--     then update set
--         target.officename = source.officename
--         ,target.originatingsystemname = source.originatingsystemname
--         ,target.officeaddress = source.officeaddress
--         ,target.officecity = source.officecity
--         ,target.stateorprovince = source.stateorprovince
--         ,target.postalcode = source.postalcode
--         ,target.phone = source.phone
--         ,target.source = source.source
--         ,target.url = source.url
--         ,target.mlsID = source.mlsID
--         ,target.update_datetime = current_timestamp()
--
-- when not matched then
--     insert(brokerage_pk, key, officeMLSID, officeName, originatingsystemname, officeaddress, officecity, stateorprovince, postalcode, phone, source, url, mlsid, update_datetime)
--     values(working.seq_dim_brokerage.nextval, source.key, source.officeMLSID, source.officeName, source.originatingsystemname, source.officeaddress, source.officecity, source.stateorprovince, source.postalcode, source.phone, source.source, source.url, source.mlsID, current_timestamp)
--
-- `;
--
-- var query_statement = snowflake.createStatement( {sqlText: set_query} );
-- var query_run = query_statement.execute();
--
-- result = "Complete!";
-- return result;
--
-- $$;


-- dim_agent
-- 360k rows, 120 min
-- using MLS IDs ~70 dups not counting nulls, 74k null dups
-- using hb_contact_id ~350 dups not counting nulls
-- using tc_id ~200 dups not counting nulls
select top 10 * from dimensional.dim_agent;
select client_indicator, count(1) from dimensional.dim_agent group by client_indicator;
select  HB_CONTACT_ID, count(1) from dimensional.dim_agent group by HB_CONTACT_ID order by count(1) desc;
select  tc_id, count(1) from dimensional.dim_agent group by tc_id order by count(1) desc;



-- dim_brokerage
select distinct brokerageGrowthManagername from dimensional.dim_brokerage;
select distinct originalsalesrepName from dimensional.dim_brokerage;
select distinct assignedCSrepName from dimensional.dim_brokerage;

select assigned_cs_rep, count(1) from dev.working.mls_hubspot_brokerage where MLS_HUBSPOT_BROKERAGE.assigned_cs_rep is not null group by assigned_cs_rep order by count(1) desc;
select id, count(1) from dimensional.dim_brokerage group by id order by count(1)desc;
select * from dimensional.dim_brokerage where id = '1cb6f83e-301e-421e-bcb4-ad61334ee262';

select * from HUBSPOT_EXTRACT.V2_DAILY.owners where ownerid = 50077558;


-- join dim_agent and dim_brokerage
select *
from
    dimensional.dim_agent a
    join dimensional.dim_brokerage b on a.mls_office_mls_id = b.mls_id
;




/*

-- truncate table dim_brokerage;
call working.dim_brokerage_sp();
create or replace table load.dim_brokerage as select * from dimensional.dim_brokerage;
select * from load.dim_brokerage;

*/



/*
-- this is to limit the number of brokerages we bring in
join fivetran.production_mlsfarm2_public.ags ags
    on ags.officemlsid = mls.mlsid
    and ags._fivetran_deleted = 'FALSE'
join fivetran.production_mlsfarm2_public.listings_current l
    on l.listagent_id = ags.id
    and l._fivetran_deleted = 'FALSE'
*/


