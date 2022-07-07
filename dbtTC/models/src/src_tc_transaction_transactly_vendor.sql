with src_tc_transaction_transactly_vendor as(
    select *
    from fivetran.transactly_app_production_rec_accounts.transaction_transactly_vendor
    where lower(_fivetran_deleted) = 'false'
)

select
    id as transaction_transactly_vendor_id
    ,transactly_vendor_id
from src_tc_transaction_transactly_vendor