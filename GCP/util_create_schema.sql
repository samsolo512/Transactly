CREATE SCHEMA if not exists `data-sandbox-343520`.load
;


-- dim_contract (GCP)
create or replace table dim_contract(
    contract_pk int
    ,contract_id int
    ,party string(100)
    ,contract_closing_date date
    ,load_datetime datetime
    ,update_datetime datetime
)
;


-- dim_date (GCP)
create or replace table `data-sandbox-343520`.load.dim_date (
    date_pk int
    ,date_id date
    ,year smallint
    ,month smallint
    ,month_name string(3)
    ,day_of_mon smallint
    ,day_of_week string(9)
    ,week_of_year smallint
    ,day_of_year smallint
)
;


-- dim_line_item (GCP)
create or replace table `data-sandbox-343520`.load.dim_line_item(
    line_item_pk int 
    ,line_item_id int
    ,load_datetime datetime
    ,update_datetime datetime
)
;


-- dim_task (GCP)
create or replace table `data-sandbox-343520`.load.dim_task(
    task_pk int
    ,task_id int
    ,party string(100)
    ,task_due_date date
    ,task_completed_date date
    ,load_datetime datetime
    ,update_datetime datetime
)
;


-- dim_transaction_order (GCP)
create or replace table `data-sandbox-343520`.load.dim_transaction_order(
    transaction_order_pk int
    ,transaction_id int
    ,order_id int
    ,assigned_TC string(100)
    ,transaction_created_by string(100)
    ,transaction_created_date date
    ,transaction_closed_date date
--     ,title_agent
    ,order_status string(100)
    ,order_type string(100)
    ,order_created_date date
--     ,days_to_create_tran
    ,load_datetime datetime
    ,update_datetime datetime
)
;
;


-- dim_user (GCP)
create or replace table `data-sandbox-343520`.load.dim_user(
    user_pk int
    ,user_id int
    ,first_name string(100)
    ,last_name string(100)
    ,full_name string(200)
    ,email string(200)
    ,license_state string(30)
    ,brokerage string(100)
    ,user_is_active_flag int
    ,valid_email_flag int
    ,load_datetime datetime
    ,update_datetime datetime
)
;


-- fact_contract (GCP)
create or replace table `data-sandbox-343520`.load.fact_contract(
    transaction_pk int
    ,contract_pk int
    ,days_tran_closed_before_contract int
    ,load_datetime datetime
    ,update_datetime datetime
)
;


-- fact_order_line_item (GCP)
create or replace table `data-sandbox-343520`.load.fact_order_line_item(
    transaction_pk int
    ,order_pk int
    ,line_item_pk int
    ,user_pk int
    ,order_created_date_pk int
    ,transaction_created_date_pk int
    ,transaction_closed_date_pk int
    ,agent_pays bignumeric
    ,price bignumeric
    ,order_transact_start_lag bignumeric
    ,load_datetime datetime
    ,update_datetime datetime
)
;


-- fact_user_month (GCP)
create or replace table `data-sandbox-343520`.load.fact_user_month(
    user_pk int
    ,order_month_pk int
    ,order_count int
    ,agent_pays_sum int
    ,price_sum int
    ,load_datetime datetime
    ,update_datetime datetime
)
;


-- vw_order_line_item (GCP)
create or replace table load.vw_order_line_item(
    order_created_date date 
    ,transaction_created_date date
    ,transaction_closed_date date
    ,order_type string(50)
    ,order_status string(50)
    ,order_state string(50)
    ,first_name string(100)
    ,last_name string(100)
    ,full_name string(200)
    ,license_state string(50)
    ,brokerage string(500)
    ,agent_pays bignumeric
    ,transaction_price bignumeric
    ,order_transact_start_lag bignumeric
)
;
