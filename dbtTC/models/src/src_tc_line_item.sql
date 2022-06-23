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
from src_tc_line_item l
