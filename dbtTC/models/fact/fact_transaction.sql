with
    src_tc_transaction as(
        select *
        from {{ ref('src_tc_transaction') }}
    )

    ,src_tc_order as(
        select *
        from {{ ref('src_tc_order') }}
    )

    ,dim_user as(
        select *
        from {{ ref('dim_user') }}
    )

    ,dim_transaction as(
        select *
        from {{ ref('dim_transaction') }}
    )

    ,diy as(
        select
            t.transaction_id
            ,t.created_by_id as agent_id
        from src_tc_transaction t
        where
            t.status_id not in (5, 6, 7)
            and t.transaction_id not in(
                select transaction_id
                from src_tc_order
                where transaction_id is not null
            )
    )

    ,cancelled as(
        select
            t.transaction_id
            ,t.created_by_id as agent_id
        from src_tc_transaction t
        where
            t.status_id in (5, 6, 7)
            and t.transaction_id not in(
                select transaction_id
                from src_tc_order
                where transaction_id is not null
            )
    )

    select
        nvl(user.user_pk, (select user_pk from dim_user where user_id = 0)) as user_pk
        ,transaction.transaction_pk
        ,case when trans.status_id = 3 then 1 else 0 end as closed_flag
        ,case when trans.status_id in (1, 2, 4) then 1 else 0 end as active_flag
        ,case when trans.side_id = 1 then 1 else 0 end as buy_flag
        ,case when trans.side_id <> 1 then 1 else 0 end as sell_flag
        ,case when diy.transaction_id is not null then 1 else 0 end as diy_flag
        ,case when c.transaction_id is not null then 1 else 0 end as cancelled_flag
        ,trans.created_date as created_date
    from
        src_tc_transaction trans
        left join dim_user user on trans.created_by_id = user.user_id
        join dim_transaction transaction on trans.transaction_id = transaction.transaction_id
        left join diy
            on trans.transaction_id = diy.transaction_id
            and trans.created_by_id = diy.agent_id
        left join cancelled c
            on trans.transaction_id = c.transaction_id
            and trans.created_by_id = c.agent_id