-- fact_line_item
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

    ,src_tc_line_item as(
        select *
        from {{ ref('src_tc_line_item')}}
    )

    ,dim_order as(
        select *
        from {{ ref('dim_order')}}
    )

    ,dim_line_item as(
        select *
        from {{ ref('dim_line_item')}}
    )

    ,dim_agent as(
        select *
        from {{ ref('dim_agent')}}
    )

    ,dim_date as(
        select *
        from {{ ref('dim_date')}}
    )

    ,dim_user as(
        select *
        from {{ ref('dim_user')}}
    )

select
    -- grain
    line.line_item_pk

    -- dims
    ,user.user_pk
    ,ord.order_pk
    ,assigned_tc.user_pk as assigned_tc_pk

    -- dates
    ,nvl(create_date.date_pk, (select date_pk from dim_date where date_id = '0')) as created_date_pk
    ,nvl(due_date.date_pk, (select date_pk from dim_date where date_id = '0')) as due_date_pk
    ,nvl(cancel_date.date_pk, (select date_pk from dim_date where date_id = '0')) as cancelled_date_pk
    ,nvl(closed_date.date_pk, (select date_pk from dim_date where date_id = '0')) as closed_date_pk

    -- flags
    ,case when closed_date.date_id is not null then 1 else 0 end as closed_date_flag
    ,case when o.assigned_tc_id is not null then 1 else 0 end as assigned_tc_flag
    ,case when create_date.date_id is not null then 1 else 0 end as first_order_placed_flag

    -- misc
    ,datediff(day, o.created_date, t.created_date) as order_transact_start_lag
    ,case when l.description in ('Listing Coordination Fee','Transaction Coordination Fee') and lower(l.status) not in ('canceled', 'withdrawn', 'cancelled') then datediff(day, create_date.date_id, due_date.date_id) else null end as days_to_close
    ,case when l.description in ('Listing Coordination Fee', 'Transaction Coordination Fee') and lower(line.status) = 'in progress' then 1 else 0 end as in_progress_orders

    -- orders
    ,case when l.description in ('Listing Coordination Fee', 'Transaction Coordination Fee') and lower(l.status) not in ('canceled', 'withdrawn', 'cancelled') then 1 else 0 end as placed_orders
    ,case when l.description in ('Listing Coordination Fee', 'Transaction Coordination Fee') and lower(l.status) in ('canceled', 'withdrawn', 'cancelled') then 1 else 0 end as canceled_orders
    ,case when l.description in ('Listing Coordination Fee', 'Transaction Coordination Fee') and lower(l.status) in ('complete', 'closed', 'tc paid', 'agent paid') then 1 else 0 end as closed_orders
    ,case when l.description in ('Listing Coordination Fee', 'Transaction Coordination Fee') and lower(l.status) not in ('complete', 'closed', 'tc paid', 'agent paid', 'canceled', 'withdrawn', 'cancelled') then 1 else 0 end as active_orders
    ,case when l.description in ('Listing Coordination Fee', 'Transaction Coordination Fee') and l.paid = 0 and lower(l.status) not in('canceled', 'withdrawn', 'cancelled') then 1 else 0 end as orders_not_paid
    ,case when l.description = 'Listing Coordination Fee' and lower(l.status) not in ('canceled', 'withdrawn', 'cancelled') then 1 else 0 end as lc_orders
    ,case when l.description = 'Transaction Coordination Fee' and lower(l.status) not in ('canceled', 'withdrawn', 'cancelled') then 1 else 0 end as tc_orders
//    max(case when 0 <> l.created and lower(l.status) not in ('canceled', 'withdrawn','cancelled') then ) as last_order_created

    -- revenue
    ,case when l.description = 'Listing Coordination Fee' and lower(l.status) not in ('canceled', 'withdrawn', 'cancelled') then 1 else 0 end as nbr_lc_orders
    ,case when l.description = 'Listing Coordination Fee' and lower(l.status) not in ('canceled', 'withdrawn', 'cancelled') then 1 else 0 end * 125 as lc_retail_value
    ,case when l.description = 'Listing Coordination Fee' and lower(l.status) not in ('canceled', 'withdrawn', 'cancelled') then l.agent_pays + l.office_pays else 0 end as lc_charged
    ,case when l.description = 'Listing Coordination Fee' and lower(l.status) not in ('canceled', 'withdrawn', 'cancelled') and l.due_date is not null then l.agent_pays + l.office_pays else 0 end as lc_due
    ,case when l.description = 'Listing Coordination Fee' and lower(l.status) not in ('canceled', 'withdrawn', 'cancelled') and l.paid = 1 then l.agent_pays + l.office_pays else 0 end as lc_paid
    ,case when l.description = 'Transaction Coordination Fee' and lower(l.status) not in ('canceled', 'withdrawn', 'cancelled') then 1 else 0 end as nbr_tc_orders
    ,case when l.description = 'Transaction Coordination Fee' and lower(l.status) not in ('canceled', 'withdrawn', 'cancelled') then 1 else 0 end * 350 as tc_retail_value
    ,case when l.description = 'Transaction Coordination Fee' and lower(l.status) not in ('canceled', 'withdrawn', 'cancelled') then l.agent_pays + l.office_pays else 0 end as tc_charged
    ,case when l.description = 'Transaction Coordination Fee' and lower(l.status) not in ('canceled', 'withdrawn', 'cancelled') and l.due_date is not null then l.agent_pays + l.office_pays else 0 end as tc_due
    ,case when l.description = 'Transaction Coordination Fee' and lower(l.status) not in ('canceled', 'withdrawn', 'cancelled') and l.paid = 1 then l.agent_pays + l.office_pays else 0 end as tc_paid
    ,case when l.description = 'Transaction Coordination Fee' and lower(l.status) not in ('canceled', 'withdrawn', 'cancelled') then 1 else 0 end * 350 + case when l.description = 'Listing Coordination Fee' then 1 else 0 end * 125 as retail_value
    ,case when l.description = 'Transaction Coordination Fee' and lower(l.status) not in ('canceled', 'withdrawn', 'cancelled') then l.agent_pays + l.office_pays else 0 end + case when l.description = 'Listing Coordination Fee' then l.agent_pays + l.office_pays else 0 end as agent_charged
    ,case when l.description = 'Transaction Coordination Fee' and lower(l.status) not in ('canceled', 'withdrawn', 'cancelled') and l.due_date is not null then l.agent_pays + l.office_pays else 0 end + case when l.description = 'Listing Coordination Fee' and l.due_date is not null then l.agent_pays + l.office_pays else 0 end as agent_due
    ,case when l.description = 'Transaction Coordination Fee' and lower(l.status) not in ('canceled', 'withdrawn', 'cancelled') and l.paid = 1 then l.agent_pays + l.office_pays else 0 end + case when l.description = 'Listing Coordination Fee' and l.paid = 1 then l.agent_pays + l.office_pays else 0 end as agent_paid
    ,case when l.description in ('Applied Credit', 'Applied Discount') and lower(l.status) not in ('canceled', 'withdrawn', 'cancelled') then l.agent_pays else 0 end as discounts_given

from  --37574
    src_tc_transaction t
    join src_tc_order o on t.transaction_id = o.transaction_id
    join src_tc_line_item l on o.order_id = l.order_id
    join dim_line_item line on l.id = line.line_item_id
    left join dim_user user on l.user_id = user.user_id
    left join dim_order ord on o.order_id = ord.order_id
    left join dim_user assigned_tc on o.assigned_tc_id = assigned_tc.user_id
    left join dim_date create_date on cast(l.created as date) = create_date.date_id
    left join dim_date due_date on cast(l.due_date as date) = due_date.date_id
    left join dim_date cancel_date on cast(l.cancelled_date as date) = cancel_date.date_id
    left join dim_date closed_date on cast(t.closed_date as date) = closed_date.date_id
where
    l.id is not null
