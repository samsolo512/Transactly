-- chart of the number of unique users per day
select
    cast(a.created as date) as created
    ,count(distinct a.user) as user
from "FIVETRAN"."TRANSACTLY_APP_PRODUCTION_REC_ACCOUNTS"."REQUEST_LOG" a
where
    a.created between '2021-10-01' and '2022-01-01'
//    cast(a.created as date) between '2021-10-27' and '2021-10-30'
group by cast(a.created as date)
order by created
;


-- a complete list of all false users
select 
    user
    ,trim(user) regexp '^[a-zA-Z0-9._+\-]*@[a-zA-Z0-9._+\-]*\.[a-zA-Z0-9._+\-]*$' as valid_user_id
    ,count(1)
from "FIVETRAN"."TRANSACTLY_APP_PRODUCTION_REC_ACCOUNTS"."REQUEST_LOG" a
where
    valid_user_id = 'FALSE'
//    and cast(a.created as date) between '2021-10-27' and '2021-10-30'
group by user, trim(user) regexp '^[a-zA-Z0-9._+\-]*@[a-zA-Z0-9._+\-]*\.[a-zA-Z0-9._+\-]*$'
order by count(1)
;


-- all false users that didn't occur on 10/27/21 and 10/30/21
select
    a.user
    ,count(1)
from "FIVETRAN"."TRANSACTLY_APP_PRODUCTION_REC_ACCOUNTS"."REQUEST_LOG" a
where
    trim(user) regexp '^[a-zA-Z0-9._+\-]*@[a-zA-Z0-9._+\-]*\.[a-zA-Z0-9._+\-]*$' = 'FALSE'
    and cast(a.created as date) <> '2021-10-27'
    and cast(a.created as date) <> '2021-10-30'
group by a.user
order by 2 desc
;


-- login history
select user_name, is_success, max(event_timestamp) event_timestamp 
from snowflake.account_usage.login_history
group by user_name, is_success
order by event_timestamp desc
;


-- most recent user grants
select created_on, role, grantee_name
from snowflake.account_usage.grants_to_users
where deleted_on is null
order by created_on desc
;


-- most recent role grants
select modified_on, privilege, concat(table_catalog, '.', table_schema) as path, name, grantee_name, granted_on as object_type
from snowflake.account_usage.grants_to_roles
where deleted_on is null
order by modified_on desc
;


-- running sum credits used
select 
    start_time
    ,credits_used
    ,sum(credits_used) over(order by start_time) as running_sum 
from(
    select 
        cast(start_time as date) start_time
        ,sum(credits_used) as credits_used
    from snowflake.organization_usage.warehouse_metering_history
    group by cast(start_time as date)
)
group by start_time, credits_used
order by start_time desc
;


-- latest users added

-- successful/failed jobs