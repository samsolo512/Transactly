-- fact_TC_diy

create or replace table fact_TC_diy as

select
    tran.transaction_pk
    ,ifnull(agent.agent_pk, 0) as agent_pk
    ,ifnull(brokerage.brokerage_pk, 0) as brokerage_pk
    ,dt.date_pk
from
    fivetran.transactly_app_production_rec_accounts.transaction transaction
    left join dim_transaction tran on transaction.id = tran.transaction_id
    left join fivetran.transactly_app_production_rec_accounts.user u on transaction.created_by_id = u.id
    left join dim_agent agent on transaction.created_by_id = agent.tc_id
    left join dim_brokerage brokerage on u.brokerage = brokerage.tc_company_name
    left join dim_date dt on cast(transaction.created as date) = dt.date_id
where
    transaction.id not in (
        select transaction_id
        from fivetran.transactly_app_production_rec_accounts.tc_order tc_order
        where transaction_id is not null
    )
;

