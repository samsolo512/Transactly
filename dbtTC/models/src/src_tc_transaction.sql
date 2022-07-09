with src_tc_transaction as(
    select *
    from fivetran.transactly_app_production_rec_accounts.transaction
    where lower(_fivetran_deleted) = 'false'
)

select
    t.id as transaction_id
    ,t.created_by_id as user_id
    ,t.status_id
    ,t.type_id
    ,t.category_id
    ,t.side_id
    ,cast(t.created as date) as created_date
    ,cast(t.closed_date as date) as closed_date
    ,t.created_by_id
from src_tc_transaction t
