-- fact_order
-- 1 row/line item
-- this is a combination of the two original TC views:
-- client_orders
-- client_revenue

with
    src_tc_transaction as(
        select *
        from {{ ref('src_tc_transaction')}}
    )

    ,src_tc_order as(
        select *
        from {{ ref('src_tc_order')}}
    )

    ,dim_order as(
        select *
        from {{ ref('dim_order')}}
    )

    ,dim_date as(
        select *
        from {{ ref('dim_date')}}
    )

select
    -- grain
    ord.order_pk

    ,assigned_tc.user_pk as assigned_tc_pk

    -- dates
    ,closed_date.date_pk as closed_date_pk

    -- flags
    ,case when closed_date.date_id is not null then 1 else 0 end as closed_date_flag
    ,case when o.assigned_tc_id is not null then 1 else 0 end as assigned_tc_flag

    -- misc
    ,datediff(day, o.created_date, t.created_date) as order_transact_start_lag

from
    src_tc_transaction t
    join src_tc_order o on t.transaction_id = o.transaction_id
//    left join dim_agent agt on agt.tc_id = o.agent_id
    left join dim_order ord on o.order_id = ord.order_id
    left join dim_user assigned_tc on o.assigned_tc_id = assigned_tc.user_id
    left join dim_date closed_date on cast(t.closed_date as date) = closed_date.date_id
