with
    src_tc_user as(
        select *
        from {{ ref('src_tc_user') }}
    )

    ,src_tc_line_item as(
        select *
        from {{ ref('src_tc_line_item') }}
    )

    ,src_tc_order as(
        select *
        from {{ ref('src_tc_order') }}
    )

    ,src_tc_transaction as(
        select *
        from {{ ref('src_tc_transaction') }}
    )

    ,src_tc_user_subscription as(
        select *
        from {{ ref('src_tc_user_subscription') }}
    )

    ,last_order_placed as (
        select
            l.user_id
            ,max(l.created_date) as last_order_placed
        from
            src_tc_user u
            join src_tc_line_item l on l.user_id = u.user_id
        where
            l.user_id = u.user_id
            and l.description in ('Listing Coordination Fee', 'Transaction Coordination Fee')
            and l.status not in ('withdrawn', 'cancelled')
        group by l.user_id
    )

    ,first_order_placed as (
        select
            l.user_id
            ,min(l.created_date) as first_order_placed
        from
            src_tc_user u
            join src_tc_line_item l on l.user_id = u.user_id
        where
            l.user_id = u.user_id
            and l.description in ('Listing Coordination Fee', 'Transaction Coordination Fee')
            and l.status not in ('withdrawn', 'cancelled')
        group by l.user_id
    )

    ,first_order_closed as (
        select
            l.user_id
            ,min(t.closed_date) as first_order_closed
        from
            src_tc_user u
            join src_tc_line_item l on l.user_id = u.user_id
            join src_tc_order o on l.order_id = o.order_id
            join src_tc_transaction t on o.transaction_id = t.transaction_id
        where
            l.user_id = u.user_id
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
                src_tc_user u
                join src_tc_line_item l on l.user_id = u.user_id
            where
                l.due_date is not null
                and l.description in ('Listing Coordination Fee', 'Transaction Coordination Fee')
            )
        where row_num = 5
    )

    ,fifth_order_closed as(
        select * from(
            select
                l.user_id
                ,t.closed_date
                ,row_number() over (partition by l.user_id order by t.closed_date) as row_num
            from
                src_tc_user u
                join src_tc_line_item l on l.user_id = u.user_id
                join src_tc_order o on l.order_id = o.order_id
                join src_tc_transaction t on o.transaction_id = t.transaction_id
            where
                t.closed_date is not null
                and l.description in ('Listing Coordination Fee', 'Transaction Coordination Fee')
            )
        where row_num = 5
    )

    ,client as(
        select u.user_id
        from
            src_tc_user u
            join src_tc_line_item li on li.user_id = u.user_id
        where
            u.is_tc_client = 1
            and li.status not in ('withdrawn', 'cancelled')
            and li.due_date is not null
            and lower(li.description) like ('%coordination fee')

        -- users without orders
        union
        select u.user_id
        from
            src_tc_user u
            left join src_tc_order o on u.user_id = o.agent_id
        where
            u.is_tc_client = 1
            and o.agent_id is null
    )

select
    working.seq_dim_user.nextval as user_pk
    ,user_id
    ,first_name
    ,last_name
    ,fullname
    ,email
    ,brokerage
    ,subscription_level
    ,pays_at_title
    ,tc_client_flag
    ,max(last_order_placed) as last_order_placed
    ,max(last_order_due) as last_order_due
    ,tier_3
    ,max(tier_2) as tier_2
    ,max(tier_1) as tier_1
    ,max(first_order_placed) as first_order_placed
    ,max(first_order_closed) as first_order_closed
    ,max(fifth_order_closed) as fifth_order_closed
from(
    select
        u.user_id
        ,u.first_name
        ,u.last_name
        ,u.fullname
        ,u.email
        ,u.brokerage
        ,sub.subscription_level
        ,case u.pays_at_title
            when 'TRUE' then 'yes'
            when 'FALSE' then 'no'
            else null
            end as pays_at_title
        ,case when c.user_id is not null then 1 else 0 end as tc_client_flag
        ,fp.first_order_placed as tier_3
--         ,u.created_date as tier_3
        ,min(li.due_date) as tier_2
        ,fifth.due_date as tier_1
        ,loc.last_order_placed
        ,max(li.due_date) as last_order_due
        ,fp.first_order_placed
        ,fc.first_order_closed
        ,fifth_c.closed_date as fifth_order_closed
    from
        src_tc_user u
        left join client c on u.user_id = c.user_id
        left join src_tc_line_item li on li.user_id = u.user_id
        left join last_order_placed loc on u.user_id = loc.user_id
        left join fifth_order fifth on u.user_id = fifth.user_id
        left join fifth_order_closed fifth_c on u.user_id = fifth_c.user_id
        left join first_order_placed fp on u.user_id = fp.user_id
        left join first_order_closed fc on u.user_id = fc.user_id
        left join src_tc_user_subscription sub on u.user_id = sub.user_id
    group by u.user_id, u.first_name, u.last_name, u.fullname, u.email, u.brokerage, pays_at_title, tc_client_flag, tier_3, loc.last_order_placed, fp.first_order_placed, fc.first_order_closed, fifth_c.closed_date, fifth.due_date, sub.subscription_level
)
group by user_pk, user_id, first_name, last_name, fullname, email, brokerage, pays_at_title, tc_client_flag, tier_3, subscription_level

union select 0, 0, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null
