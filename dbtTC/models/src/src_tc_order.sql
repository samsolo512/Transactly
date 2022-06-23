with src_tc_order as(
    select *
    from fivetran.transactly_app_production_rec_accounts.tc_order
    where lower(_fivetran_deleted) = 'false'
)

select
    o.id
    ,o.transaction_id
from src_tc_order o
