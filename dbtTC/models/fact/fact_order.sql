-- fact_order
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

select
    -- grain
    line.line_item_pk

    -- dims
    ,client.client_pk
    ,agt.agent_pk

    -- dates
    ,create_date.date_pk as created_date_pk
    ,due_date.date_pk as due_date_pk
    ,cancel_date.date_pk as cancelled_date_pk
    ,closed_date.date_pk as closed_date_pk

    -- flags
    ,case when closed_date.date_id is not null then 1 else 0 end as closed_date_flag
    ,case when b.assigned_tc_id is not null then 1 else 0 end as assigned_tc_flag
    ,case when create_date.date_id is not null then 1 else 0 end as first_order_placed_flag

    -- misc
    ,datediff(day, b.created, a.created_date) as order_transact_start_lag
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

from
    src_tc_transaction a
    join src_tc_order b on a.transaction_id = b.transaction_id
    join src_tc_line_item l on b.id = l.order_id
    join dim_line_item line on l.id = line.line_item_id
    left join dim_agent agt on agt.tc_id = b.agent_id
    left join dim_client client on l.user_id = client.user_id
    left join dim_date create_date on cast(l.created as date) = create_date.date_id
    left join dim_date due_date on cast(l.due_date as date) = due_date.date_id
    left join dim_date cancel_date on cast(l.cancelled_date as date) = cancel_date.date_id
    left join dim_date closed_date on cast(a.closed_date as date) = closed_date.date_id
where
    l.id is not null
