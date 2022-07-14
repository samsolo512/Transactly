-- fact_diy
select
    u.id user_id
    ,transaction.id
from
    fivetran.transactly_app_production_rec_accounts.transaction transaction
    join fivetran.transactly_app_production_rec_accounts.user u on transaction.created_by_id = u.id
where
    transaction.id not in (
        select transaction_id
        from fivetran.transactly_app_production_rec_accounts.tc_order tc_order
        where transaction_id is not null
    )
;



-- fact_line_item
select
    user.id
    ,user.first_name
    ,user.last_name
    ,user.brokerage
    ,agent.tc_id
    ,agent.tc_fullname
    ,ofc.name
    ,brokerage.tc_company_name
    ,line.description
    ,line.status
--     ,diy_trans.diy_cnt
    ,case
        when
            line.description in ('Listing Coordination Fee', 'Transaction Coordination Fee')
            and line.status not in ('cancelled', 'withdrawn')
        then 1
        end as nbr_placed
    ,case
        when
            line.description in ('Listing Coordination Fee', 'Transaction Coordination Fee')
            and line.status = 'closed'
        then 1
        end as nbr_closed
    ,case
        when
            line.description in ('Listing Coordination Fee')
            and line.status not in ('cancelled', 'withdrawn')
        then 1
        end as nbr_TCOrders
from
    fivetran.transactly_app_production_rec_accounts.line_item line  -- select * from fivetran.transactly_app_production_rec_accounts.line_item where created between '4/1/2022' and '5/1/2022'
    -- user/agent
    left join fivetran.transactly_app_production_rec_accounts.user user  -- select * from fivetran.transactly_app_production_rec_accounts.user
        join fivetran.transactly_app_production_rec_accounts.user_role user_role
            on user_role.user_id = user.id
            and user_role.role_id = 5
        on line.user_id = user.id
    left join dim_agent agent on user.id = agent.tc_id
    -- office/brokerage
    left join FIVETRAN.TRANSACTLY_APP_PRODUCTION_REC_ACCOUNTS.OFFICE ofc on ofc.name = user.brokerage  -- select * from dim_brokerage where lower(tc_company_name) like '%spartan%'
    left join dim_brokerage brokerage on ofc.name = brokerage.tc_company_name
where
    user.email not like '%@transactly.com'
    and user.email not like '%test%'

    and line.created between '4/1/2022' and '5/1/2022'
    and tc_company_name is not null
;

