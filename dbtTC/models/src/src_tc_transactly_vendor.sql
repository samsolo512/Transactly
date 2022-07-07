with src_tc_transactly_vendor as(
    select *
    from fivetran.transactly_app_production_rec_accounts.transactly_vendor
    where lower(_fivetran_deleted) = 'false'
)

select
    id as vendor_id
    ,vendor_type_id
from src_tc_transactly_vendor