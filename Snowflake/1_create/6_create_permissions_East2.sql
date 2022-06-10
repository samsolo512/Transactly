use role securityadmin;

----------------------------------------------------------------------------------------------------
-- grant user roles to users

grant role data_engineer to user sbrown;



----------------------------------------------------------------------------------------------------
-- grant user roles to user roles

-- grant user roles to data_engineer;

-- grant user roles to sysadmin




----------------------------------------------------------------------------------------------------
-- grant object roles and warehouses to user roles

-- data_engineer
grant role hubspot_owner to role data_engineer;
grant role hubspot_extract_owner to role data_engineer;
grant role dev_owner to role data_engineer;
grant usage on warehouse compute_wh to role data_engineer;


-- sysadmin




----------------------------------------------------------------------------------------------------
-- grant privileges to object roles

-- hubspot_owner
grant imported privileges on database hubspot to role hubspot_owner;


-- hubspot_extract_owner
grant ownership on database hubspot_extract to role hubspot_extract_owner;
grant ownership on all schemas in database hubspot_extract to role hubspot_extract_owner;
grant ownership on all tables in database hubspot_extract to role hubspot_extract_owner;
grant ownership on future tables in database hubspot_extract to role hubspot_extract_owner;
grant ownership on all views in database hubspot_extract to role hubspot_extract_owner;
grant ownership on future views in database hubspot_extract to role hubspot_extract_owner;


-- dev_owner
grant ownership on database dev to role dev_owner;
grant ownership on all schemas in database dev to role dev_owner;
grant ownership on all tables in database dev to role dev_owner;
grant ownership on future tables in database dev to role dev_owner;
