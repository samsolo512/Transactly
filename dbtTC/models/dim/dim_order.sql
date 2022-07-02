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
    working.seq_dim_order.nextval as order_pk
    ,t.transaction_id
    ,o.order_id
    ,usr.fullname as assigned_TC
    ,t_create.fullname as created_by
    ,t.created_date
    ,t.closed_date
    ,o.order_status
    ,o.order_type
    ,o.address
    ,o.state
    ,case
        when o.order_side_id = 1 then 'buyer'
        when o.order_side_id = 2 then 'seller'
        else null
        end as order_side
from
    src_tc_transaction t
    left join src_tc_order o on t.transaction_id = o.transaction_id
    left join src_tc_user u on o.assigned_tc_id = u.user_id
    left join src_tc_user usr on u.user_id = u.google_user_id
    left join src_tc_user t_create on t.created_by_id = t_create.user_id
