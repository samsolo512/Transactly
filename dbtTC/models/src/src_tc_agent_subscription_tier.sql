with src_tc_agent_subscription_tier as(
    select *
    from fivetran.transactly_app_production_rec_accounts.agent_subscription_tier
    where lower(_fivetran_deleted) = 'false'
)

select
    u.id
from src_tc_agent_subscription_tier u
