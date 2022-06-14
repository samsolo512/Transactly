-- create schema at acct level

/*
use prod.dimensional;
use stage.dimensional;
use dev.dimensional;
 */

use role sysadmin;
---------------------------------------------------------------------------------------------------
-- create warehouses

create warehouse if not exists airbyte_wh with WAREHOUSE_SIZE = xsmall max_cluster_count = 1 auto_suspend = 30 auto_resume = true scaling_policy = economy INITIALLY_SUSPENDED = true;
create warehouse if not exists compute_wh with warehouse_size = xsmall scaling_policy = economy auto_resume = true auto_suspend = 60 initially_suspended = true max_cluster_count = 1;
create warehouse if not exists fivetran_wh with warehouse_size = xsmall scaling_policy = economy auto_resume = true auto_suspend = 60 initially_suspended = true max_cluster_count = 1;
create warehouse if not exists PowerBI_WH with WAREHOUSE_SIZE = xsmall max_cluster_count = 1 auto_suspend = 30 auto_resume = true scaling_policy = economy INITIALLY_SUSPENDED = true;
create warehouse if not exists Tableau_WH with WAREHOUSE_SIZE = xsmall max_cluster_count = 1 auto_suspend = 30 auto_resume = true scaling_policy = economy INITIALLY_SUSPENDED = true;
create warehouse if not exists dbt_WH with WAREHOUSE_SIZE = xsmall max_cluster_count = 1 auto_suspend = 30 auto_resume = true scaling_policy = economy INITIALLY_SUSPENDED = true;



---------------------------------------------------------------------------------------------------
-- create databases

create database if not exists airbyte;
create database if not exists fivetran;
create database if not exists dev;
create database if not exists prod;
create database if not exists stage;



---------------------------------------------------------------------------------------------------
-- create schemas

create schema if not exists airbyte.postgreSQL;
create schema if not exists dev.dimensional;
create schema if not exists dev.working;
create schema if not exists dev.load;
create schema if not exists dev.models;
create schema if not exists prod.dimensional;
create schema if not exists prod.working;
create schema if not exists prod.load;
create schema if not exists stage.dimensional;
create schema if not exists stage.working;
create schema if not exists stage.load;



use role useradmin;
----------------------------------------------------------------------------------------------------
-- create or modify service accounts
create user if not exists airbyte_svc default_role = airbyte_role default_warehouse = airbyte_wh default_namespace = airbyte.postgreSQL password = '' must_change_password = false;
create user if not exists powerbi_svc default_role = powerbi_role default_warehouse = powerbi_wh default_namespace = prod.load password = '' must_change_password = false;
create user if not exists tableau_svc default_role = tableau_role default_warehouse = tableau_wh default_namespace = prod.load password = '' must_change_password = false;
create user if not exists dbt_svc default_role = dbt_role default_warehouse = dbt_WH default_namespace = dev.models password = '' must_change_password = false;
create user if not exists fivetran_user default_role = fivetran_role default_warehouse = fivetran_wh password = '' must_change_password = false;


-- create or modify users
create user if not exists sbrown default_role = data_engineer default_warehouse = compute_wh default_namespace = dev.dimensional;
create user if not exists CATHERINEHARRIS default_role = sysadmin default_warehouse = compute_wh default_namespace = prod.load;
create user if not exists NNIEMEYER default_role = accountadmin default_warehouse = compute_wh default_namespace = prod.load;
create user if not exists qstrother default_role = data_analyst default_warehouse = compute_wh default_namespace = prod.load password = 'DiFBuyCxFWTIUpw7Y3XU' must_change_password = true;
create user if not exists mclifton default_role = data_analyst default_warehouse = compute_wh default_namespace = prod.load password = 'DiFBuyCxFWTIUpw7Y3XU' must_change_password = true;


-- create user roles
create role if not exists admin_read;
create role if not exists airbyte_role;
create role if not exists account_support;
create role if not exists data_analyst;
create role if not exists data_engineer;
create role if not exists dbt_role;
create role if not exists fivetran_role;
create role if not exists powerbi_role;
create role if not exists tableau_role;


-- create object roles
create role if not exists airbyte_owner;
create role if not exists fivetran_owner;
create role if not exists fivetran_read;
create role if not exists hubspot_extract_owner;
create role if not exists prod_owner;
create role if not exists prod_read;
create role if not exists prod_load_read;
create role if not exists stage_owner;
create role if not exists stage_read;
create role if not exists dev_owner;
create role if not exists dev_read;
create role if not exists skyvia_read;
create role if not exists skyvia_owner;



---------------------------------------------------------------------------------------------------
-- create integration to link to GCP

use role accountadmin;
grant create integration on account to role data_engineer;


use role sysadmin;


-- https://docs.snowflake.com/en/user-guide/data-load-gcs-config.html
-- https://docs.snowflake.com/en/sql-reference/sql/create-storage-integration.html


-- necessary permissions (located in the permissions file)
/*
--use role sysadmin;
grant create integration on account to role data_engineer;
--use role securityadmin;
grant create stage on schema dev.working to role data_engineer;
grant usage on integration GCP to role data_engineer;
*/


-- step 1: create the integration
create storage if not exists integration GCP
    type = external_stage
    storage_provider = GCS
    enabled = true
    storage_allowed_locations = ('gcs://tc_snowflake_exports/exports/')
;


-- step 2: get the storage_gcp_service_account
-- there is only one GCP storage service acct provisioned per Snowflake acct
-- desc integration GCP;
-- service acct: dfckwweeuu@gcpuscentral1-1dfa.iam.gserviceaccount.com


-- step 3: grant the service acct permissions to access bucket objects
-- this is where you create a custom GCP role to access buckets and assign it to the service acct
-- see the above URL for details


-- step 4: create an external stage
-- step 4A: create a file format if needed, to be plugged into the stage
-- https://docs.snowflake.com/en/sql-reference/sql/create-file-format.html#usage-notes
-- https://cloud.google.com/bigquery/docs/loading-data-cloud-storage-csv
//create file format if not exists csv_format
create or replace file format csv_format
    type = csv
    empty_field_as_null = false
    escape_unenclosed_field = none
    field_optionally_enclosed_by = none
    --field_delimiter = '\\011'  -- tab
    field_delimiter = '^'
    null_if=('')
;

-- step 4b: create a stage
create stage if not exists dimensional.GCP_stage
//create or replace stage dimensional.GCP_stage
    url = 'gcs://tc_snowflake_exports/exports/'
    storage_integration = GCP
    file_format = csv_format
;


