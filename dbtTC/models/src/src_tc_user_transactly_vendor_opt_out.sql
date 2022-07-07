with src_tc_user_transactly_vendor_opt_out as(
    select *
    from fivetran.transactly_app_production_rec_accounts.user_transactly_vendor_opt_out
    where lower(_fivetran_deleted) = 'false'
)

select
    user_id
    ,created as created_date
from src_tc_user_transactly_vendor_opt_out