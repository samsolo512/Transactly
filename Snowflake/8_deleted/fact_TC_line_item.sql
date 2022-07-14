-- fact_TC_line_item

create or replace table fact_TC_line_item as

with combined as(
    select
        ifnull(agent.agent_pk, 0) as agent_pk
        ,ifnull(brokerage.brokerage_pk, 0) as brokerage_pk
        ,ifnull(item.line_item_pk, 0) as line_item_pk
        ,dt.date_pk

        -- transactly revenue
        ,0 as office_pays
        ,0 as agent_pays
        ,0 as revenue
        ,0 as credit
--         ,0 as proMembership

        -- orders aggregation
        ,case
            when
                line.description in ('Listing Coordination Fee', 'Transaction Coordination Fee')
                and line.status not in ('cancelled', 'withdrawn')
            then 1
            else 0
            end as nbr_placed
        ,case
            when
                line.description in ('Listing Coordination Fee', 'Transaction Coordination Fee')
                and line.status = 'closed'
            then 1
            else 0
            end as nbr_closed
        ,case
            when
                line.description in ('Listing Coordination Fee')
                and line.status not in ('cancelled', 'withdrawn')
            then 1
            else 0
            end as nbr_TCOrders

    from
        fivetran.transactly_app_production_rec_accounts.line_item line
        left join dim_line_item item on line.id = item.line_item_id

        -- user/agent
        left join fivetran.transactly_app_production_rec_accounts.user user
            join fivetran.transactly_app_production_rec_accounts.user_role user_role
                on user_role.user_id = user.id
                and user_role.role_id = 5
            on line.user_id = user.id
        left join dim_agent agent on user.id = agent.tc_id

        -- office/brokerage
        left join FIVETRAN.TRANSACTLY_APP_PRODUCTION_REC_ACCOUNTS.OFFICE ofc on trim(lower(ofc.name)) = trim(lower(user.brokerage))
        left join dim_brokerage brokerage on ofc.name = brokerage.tc_company_name

        -- date
        left join dim_date dt on cast(line.created as date) = dt.date_id

    where
        user.email not like '%@transactly.com'
        and user.email not like '%test%'


    union all
    select
        ifnull(agent.agent_pk, 0) as agent_pk
        ,ifnull(brokerage.brokerage_pk, 0) as brokerage_pk
        ,ifnull(item.line_item_pk, 0) as line_item_pk
        ,dt.date_pk

        -- transactly revenue
        ,line.office_pays
        ,line.agent_pays
        ,(line.office_pays + line.agent_pays) as revenue
        ,case
            when line.description = 'Applied Credit'
            then line.agent_pays
            else 0
            end as credit
--         ,ifnull(tier.price, 0) as proMembership

        -- orders aggregation
        ,0 as nbr_placed
        ,0 as nbr_closed
        ,0 as nbr_TCOrders

    from
        fivetran.transactly_app_production_rec_accounts.line_item line
        left join dim_line_item item on line.id = item.line_item_id

        -- user
        join fivetran.transactly_app_production_rec_accounts.user user on line.user_id = user.id
        left join dim_agent agent on user.id = agent.tc_id
--         left join fivetran.transactly_app_production_rec_accounts.user_agent_subscription_tier tier
--             on tier.user_id = user.id
--             and tier.end_date < current_date()
--             and tier.agent_subscription_tier_id = 2

        -- office/brokerage
        left join FIVETRAN.TRANSACTLY_APP_PRODUCTION_REC_ACCOUNTS.OFFICE ofc on trim(lower(ofc.name)) = trim(lower(user.brokerage))
        left join dim_brokerage brokerage on ofc.name = brokerage.tc_company_name

        -- date
        left join dim_date dt on cast(line.created as date) = dt.date_id

    where
        line.description in ('Listing Coordination Fee', 'Transaction Coordination Fee')
        and line.due_date is not null
        and agent.tc_is_active = 1
        and agent.tc_is_tc_client = 1
)

select
    agent_pk
    ,brokerage_pk
    ,line_item_pk
    ,date_pk
    ,sum(office_pays) as office_pays
    ,sum(agent_pays) as agent_pays
    ,sum(revenue) as revenue
    ,sum(credit) as credit
--     ,sum(promembership) as promembership
    ,sum(nbr_placed) as nbr_placed
    ,sum(nbr_closed) as nbr_closed
    ,sum(nbr_tcorders) as nbr_tcorders
from combined
group by agent_pk, brokerage_pk, line_item_pk, date_pk
;

