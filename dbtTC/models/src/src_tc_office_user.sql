with src_tc_office_user as(
    select *
    from fivetran.transactly_app_production_rec_accounts.office_user
    where lower(_fivetran_deleted) = 'false'
)

select
    o.id as office_user_id
    ,o.user_id
    ,o.office_id
from src_tc_office_user o
