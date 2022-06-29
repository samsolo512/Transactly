with
    src_tc_transaction as(
        select *
        from {{ ref('src_tc_transaction') }}
    )

    ,src_tc_order as(
        select *
        from {{ ref('src_tc_order') }}
    )

    ,src_tc_user as(
        select *
        from {{ ref('src_tc_user') }}
    )

select
    t.transaction_id
    ,o.id as order_id
    ,usr.fullname as assigned_TC
    ,t_create.fullname as transaction_created_by
    ,cast(t.created_date as date) as transaction_created_date
    ,cast(t.closed_date as date) as transaction_closed_date
    ,o.status as order_status
    ,o.type as order_type
    ,o.created as order_created_date
from
    src_tc_transaction t
    left join src_tc_order o on t.transaction_id = o.transaction_id
    left join src_tc_user u on o.assigned_tc_id = u.id
    left join src_tc_user usr on u.id = u.google_user_id
    left join src_tc_user t_create on t.created_by_id = t_create.id
