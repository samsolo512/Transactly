with src_tc_transaction as(
    select *
    from fivetran.transactly_app_production_rec_accounts.transaction
    where lower(_fivetran_deleted) = 'false'
)

select
    t.id as transaction_id
    ,t.created_by_id as user_id
    ,t.created as created_date
from src_tc_transaction t
