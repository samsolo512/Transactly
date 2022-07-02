with
    src_mls_ofs as(
        select *
        from {{ ref('src_mls_ofs') }}
    )

    ,HS_brokerage as(
        select *
        from {{ ref('HS_brokerage') }}
    )

    ,HS_owners as(
        select *
        from {{ ref('src_hs_owners') }}
    )

--     ,src_tc_agent_subscription_tier as(
--         select *
--         from {{ ref('src_tc_agent_subscription_tier') }}
--     )
--
--     ,src_tc_user_agent_subscription_tier as(
--         select *
--         from {{ ref('src_tc_user_agent_subscription_tier') }}
--     )

    ,src_mls_listings as (
        select *
        from {{ ref('src_mls_listings') }}
    )

    ,src_tc_office as(
        select *
        from {{ ref('src_tc_office') }}
    )

--     ,src_tc_user as(
--         select *
--         from {{ ref('src_tc_user') }}
--     )
--
--     ,src_tc_user_role as(
--         select *
--         from {{ ref('src_tc_user_role') }}
--     )

    ,MLS_combined as(
        select
            -- unique ids
            mls.id
            ,mls.mls_key as MLS_key
            ,mls.MLS_ID
            ,hb.company_id as hb_company_id  -- select top 10 * from dimensional.dim_brokerage;
            ,tc.office_id

            -- matching
            ,jarowinkler_similarity(
                concat(
                    trim(lower(mls.mls_name))
                    ,trim(lower(mls.mls_city))
                    ,trim(lower(mls.mls_state))
                )
                ,concat(
                    trim(lower(hb.company_name))
                    ,trim(lower(hb.city))
                    ,trim(lower(hb.state))
                )
            ) pct_similar
            ,editdistance(trim(lower(mls.mls_name)), trim(lower(hb.company_name))) name_distance

            ----------------------------------------
            -- comparison fields
            ,mls.MLS_name
            ,hb.company_name as hb_name
            ,tc.office_name as TC_company_name
            ----
            ,mls.mls_source as MLS_source
            ,hb.mls_id as hb_MLS_id
            ----
            ,mls.mls_url as MLS_url
            ,hb.website_url as hb_url
            ----
            ,case
                when left(regexp_replace(mls.mls_phone, '[^0-9]'), 1) = '1'
                then ltrim(regexp_replace(mls.mls_phone, '[^0-9]'), 1)
                else regexp_replace(mls.mls_phone, '[^0-9]')
                end as MLS_phone
            ,case
                when left(regexp_replace(hb.phone_number, '[^0-9]'), 1) = '1'
                then ltrim(regexp_replace(hb.phone_number, '[^0-9]'), 1)
                else regexp_replace(hb.phone_number, '[^0-9]')
                end as hb_phone
            ----
            ,mls.MLS_street
            ,concat(hb.street_address_1, ' ', hb.street_address_2) as hb_street
            ----
            ,mls.mls_city as MLS_city
            ,hb.city as hb_city
            ----
            ,mls.MLS_state
            ,hb.state as hb_state
            ----
            ,mls.mls_zip as MLS_zip
            ,hb.postal_code as hb_zip
            ----------------------------------------

            -- MLS
            ,mls.MLS_broker_MLS_ID
            ,mls.MLS_office_MLS_ID
            ,mls.MLS_manager_MLS_ID
            ,mls.MLS_status
            ,mls.MLS_ca
            ,mls.MLS_ua
            ,mls.MLS_i1
            ,mls.MLS_modification_time_stamp

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
            ,tc.office_name as tc_officeName
            ,tc.parent_office_id as tc_parentOfficeID
--             ,tc.parentOfficeName
--             ,tc.officeActiveIndicator
--             ,tc.first_user_created

        from
            (select * from src_mls_ofs ofs) mls  -- select id, count(1) from fivetran.production_mlsfarm2_public.ofs group by id order by count(1) desc

            -- this is to limit the number of brokerages, takes it down to 57k rows
            join (
                select distinct ofs.id
                from
                    src_mls_listings list
                    join src_mls_ofs ofs
                        on list.listoffice_id = ofs.id

            ) l
                on mls.id = l.id

            left join HS_brokerage hb  --2.4k rows, company_id is unique id

                -- when the mls id's match exactly
                on trim(lower(mls.mls_id)) = trim(lower(hb.mls_id))

                -- individual combination of name, state, office, city, and zip codes match
                or(
                    jarowinkler_similarity(trim(lower(mls.mls_state)), trim(lower(hb.state))) >= 93
                    and jarowinkler_similarity(trim(lower(mls.mls_Name)), trim(lower(hb.company_name))) >= 93
                    and jarowinkler_similarity(trim(lower(mls.mls_city)), trim(lower(hb.city))) >= 94
                    and jarowinkler_similarity(
                        trim(lower(regexp_replace(mls.mls_zip, '[^0-9]'))),
                        trim(lower(regexp_replace(hb.postal_code, '[^0-9]')))
                    ) = 100
                )

                -- concatenated name, city, state are similar and zip codes match
                or(
                    jarowinkler_similarity(
                        concat(
                            trim(lower(mls.mls_Name))
                            ,trim(lower(mls.mls_city))
                            ,trim(lower(mls.mls_state))
                        )
                        ,concat(
                            trim(lower(hb.company_name))
                            ,trim(lower(hb.city))
                            ,trim(lower(hb.state))
                        )
                    ) >= 93
                    and jarowinkler_similarity(
                            trim(lower(regexp_replace(mls.mls_zip, '[^0-9]'))),
                            trim(lower(regexp_replace(hb.postal_code, '[^0-9]')))
                    ) = 100
                )

                -- the websites are similar
                or jarowinkler_similarity(trim(lower(mls.mls_url)), trim(lower(hb.website_url))) >= 98

                -- the phone numbers match and the zip codes match
                or (
                    case
                        when left(regexp_replace(mls.mls_phone, '[^0-9]'), 1) = '1'
                            then ltrim(regexp_replace(mls.mls_phone, '[^0-9]'), 1)
                        else regexp_replace(mls.mls_phone, '[^0-9]')
                        end =
                    case
                        when left(regexp_replace(hb.phone_number, '[^0-9]'), 1) = '1'
                            then ltrim(regexp_replace(hb.phone_number, '[^0-9]'), 1)
                        else regexp_replace(hb.phone_number, '[^0-9]')
                        end
                    and jarowinkler_similarity(
                            trim(lower(regexp_replace(mls.mls_zip, '[^0-9]'))),
                            trim(lower(regexp_replace(hb.postal_code, '[^0-9]')))
                    ) = 100
                )

            left join src_hs_owners bgm on hb.brokeragegrowthmanager = bgm.ownerid
            left join src_hs_owners cs on (case when hb.assigned_cs_rep = '' then null else hb.assigned_cs_rep end) = cs.ownerid
            left join src_hs_owners srn on (case when hb.originalsalesrep = '' then null else hb.originalsalesrep end) = srn.ownerid

            left join src_tc_office tc  -- 263 rows, id is unique id
                on jarowinkler_similarity(trim(lower(tc.office_name)), trim(lower(hb.company_name))) >= 93
    )

    -- hubspot agents who aren't in the MLS
    ,unique_hb_brokerage as(
        select
            a.*
            ,tc.office_id
            ,tc.office_name
            ,tc.parent_office_id
            ,concat(bgm.firstname, ' ', bgm.lastname) as brokerageGrowthManagerName
            ,concat(srn.firstname, ' ', srn.lastname) as originalSalesRepName
            ,concat(cs.firstname, ' ', cs.lastname) as assignedCSRepName
        from
            hs_brokerage a
            left join src_tc_office tc
                on jarowinkler_similarity(trim(lower(tc.office_name)), trim(lower(a.company_name))) >= 93
            left join MLS_combined b on a.company_id = b.HB_company_id
            left join src_hs_owners bgm on a.brokeragegrowthmanager = bgm.ownerid
            left join src_hs_owners cs on (case when a.assigned_cs_rep = '' then null else a.assigned_cs_rep end) = cs.ownerid
            left join src_hs_owners srn on (case when a.originalsalesrep = '' then null else a.originalsalesrep end) = srn.ownerid
        where
            b.HB_company_id is null
    )-- desc table dev.working.mls_hubspot_brokerage

    -- Transactly brokerage who aren't in Hubspot/MLS
    ,unique_tc_brokerage as(
        select t.*
        from
            src_tc_office t
            left join hs_brokerage h
                on jarowinkler_similarity(trim(lower(t.office_name)), trim(lower(h.company_name))) >= 93
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
            ,hb.office_id as office_id

            -- matching
            ,null as pct_similar
            ,null as name_distance

            ----------------------------------------
            -- comparison fields
            ,null as MLS_name
            ,hb.company_name as hb_name
            ,hb.office_name as TC_company_name
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
            ,hb.office_Name
            ,hb.parent_office_id as tc_parentOfficeID

        from unique_hb_brokerage hb

        -- Transactly agents who aren't in Hubspot/MLS
        union all select
            -- unique ids
            null as ID
            ,null as MLS_key
            ,null as MLS_ID
            ,null as hb_company_id
            ,tc.office_id

            -- matching
            ,null as pct_similar
            ,null as name_distance

            ----------------------------------------
            -- comparison fields
            ,null as MLS_name
            ,null as hb_name
            ,tc.office_name as TC_company_name
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
            ,tc.office_name as tc_officeName
            ,tc.parent_office_id as tc_parentOfficeID

        from unique_tc_brokerage tc
    )

    select
        working.seq_dim_brokerage.nextval as brokerage_pk
        ,ca.*
        ,case
            when office_id is not null then 'client'
            when hb_company_id is not null and office_id is null then 'prospect'
            when mls_id is not null and hb_company_id is null and office_id is null then 'MLS only'
            else '?'
            end as client_indicator
    from
        combine_all ca


    union select '0', '0', '0', '0', '0', '0', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null
