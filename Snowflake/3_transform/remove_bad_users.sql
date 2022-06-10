---------------------------------------------------------------------------------------------------
-- remove hack attempt 'users' from request_log table


create schema working;

-- find the records we are interested in
select  --10113
        case
            when trim(u.user) regexp '^[a-zA-Z0-9._+\-]*@[a-zA-Z0-9._+\-]*\.[a-zA-Z0-9._+\-]*$' then 1
            else 0
            end as valid_email_flag
        ,u.*
from  rec_accounts.request_log u
where
    case
        when trim(u.user) regexp '^[a-zA-Z0-9._+\-]*@[a-zA-Z0-9._+\-]*\.[a-zA-Z0-9._+\-]*$' then 1
        else 0
        end = 0
    and u.user not in('NO USER', 'transactly-system')
;


-- create a table to store the bad entries
create table if not exists working.request_log_junk_user_entries(  -- source
    id int
    ,request_method varchar(50)
    ,created datetime
    ,status varchar(50)
    ,request_url varchar(500)
    ,user varchar(255)
    ,request_type varchar(50)
    ,update_date datetime
)
;



-- populate the new table with the bad entries
start transaction;
insert into working.request_log_junk_user_entries
select
    id
    ,request_method
    ,created
    ,status
    ,request_url
    ,user
    ,request_type
    ,current_timestamp()
from rec_accounts.request_log u
where
    not trim(u.user) regexp '^[a-zA-Z0-9._+\-]*@[a-zA-Z0-9._+\-]*\.[a-zA-Z0-9._+\-]*$'
    and u.user not in('NO USER', 'transactly-system')
;
commit;




-- check the new entries
select count(1) from working.request_log_junk_user_entries;
select count(1) from rec_accounts.request_log;  -- 11086982 vs 11077027 after delete


-- delete the bad entries from request_log
start transaction;
delete
from  rec_accounts.request_log u
where
    case
        when trim(u.user) regexp '^[a-zA-Z0-9._+\-]*@[a-zA-Z0-9._+\-]*\.[a-zA-Z0-9._+\-]*$' then 1
        else 0
        end = 0
    and u.user not in('NO USER', 'transactly-system')
;
commit;
