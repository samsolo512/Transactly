with src_tc_line_item as(
    select *
    from fivetran.transactly_app_production_rec_accounts.line_item
    where lower(_fivetran_deleted) = 'false'
)

select
    l.description
    ,l.status
    ,l.user_id
    ,l.created
    ,l.due_date
    ,l.order_id
    ,l.id
    ,l.cancelled_date
    ,l.paid
    ,l.agent_pays
    ,l.office_pays
from src_tc_line_item l
