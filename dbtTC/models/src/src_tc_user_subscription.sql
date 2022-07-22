with src_tc_user_subscription as(
    select *
    from fivetran.transactly_app_production_rec_accounts.user_subscription
    where lower(_fivetran_deleted) = 'false'
)

select
    u.user_id
    ,u.level as subscription_level
from src_tc_user_subscription u

