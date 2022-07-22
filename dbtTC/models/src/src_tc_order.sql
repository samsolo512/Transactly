with src_tc_order as(
    select *
    from fivetran.transactly_app_production_rec_accounts.tc_order
    where lower(_fivetran_deleted) = 'false'
)

select
    o.id as order_id
    ,o.transaction_id
    ,o.agent_id
    ,cast(o.created as date) as created_date
    ,o.assigned_tc_id
    ,o.status as order_status
    ,o.type as order_type
    ,o.address
    ,o.state
    ,o.side_id as order_side_id
    ,o.order_data
    ,o.assigned_tc_office_id
    ,o._fivetran_synced last_sync
    ,o.agent_office_id
from src_tc_order o
