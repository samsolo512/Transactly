with object_properties as(
    select *
    from {{ ref('src_hs_object_properties') }}
)

select
    orderid as company_id
    ,name as company_name
    --transactly_office_id
    ,original_sales_rep as originalSalesRep
    ,recent_deal_amount  as recentdealamount
    ,recent_deal_close_date as recentclosedate
    ,contract_date as contracteffectivedate
    ,office_subscription_plan_tier as officesubscriptionplan
--     ,office_subscription_renewal_date as officesubscriptionrenewaldate
    ,brokerage_onboarding_date as brokerageonboardingdate
    ,id__mls_ as mls_id
    ,mls_system_names as mls_system_name
    ,email  -- email
    ,principal_broker_s_email_address as principalbrokeremail
    ,phone as phone_number
    ,address as street_address_1
    ,address2 as street_address_2
    ,city  -- city
    ,state  -- state
    ,zip as postal_code
    ,brokerage_growth_manager as brokeragegrowthmanager
    ,assigned_cs_rep  -- assigned_cs_rep
    ,hs_last_sales_activity_timestamp as lastengagementdate
    -- can_we_send_emails_to_agents
    ,domain as companydomainname
    ,website as website_url
    ,billing_contact_name

from(

    select
        objectid
        ,name
        ,value
    from
        object_properties p
    where
        objecttypeid = '0-2'
        and name in(
            'name'  -- company_name
            --transactly_office_id
            ,'original_sales_rep'  -- original_sales_rep_company
            ,'recent_deal_amount'  -- recent_deal_amount
            ,'recent_deal_close_date'  -- recent_deal_close_date
            ,'contract_date'  -- contract_effective_date
            ,'office_subscription_plan_tier'  -- office_subscription_plan
--             ,office_subscription_renewal_date
            ,'brokerage_onboarding_date'  -- brokerage_onboarding_date
            ,'id__mls_'  -- mls_id
            ,'mls_system_names'  -- mls_system_name
            ,'email'  -- email
            ,'principal_broker_s_email_address'  -- principal_broker_email_address
            ,'phone'  -- phone_number
            ,'address'  -- street_address_1
            ,'address2'  -- street_address_2
            ,'city'  -- city
            ,'state'  -- state
            ,'zip'  -- postal_code
            ,'brokerage_growth_manager'  -- brokerage_growth_manager
            ,'assigned_cs_rep'  -- assigned_cs_rep
            ,'hs_last_sales_activity_timestamp'  -- last_engagement_date
            -- can_we_send_emails_to_agents
            ,'domain'  -- company_domain_name
            ,'website'  -- website_url
            ,'billing_contact_name'  -- billing_contact_name
        )
) as r

pivot(
    max(value) for name in(
        'name'
        ,'original_sales_rep'
        ,'recent_deal_amount'
        ,'recent_deal_close_date'
        ,'contract_date'
        ,'office_subscription_plan_tier'
        ,'brokerage_onboarding_date'
        ,'id__mls_'
        ,'mls_system_names'
        ,'email'
        ,'principal_broker_s_email_address'
        ,'phone'
        ,'address'
        ,'address2'
        ,'city'
        ,'state'
        ,'zip'
        ,'brokerage_growth_manager'
        ,'assigned_cs_rep'
        ,'hs_last_sales_activity_timestamp'
        ,'domain'
        ,'website'
        ,'billing_contact_name'
    )
) as p(
    orderid
    ,name
    ,original_sales_rep
    ,recent_deal_amount
    ,recent_deal_close_date
    ,contract_date
    ,office_subscription_plan_tier
    ,brokerage_onboarding_date
    ,id__mls_
    ,mls_system_names
    ,email
    ,principal_broker_s_email_address
    ,phone
    ,address
    ,address2
    ,city
    ,state
    ,zip
    ,brokerage_growth_manager
    ,assigned_cs_rep
    ,hs_last_sales_activity_timestamp
    ,domain
    ,website
    ,billing_contact_name
)
