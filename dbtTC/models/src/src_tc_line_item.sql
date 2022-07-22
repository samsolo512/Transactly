with src_tc_line_item as(
    select *
    from fivetran.transactly_app_production_rec_accounts.line_item
    where lower(_fivetran_deleted) = 'false'
)

select
    l.description
    ,l.status
    ,l.user_id
    ,cast(l.created as date) as created_date
    ,cast(l.due_date as date) as due_date
    ,l.order_id
    ,l.id
    ,cast(l.cancelled_date as date) as cancelled_date
    ,l.paid
    ,l.tc_paid
    ,l.agent_pays
    ,l.office_pays
    ,l._fivetran_synced as last_sync
from src_tc_line_item l
