create or replace table dimensional.dim_client as

with
    last_order_created as (
        select
            l.user_id
            ,max(l.created) as last_order_created
        from
            fivetran.transactly_app_production_rec_accounts.user u
            join fivetran.transactly_app_production_rec_accounts.line_item l on l.user_id = u.id
        where
            l.user_id = u.id
            and l.description in ('Listing Coordination Fee', 'Transaction Coordination Fee')
            and l.status not in ('withdrawn', 'cancelled')
        group by l.user_id
    )

    ,fifth_order as(
        select * from(
            select
                l.user_id
                ,l.due_date
                ,row_number() over (partition by l.user_id order by l.due_date) as row_num
            from
                fivetran.transactly_app_production_rec_accounts.user u
                join fivetran.transactly_app_production_rec_accounts.line_item l on l.user_id = u.id
            where
                l.due_date is not null
                and l.description in ('Listing Coordination Fee', 'Transaction Coordination Fee')
            )
        where row_num = 5
    )

select
    u.id as user_id,
    u.first_name as first_name,
    u.last_name as last_name,
    u.email as email,
    loc.last_order_created,
    max(li.due_date) as last_order_due,
    u.created as tier_3,
    min(li.due_date) as tier_2,
    fifth.due_date as tier_1,
    -- remove from this dim and rely on brokerage for these fields
    o.id as office_id,
    o.name as office_name,
    -- remove from this dim and add to fact
    count(0) as total_orders
from
    fivetran.transactly_app_production_rec_accounts.user u
    join fivetran.transactly_app_production_rec_accounts.line_item li on li.user_id = u.id
    left join fivetran.transactly_app_production_rec_accounts.office_user ou on ou.user_id = u.id
    left join fivetran.transactly_app_production_rec_accounts.office o on o.id = ou.office_id
    left join last_order_created loc on u.id = loc.user_id
    left join fifth_order fifth on u.id = fifth.user_id
where
    u.is_tc_client = 1
    and li.status not in ('withdrawn', 'cancelled')
    and li.due_date is not null
    and lower(li.description) like ('%coordination fee')
group by u.id, o.id, o.id, u.id, o.name, u.first_name, u.last_name, u.email, loc.last_order_created, u.created, fifth.due_date


-- users without orders
union all
select
    u.id as user_id,
    u.first_name as first_name,
    u.last_name as last_name,
    u.email as email,
    null as last_order_created,
    null as last_order_due,
    u.created as tier_3,
    null as tier_2,
    null as tier_1,
    -- remove from this dim and rely on brokerage for these fields
    o2.id as office_id,
    o2.name as office_name,
    -- remove from this dim and add to fact
    0 as total_orders
from
    fivetran.transactly_app_production_rec_accounts.user u
    left join fivetran.transactly_app_production_rec_accounts.office_user ou2 on u.id = ou2.user_id
    left join fivetran.transactly_app_production_rec_accounts.office o2 on o2.id = ou2.office_id
    left join fivetran.transactly_app_production_rec_accounts.tc_order o on u.id = o.agent_id
where
    u.is_tc_client = 1
    and o.id is null
order by user_id
;
