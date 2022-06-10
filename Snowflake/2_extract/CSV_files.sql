----------------------------------------------------------------------------------------------------------------------------------------
-- working.hubspot_brokerages_csv
-- from file: 22_04_22_Hubspot_Brokerages


/*
to prepare CSVs
    add a column representing the survey_response_id.  I used the term dash unique id (2216-1, 2216-2...)
    UNPIVOT the question/answer columns - those columns we want to turn into rows
    do a mass replacement of:
        commas for a single space
        line breaks for a single space
            ctrl +J = line break
            if that doesn't work, use =SUBSTITUTE(SUBSTITUTE(B2,CHAR(13),""),CHAR(10),"")  -- https://www.ablebits.com/office-addins-blog/2013/12/03/remove-carriage-returns-excel/
*/



-- create file format
create or replace file format CSV_File_Format
    type = 'CSV'
    field_delimiter = ','
    skip_header = 1
;

show file formats;
desc file format csv_file_format;



-- create stage
create or replace stage CSV_stage
    file_format = CSV_File_Format
;
show stages;
list @csv_stage;



-- in SnowSQL
-- login to cmd prompt
-- snowSQL -a fl27750.us-central1.gcp -u sbrown
-- OR snowSQL -c config
-- put file:///C:\Users\Sam\Dropbox\Transactly\Flat_Files\22_04_22_Hubspot_Brokerages.csv @CSV_STAGE overwrite = true;




-- create table
create or replace table working.hubspot_brokerages as
select 
    $1 as company_id
    ,$2 as company_name
    ,$3 as transactly_office_id
    ,$4 as original_sales_rep_company
    ,$5 as recent_deal_amount
    ,$6 as recent_deal_close_date
    ,$7 as contract_effective_date
    ,$8 as office_subscription_plan
    ,$9 as office_subscription_renewal_date
    ,$10 as brokerage_onboarding_date
    ,$11 as MLS_id
    ,$12 as MLS_system_name
    ,$13 as email
    ,$14 as principal_broker_email_address
    ,$15 as phone_number
    ,$16 as street_address_1
    ,$17 as street_address_2
    ,$18 as city
    ,$19 as state
    ,$20 as postal_code
    ,$21 as brokerage_growth_manager
    ,$22 as assigned_cs_rep
    ,$23 as last_engagement_date
    ,$24 as can_we_send_emails_to_agents
    ,$25 as company_domain_name
    ,$26 as website_url
    ,$27 as billing_contact_name
from @CSV_stage/22_04_22_Hubspot_Brokerages.csv.gz
;


select * from working.HUBSPOT_BROKERAGES_csv;


remove @CSV_stage/22_04_22_Hubspot_Brokerages.csv.gz;
list @csv_stage;

