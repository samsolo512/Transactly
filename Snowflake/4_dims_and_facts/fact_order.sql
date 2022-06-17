-- fact_order

select
    -- grain
    agt.agent_pk
    ,line.line_item_pk

    -- dates
    ,create_date.date_pk as line_item_created_date_pk
    ,due_date.date_pk as line_item_due_date_pk
    ,cancel_date.date_pk as line_item_cancelled_date_pk

    -- misc
    ,datediff(day, b.created, a.created) as order_transact_start_lag
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
    fivetran.transactly_app_production_rec_accounts.transaction a
    left join fivetran.transactly_app_production_rec_accounts.tc_order b  -- select top 10 * from fivetran.transactly_app_production_rec_accounts.tc_order
        on a.id = b.transaction_id
        and b._fivetran_deleted = 'FALSE'
    left join fivetran.transactly_app_production_rec_accounts.line_item l  -- select top 10 * from fivetran.transactly_app_production_rec_accounts.line_item
        on b.id = l.order_id
        and l._fivetran_deleted = 'FALSE'
    left join dim_line_item line on l.id = line.line_item_id  -- select top 10 * from dim_line_item
    left join dim_agent agt on agt.tc_id = l.user_id
    left join dim_date create_date on cast(l.created as date) = create_date.date_id
    left join dim_date due_date on cast(l.due_date as date) = due_date.date_id
    left join dim_date cancel_date on cast(l.cancelled_date as date) = cancel_date.date_id
where
    l.id is not null
;
