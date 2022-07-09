select *
from
    hubspot_extract.v2_daily.object_properties
where
    value like '%9356042278%'
order by name
;


select *
from
    hubspot_extract.v2_daily.object_properties
where
    objectid = '9356042278'
order by name
;


select objectid, name, value, to_timestamp(value) lastdate
from
    hubspot_extract.v2_daily.object_properties
where
--     objectid = '9356042278'
--     and name like '%date%'
    name = 'notes_last_updated'
    and objecttypeid = '0-3'  --deal
    and value is not null
    and value <> ''
-- order by lastdate
;


SELECT distinct value
FROM HUBSPOT_EXTRACT.V2_DAILY.object_properties
where name = 'type'
order by 1
;





------------------------------------------------------------------------------------------------------------------------------
-- MLS_Hubspot_Agent

create or replace table dev.working.MLS_Hubspot_Agent as  -- select * from dev.working.MLS_Hubspot_Agent
select
    hs_object_id as contact_id
    ,firstname as first_name
    ,lastname as last_name
    ,brokerage_name
    ,to_number(case when transactly_user_id__app_ = '' then null else transactly_user_id__app_ end) as transactly_id
    ,createdate as created_date
    ,hs_lead_status as lead_status
    ,case when email = '' then null else email end as email
    ,original_sales_repr as original_sales_rep
    ,hubspot_owner_id as contact_owner
    ,hs_lifecyclestage_customer_date as became_a_customer
    ,renewal_date
    ,case when mobilephone = '' then null else mobilephone end as mobile_phone_number
    ,case when phone = '' then null else phone end as phone_number
    ,city
    ,state_province
    ,zip
    ,company as company_name
    ,brokerage_growth_manager
    ,type

from(

    select
        objectid
        ,name
        ,value
    from hubspot_extract.v2_daily.object_properties
    where
        objecttypeid = '0-1'
        and name in(
            'hs_object_id'  -- contact id
            ,'firstname'  -- first name
            ,'lastname'  -- last name
            ,'brokerage_name'  -- brokerage name
            ,'transactly_user_id__app_'  -- transactly user
            ,'createdate'  -- create date
            ,'hs_lead_status'  -- lead status
            ,'email'
            ,'original_sales_repr'  -- original sales rep
            ,'hubspot_owner_id'  -- contact owner
            ,'hs_lifecyclestage_customer_date'  -- became a customer
            -- is active (APP)
            -- assigned TC (APP)
            -- number of Active Transactions (APP)
            -- user number of orders (APP)
            ,'renewal_date'  -- renewal date (APP)
            -- agent role (APP)
            -- user subscription renewal date (APP)
            -- user number of transactions (APP)
            -- User Date of Last Service Ordered (APP)
            -- work email
            -- secondary email
            ,'mobilephone'  -- mobile phone number
            ,'phone'  -- phone number
            -- secondary phone number
            -- office address - street address 1
            -- office address - street address 2
            ,'city'  -- city
            ,'state_province'  -- State / Province
            ,'zip'  -- postal code
            ,'company'  -- company name
            -- brokerage plan member?
            -- listing MLS Number
            ,'brokerage_growth_manager'
            ,'type'
        )
//        and objectid = '30163801'

)

pivot(
    max(value) for name in(
        'firstname'
        ,'lastname'
        ,'brokerage_name'
        ,'transactly_user_id__app_'
        ,'createdate'
        ,'hs_lead_status'
        ,'email'
        ,'original_sales_repr'
        ,'hubspot_owner_id'
        ,'hs_lifecyclestage_customer_date'
        ,'renewal_date'
        ,'mobilephone'
        ,'phone'
        ,'city'
        ,'state_province'
        ,'zip'
        ,'company'
        ,'brokerage_growth_manager'
        ,'type'
    )
)
as p(
    hs_object_id
    ,firstname
    ,lastname
    ,brokerage_name
    ,transactly_user_id__app_
    ,createdate
    ,hs_lead_status
    ,email
    ,original_sales_repr
    ,hubspot_owner_id
    ,hs_lifecyclestage_customer_date
    ,renewal_date
    ,mobilephone
    ,phone
    ,city
    ,state_province
    ,zip
    ,company
    ,brokerage_growth_manager
    ,type
)
;
