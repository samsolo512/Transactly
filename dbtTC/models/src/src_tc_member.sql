with src_tc_member as(
    select *
    from fivetran.transactly_app_production_rec_accounts.member
    where lower(_fivetran_deleted) = 'false'
)

select
    id as member_id
    ,transaction_id
from src_tc_member