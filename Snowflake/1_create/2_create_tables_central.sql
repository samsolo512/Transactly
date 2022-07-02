-- create schema at database level

/*
use prod.dimensional;
use stage.dimensional;
use dev.dimensional;
 */

---------------------------------------------------------------------------------------------------
-- create tables

-- dim_agent
create or replace table dim_agent(
    agent_pk int identity primary key
    ,key varchar not null
    ,agentMLSID varchar not null
    ,fullName varchar
    ,agentEmail varchar
    ,agentCellPhone varchar
    ,agentOfficePhone varchar
    ,agentDirectPhone varchar
    ,agentAddress varchar
    ,agentCity varchar
    ,agentState varchar
    ,agentZipCode varchar
    ,StateLicense varchar
    ,source varchar
    ,AOR varchar
    ,mainOfficeMLSID varchar
    ,officeMLSID varchar
    ,brokerMLSID varchar
    ,update_datetime datetime
)
;
create or replace sequence working.seq_dim_agent start=1 increment=1;



-- dim_brokerage.sql
create or replace table dim_brokerage(
    brokerage_pk int identity primary key
    ,key varchar not null
    ,officeMLSID varchar not null
--     ,updatedDate timestamp_tz
    ,officeName varchar
    ,originatingSystemName varchar
    ,officeAddress varchar
    ,officeCity varchar
    ,stateOrProvince varchar
    ,postalCode varchar
    ,phone varchar
    ,source varchar
    ,url varchar
    ,mlsID varchar
    ,update_datetime datetime
)
;
create or replace sequence working.seq_dim_brokerage start=1 increment=1;



-- dim_contract
create or replace table dim_contract(
    contract_pk int identity primary key
    ,contract_id int not null
    ,party varchar
    ,contract_closing_date date
    ,update_datetime datetime
)
;
create or replace sequence working.seq_dim_contract start=1 increment=1;



-- dim_date
create or replace table dim_date (
    date_pk int not null primary key
    ,date_id date not null
    ,year smallint not null
    ,month smallint not null
    ,month_name char(3) not null
    ,day_of_mon smallint not null
    ,day_of_week varchar(9) not null
    ,week_of_year smallint not null
    ,day_of_year smallint not null
    ,update_datetime datetime
)
;
create or replace sequence working.seq_dim_client start=1 increment=1;



-- dim_line_item
create or replace table dim_line_item(
    line_item_pk int identity primary key
    ,line_item_id int not null
    ,status varchar
    ,description varchar
    ,update_datetime datetime
)
;
create or replace sequence working.seq_dim_line_item start=1 increment=1;



-- dim_listing
create or replace table dim_listing(
    listing_pk int not null primary key
    ,listingkey varchar not null
    ,status varchar
    ,listprice number
    ,closeprice number
    ,listingid varchar
    ,update_datetime datetime
    ,streetdirprefix varchar
    ,streetsuffix varchar
    ,streetname varchar
    ,streetnumber varchar
    ,listingContractDate varchar
    ,closeDate date
    ,cumulativeDaysOnMarket int
)
;
create or replace sequence working.seq_dim_listing start=1 increment=1;


create or replace sequence working.seq_dim_order start=1 increment=1;


-- dim_task
create or replace table dim_task(
    task_pk int identity primary key
    ,task_id int not null
    ,party varchar
    ,task_due_date date
    ,task_completed_date date
    ,update_datetime datetime
)
;
create or replace sequence working.seq_dim_task start=1 increment=1;



-- dim_transaction_order
create or replace table dim_transaction_order(
    transaction_order_pk int identity primary key
    ,transaction_id int not null
    ,order_id int
    ,assigned_TC varchar
    ,transaction_created_by varchar
    ,transaction_created_date date
    ,transaction_closed_date date
--     ,title_agent
    ,order_status varchar
    ,order_type varchar
    ,order_created_date date
--     ,days_to_create_tran
    ,update_datetime datetime
)
;
create or replace sequence working.seq_dim_transaction_order start=1 increment=1;



-- dim_user
create or replace table dim_user(
    user_pk int identity primary key
    ,user_id int not null
    ,first_name varchar
    ,last_name varchar
    ,full_name varchar
    ,email varchar
    ,license_state string(30)
    ,brokerage string(100)
    ,user_is_active_flag int
    ,valid_email_flag int
    ,update_datetime datetime
)
;
create or replace sequence working.seq_dim_user start=1 increment=1;



-- fact_contract
create or replace table fact_contract(
    transaction_pk int
    ,contract_pk int
    ,days_tran_closed_before_contract int
    ,update_datetime datetime
)
;



-- fact_listing
create or replace table fact_listing(
    listing_pk int
    ,brokerage_pk int
    ,agent_pk int
    ,active_flag int
    ,cancelled_or_withdrawn_flag int
    ,closed_flag int
    ,update_datetime datetime
)
;



-- fact_order_line_item
create or replace table fact_order_line_item(
    transaction_order_pk int
    ,line_item_pk int
    ,user_pk int
    ,line_item_created_date_pk int
    ,line_item_due_date_pk int
    ,line_item_cancelled_date_pk int
    ,days_to_close int
    ,agent_pays number
    ,price number
    ,order_transact_start_lag number
    ,in_progress_flag int
    ,withdrawn_flag int
    ,cancelled_flag int
    ,update_datetime datetime
    ,primary key(transaction_order_pk, line_item_pk)
)
;



-- fact_transaction
create or replace table fact_transaction(
    transaction_order_pk int
    ,update_datetime datetime
    ,primary key(transaction_order_pk)
)
;



-- fact_user_month
create or replace table fact_user_month(
    user_pk number
    ,order_month_pk number
    ,order_count number
    ,agent_pays_sum number
    ,price_sum number
    ,update_datetime datetime
    ,primary key(user_pk, order_month_pk)
)
;
