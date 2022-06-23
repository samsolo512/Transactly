with src_tc_user_role as(
    select *
    from fivetran.transactly_app_production_rec_accounts.user_role
    where lower(_fivetran_deleted) = 'false'
)

select
    ur.user_id
    ,ur.role_id
from src_tc_user_role ur

