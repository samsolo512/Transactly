use role securityadmin;

----------------------------------------------------------------------------------------------------
-- grant user roles to users

grant role fivetran_role to user fivetran_user;
grant role data_engineer to user sbrown;
grant role orgadmin to user sbrown;
grant role orgadmin to user nniemeyer;
grant role orgadmin to user accountadmin;
grant role powerbi_role to user powerbi_svc;
grant role tableau_role to user tableau_svc;
grant usage on warehouse PowerBI_WH to role PowerBI_role;
grant role admin_read to user catherineharris;
grant role airbyte_role to user airbyte_svc;
grant role data_analyst to user qstrother;
grant role data_analyst to user mclifton;
grant role dbt_role to user dbt_svc;



----------------------------------------------------------------------------------------------------
-- grant user roles to user roles

-- grant user roles to data_engineer;
grant role fivetran_role to role data_engineer;
grant role tableau_role to role data_engineer;
grant role data_analyst to role data_engineer;
grant role dbt_role to role data_engineer;


-- grant user roles to sysadmin
grant role fivetran_role to role sysadmin;
grant role data_engineer to role sysadmin;
grant role airbyte_role to role sysadmin;
grant role dbt_role to role sysadmin;


----------------------------------------------------------------------------------------------------
-- grant object roles and warehouses to user roles

-- airbyte_role
grant role airbyte_owner to role airbyte_role;
grant usage on warehouse airbyte_wh to role airbyte_role;


-- dbt_role
grant role hubspot_extract_owner to role dbt_role;
grant role skyvia_owner to role dbt_role;
grant role fivetran_owner to role dbt_role;
grant role dev_owner to role dbt_role;
grant usage on warehouse dbt_wh to role dbt_role;


-- fivetran_role
grant role fivetran_owner to role fivetran_role;
grant usage on warehouse fivetran_wh to role fivetran_role;


-- data_engineer
grant role prod_owner to role data_engineer;
grant role stage_owner to role data_engineer;
grant role dev_owner to role data_engineer;
grant role fivetran_owner to role data_engineer;
grant role admin_read to role data_engineer;
grant role fivetran_read to role data_engineer;
grant role account_support to role data_engineer;
grant role airbyte_role to role data_engineer;
grant role airbyte_owner to role data_engineer;
grant role skyvia_read to role data_engineer;
grant role skyvia_owner to role data_engineer;
grant usage on warehouse compute_wh to role data_engineer;
grant usage on warehouse powerbi_wh to role data_engineer;
grant usage on warehouse tableau_wh to role data_engineer;
grant usage on warehouse transactlydev to role data_engineer;
grant usage on warehouse airbyte_wh to role airbyte_role;
grant usage on integration GCP to role data_engineer;
grant imported privileges on database snowflake to role data_engineer;  -- so can view snowflake database


-- sysadmin
grant role prod_owner to role sysadmin;
grant role stage_owner to role sysadmin;
grant role dev_owner to role sysadmin;
grant role fivetran_owner to role sysadmin;
grant role airbyte_owner to role sysadmin;


-- tableau_role
grant role prod_load_read to role tableau_role;
grant usage on warehouse tableau_wh to role tableau_role;


-- PowerBI_role
grant role prod_load_read to role PowerBI_role;
grant usage on warehouse powerbi_wh to role PowerBI_role;


-- admin_read
grant role fivetran_read to role admin_read;
grant role prod_load_read to role admin_read;
grant role dev_read to role admin_read;
grant usage on warehouse compute_wh to role admin_read;
grant role skyvia_read to role admin_read;


-- data_analyst
grant role fivetran_read to role admin_read;
grant role prod_load_read to role admin_read;
grant usage on warehouse compute_wh to role admin_read;
grant role skyvia_read to role data_analyst;


----------------------------------------------------------------------------------------------------
-- grant privileges to object roles

-- account_support
grant manage account support cases on account to role account_support;


-- airbyte_owner
grant ownership on database airbyte to role airbyte_owner;
grant ownership on all schemas in database airbyte to role airbyte_owner;
grant ownership on future schemas in database airbyte to role airbyte_owner;
grant ownership on all tables in database airbyte to role airbyte_owner;
grant ownership on future tables in database airbyte to role airbyte_owner;
grant create schema, monitor, usage on database airbyte to role airbyte_owner;


-- fivetran_owner
grant ownership on database fivetran to role fivetran_owner revoke current grants;
grant ownership on all schemas in database fivetran to role fivetran_owner revoke current grants;
grant ownership on future schemas in database fivetran to role fivetran_owner;
grant ownership on all tables in database fivetran to role fivetran_owner revoke current grants;
grant ownership on future tables in database fivetran to role fivetran_owner;
grant create schema, monitor, usage on database fivetran to role fivetran_owner;


-- fivetran_read
grant usage on database fivetran to role fivetran_read;
grant usage on all schemas in database fivetran to role fivetran_read;
grant usage on future schemas in database fivetran to role fivetran_read;
grant select on all tables in database fivetran to role fivetran_read;
grant select on future tables in database fivetran to role fivetran_read;


-- prod_owner
grant ownership on database prod to role prod_owner;
grant ownership on all schemas in database prod to role prod_owner;
grant ownership on all tables in database prod to role prod_owner revoke current grants;
grant ownership on all procedures in database prod to role prod_owner;
grant ownership on all sequences in database prod to role prod_owner;
revoke ownership on future schemas in database prod from role prod_owner;
revoke ownership on future tables in database prod from role prod_owner;
revoke ownership on future procedures in database prod from role prod_owner;
revoke ownership on future sequences in database prod from role prod_owner;
revoke ownership on future tables in schema prod.public from role prod_owner;
grant ownership on future schemas in database prod to role prod_owner;
grant ownership on future tables in database prod to role prod_owner;
grant ownership on future procedures in database prod to role prod_owner;
grant ownership on future sequences in database prod to role prod_owner;
grant ownership on future tables in schema prod.public to role prod_owner


-- stage_owner
grant ownership on database stage to role stage_owner;
grant ownership on all schemas in database stage to role stage_owner;
grant ownership on all tables in database stage to role stage_owner revoke current grants;
grant ownership on all procedures in database stage to role stage_owner;
grant ownership on all sequences in database stage to role stage_owner;
revoke ownership on future schemas in database stage from role stage_owner;
revoke ownership on future tables in database stage from role stage_owner;
revoke ownership on future procedures in database stage from role stage_owner;
revoke ownership on future sequences in database stage from role stage_owner;
revoke ownership on future tables in schema stage.public from role stage_owner;
grant ownership on future schemas in database stage to role stage_owner;
grant ownership on future tables in database stage to role stage_owner;
grant ownership on future procedures in database stage to role stage_owner;
grant ownership on future sequences in database stage to role stage_owner;
grant ownership on future tables in schema stage.public to role stage_owner;


-- dev_owner
grant ownership on database dev to role dev_owner;
grant ownership on all schemas in database dev to role dev_owner;
grant ownership on all tables in database dev to role dev_owner revoke current grants;
grant ownership on all procedures in database dev to role dev_owner;
grant ownership on all sequences in database dev to role dev_owner;
revoke ownership on future schemas in database dev from role dev_owner;
revoke ownership on future tables in database dev from role dev_owner;
revoke ownership on future procedures in database dev from role dev_owner;
revoke ownership on future sequences in database dev from role dev_owner;
revoke ownership on future tables in schema dev.public from role dev_owner;
grant ownership on future schemas in database dev to role dev_owner;
grant ownership on future tables in database dev to role dev_owner;
grant ownership on future procedures in database dev to role dev_owner;
grant ownership on future sequences in database dev to role dev_owner;
grant ownership on future tables in schema dev.public to role dev_owner;
grant create stage on schema dev.working to role dev_owner;


-- dev_read
grant usage on database dev to role dev_read;
grant usage on all schemas in database dev to role dev_read;
grant select on all tables in database dev to role dev_read;
grant select on future tables in database dev to role dev_read;
grant usage on future schemas in database dev to role dev_read;


-- grant privileges to object role prod_load_read
grant usage on database prod to role prod_load_read;
grant usage on schema prod.load to role prod_load_read;
grant select on all tables in schema prod.load to role prod_load_read;
grant select on future tables in schema prod.load to role prod_load_read;


-- hubspot_extract_owner
grant ownership on database hubspot_extract to role hubspot_extract_owner;
grant ownership on all schemas in database hubspot_extract to role hubspot_extract_owner;
grant ownership on future schemas in database hubspot_extract to role hubspot_extract_owner;
grant ownership on all tables in database hubspot_extract to role hubspot_extract_owner;
grant ownership on future tables in database hubspot_extract to role hubspot_extract_owner;
grant ownership on all views in database hubspot_extract to role hubspot_extract_owner;
grant ownership on future views in database hubspot_extract to role hubspot_extract_owner;


-- skyvia_read
grant usage on database skyvia to role skyvia_read;
grant usage on all schemas in database skyvia to role skyvia_read;
grant usage on future schemas in database skyvia to role skyvia_owner;
grant select on all tables in database skyvia to role skyvia_read;
grant select on future tables in database skyvia to role skyvia_read;


-- skyvia_owner
grant ownership on database skyvia to role skyvia_owner;
grant ownership on all schemas in database skyvia to role skyvia_owner revoke current grants;
grant ownership on future schemas in database skyvia to role skyvia_owner;
grant ownership on all tables in database skyvia to role skyvia_owner;
revoke ownership on future tables in database skyvia to role skyvia_owner;