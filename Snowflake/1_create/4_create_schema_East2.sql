use role sysadmin;

---------------------------------------------------------------------------------------------------
-- create warehouses

create warehouse if not exists compute_wh with warehouse_size = xsmall scaling_policy = economy auto_resume = true auto_suspend = 60 initially_suspended = true max_cluster_count = 1;



---------------------------------------------------------------------------------------------------
-- create databases

create database if not exists dev;
create database hubspot_extract;



---------------------------------------------------------------------------------------------------
-- create schemas

create schema if not exists dev.working;
create schema hubspot_extract.v2_daily;
create schema hubspot_extract.v2_live;



----------------------------------------------------------------------------------------------------
-- create users

create user if not exists sbrown default_role = data_engineer default_warehouse = compute_wh default_namespace = dev.working;



----------------------------------------------------------------------------------------------------
-- create user roles

create role if not exists data_engineer;



----------------------------------------------------------------------------------------------------
-- create object roles

create role if not exists hubspot_owner;
create role if not exists hubspot_extract_owner;
create role if not exists dev_owner;

