-- agents
select
    user.id as id,
    user.email as email,
    user.first_name as first_name,
    user.last_name as last_name,
    user.brokerage as brokerage,
    user.join_date as join_date,
    user.last_online_date as last_online_date,
    user.first_login as first_login,
    user.is_active as is_active,
    user.is_tc_client as is_tc_client,
    user.autopay_date as autopay_date,
    ast.name as membership_type,
    uast.price as membership_price,
    uast.end_date as membership_end_date
from
    fivetran.transactly_app_production_rec_accounts.user user
    join fivetran.transactly_app_production_rec_accounts.user_role ur on user.id = ur.user_id
    left join fivetran.transactly_app_production_rec_accounts.user_agent_subscription_tier uast on uast.id = uast.user_id
    left join fivetran.transactly_app_production_rec_accounts.agent_subscription_tier ast on ast.id = uast.agent_subscription_tier_id
where
    ur.role_id in (4, 5)
;



-- clients
select
    u.id as user_id,
    o.id as office_id,
    o.name as office_name,
    u.first_name as first_name,
    u.last_name as last_name,
    u.email as email,
//    (
//        select max(l.created)
//        from fivetran.transactly_app_production_rec_accounts.line_item l
//        where
//            l.user_id = u.id
//            and l.description in ('Listing Coordination Fee', 'Transaction Coordination Fee')
//            and l.status not in ('withdrawn', 'cancelled')
//        group by l.user_id
//    ) as last_order_created,
    max(li.due_date) as last_order_due,
    count(0) as total_orders,
    u.created as tier_3,
    min(li.due_date) as tier_2
//    if(
//        count(0) > 4,
//        select max(cast(data.due_date as date)) as 5th_order
//        from (
//            select rec_accounts.line_item.due_date as due_date
//            from rec_accounts.line_item
//            where
//                rec_accounts.line_item.user_id = li.user_id
//                and rec_accounts.line_item.due_date is not null
//                and rec_accounts.line_item.description in ('Listing Coordination Fee', 'Transaction Coordination Fee')
//            order by rec_accounts.line_item.due_date
//            limit 5
//        ) data
//        ,null
//    ) as tier_1
//
from
    fivetran.transactly_app_production_rec_accounts.user u
    join fivetran.transactly_app_production_rec_accounts.line_item li on li.user_id = u.id
    left join fivetran.transactly_app_production_rec_accounts.office_user ou on ou.user_id = u.id
    left join fivetran.transactly_app_production_rec_accounts.office o on o.id = ou.office_id
where
    u.is_tc_client = 1
    and li.status not in ('withdrawn', 'cancelled')
    and li.due_date is not null
    and li.description in ('Listing Coordination Fee', 'Transaction Coordination Fee')
group by u.id, o.id, o.name, u.first_name, u.last_name, u.email, u.created

union all
select
    u.id as user_id,
    o2.id as office_id,
    o2.name as office_name,
    u.first_name as first_name,
    u.last_name as last_name,
    u.email as email,
//    null,
    null,
    0,
    u.created as tier_3,
    null
//    null
from
    fivetran.transactly_app_production_rec_accounts.user u
    left join fivetran.transactly_app_production_rec_accounts.office_user ou2 on u.id = ou2.user_id
    left join fivetran.transactly_app_production_rec_accounts.office o2 on o2.id = ou2.office_id
where
    u.is_tc_client = 1
    and u.id not in (
        select distinct o.agent_id
        from fivetran.transactly_app_production_rec_accounts.tc_order o
    )
order by user_id
;



-- agent_transactions
select
    trans.created_by_id as agent_id,
    agent_canceled_transactions.canceled_transactions as canceled_transactions,
    count(0) as total_transactions_created,
    diy_transactions.diy_transaction_cnt as diy_transaction_cnt,
    sum(case when trans.status_id = 3 then 1 else 0 end) as total_transactions_closed,
    sum(case when trans.status_id in (1, 2, 4) then 1 else 0 end) as total_transactions_active,
    sum(case when trans.side_id = 1 then 1 else 0 end) as total_buy_transactions,
    sum(case when trans.side_id <> 1 then 1 else 0 end) as total_sell_transactions,
    tm.total_transaction_members as total_transaction_members,
    max(trans.created) as last_transaction_created_date
from
    fivetran.transactly_app_production_rec_accounts.transaction trans

    left join (
        select
            created_by_id as agent_id,
            count(0) as diy_transaction_cnt
        from fivetran.transactly_app_production_rec_accounts.transaction
        where
            status_id not in (5, 6, 7)
            and transaction.id not in(
                select transaction_id
                from fivetran.transactly_app_production_rec_accounts.tc_order
                where transaction_id is not null
            )
        group by created_by_id
    ) diy_transactions on diy_transactions.agent_id = trans.created_by_id

    left join (
        select
            m.user_id as agent_id,
            count(0) as total_transaction_members
        from
            fivetran.transactly_app_production_rec_accounts.transaction t
            join fivetran.transactly_app_production_rec_accounts.member m on t.id = m.transaction_id
        where
            t.status_id not in (5, 6, 7)
            and t.id not in(
                select o.transaction_id
                from fivetran.transactly_app_production_rec_accounts.tc_order o
                where o.transaction_id is not null
            )
        group by m.user_id
    ) tm on tm.agent_id = trans.created_by_id

    left join (
        select
            t.created_by_id as agent_id,
            count(0) as canceled_transactions
        from fivetran.transactly_app_production_rec_accounts.transaction t
        where
            t.id not in(
                select o.transaction_id
                from fivetran.transactly_app_production_rec_accounts.tc_order o
                where o.transaction_id is not null
            )
            and t.status_id in (5, 6, 7)
        group by t.created_by_id
    ) agent_canceled_transactions on agent_canceled_transactions.agent_id = trans.created_by_id

where
    trans.status_id not in (5, 6, 7)
    and trans.id not in(
        select o.transaction_id
        from fivetran.transactly_app_production_rec_accounts.tc_order o
        where o.transaction_id is not null
    )
group by trans.created_by_id, tm.total_transaction_members, diy_transactions.diy_transaction_cnt, agent_canceled_transactions.canceled_transactions
order by trans.created_by_id
;



-- client connections
select
    o.agent_id as agent_id,
    utvoo.created as created,
    count(0) as nbr_leads,
    client_buy_transactions.client_buy_transaction_cnt as client_buy_transaction_cnt
from
    fivetran.transactly_app_production_rec_accounts.transaction_transactly_vendor_member_notified ttvmn
    join fivetran.transactly_app_production_rec_accounts.member m on m.id = ttvmn.member_id
    join fivetran.transactly_app_production_rec_accounts.transaction_transactly_vendor ttv on ttvmn.transaction_transactly_vendor_id = ttv.id
    join fivetran.transactly_app_production_rec_accounts.transactly_vendor tv on ttv.transactly_vendor_id = tv.id
    join fivetran.transactly_app_production_rec_accounts.transaction t on m.transaction_id = t.id
    join fivetran.transactly_app_production_rec_accounts.tc_order o
        on t.id = o.transaction_id
        and o.transaction_id is not null
    left join fivetran.transactly_app_production_rec_accounts.user_transactly_vendor_opt_out utvoo on utvoo.user_id = o.agent_id
    left join(
        select
            o.agent_id as agent_id,
            count(0) as client_buy_transaction_cnt
        from fivetran.transactly_app_production_rec_accounts.tc_order o
        where
            o.transaction_id is not null
            and o.side_id = 1
        group by o.agent_id
    ) client_buy_transactions on client_buy_transactions.agent_id = o.agent_id
where tv.vendor_type_id = 10
group by o.agent_id, utvoo.created, client_buy_transactions.client_buy_transaction_cnt
order by 1
;



-- client orders
select
    l.user_id as agent_id,
    sum(case when l.status not in ('canceled', 'withdrawn', 'cancelled') then 1 else 0 end) as placed_orders,
    sum(case when l.status in ('canceled', 'withdrawn', 'cancelled') then 1 else 0 end) as canceled_orders,
    sum(case when l.status in ('complete', 'closed', 'tc paid', 'agent paid') then 1 else 0 end) as closed_orders,
    sum(case when l.status not in ('complete', 'closed', 'tc paid', 'agent paid', 'canceled', 'withdrawn', 'cancelled') then 1 else 0 end) as active_orders,
    sum(
        case
            when
                l.description = 'Listing Coordination Fee'
                and l.status not in ('canceled', 'withdrawn', 'cancelled')
            then 1
            else 0
            end
    ) as lc_orders,
    sum(
        case
            when
                l.description in('Transaction Coordination Fee')
                and l.status not in ('canceled', 'withdrawn', 'cancelled')
            then 1
            else 0
            end
    ) as tc_orders,
    sum(
        case when
            l.paid = 0
            and l.status not in('canceled', 'withdrawn', 'cancelled')
        then 1
        else 0 end
    ) as orders_not_paid
//    max(
//        0 <> l.created
//        and l.status not in ('canceled', 'withdrawn','cancelled')
//    ) as last_order_created
from fivetran.transactly_app_production_rec_accounts.line_item l
where l.description in ('Listing Coordination Fee', 'Transaction Coordination Fee')
group by l.user_id
order by 1
;



-- client revenue
select
    l.user_id as agent_id,
    sum(case when l.description = 'Transaction Coordination Fee' then 1 else 0 end) as nbr_tc_orders,
    sum(case when l.description = 'Transaction Coordination Fee' then 1 else 0 end) * 350 as tc_retail_value,
    sum(case when l.description = 'Transaction Coordination Fee' then l.agent_pays + l.office_pays else 0 end) as tc_charged,
    sum(case when l.description = 'Transaction Coordination Fee' and l.due_date is not null then l.agent_pays + l.office_pays else 0 end) as tc_due,
    sum(case when l.description = 'Transaction Coordination Fee' and l.paid = 1 then l.agent_pays + l.office_pays else 0 end) as tc_paid,
    sum(case when l.description = 'Listing Coordination Fee' then 1 else 0 end) as nbr_lc_orders,
    sum(case when l.description = 'Listing Coordination Fee' then 1 else 0 end) * 125 as lc_retail_value,
    sum(case when l.description = 'Listing Coordination Fee' then l.agent_pays + l.office_pays else 0 end) as lc_charged,
    sum(case when l.description = 'Listing Coordination Fee' and l.due_date is not null then l.agent_pays + l.office_pays else 0 end ) as lc_due,
    sum(case when l.description = 'Listing Coordination Fee' and l.paid = 1 then l.agent_pays + l.office_pays else 0 end) as lc_paid,
    sum(case when l.description = 'Transaction Coordination Fee' then 1 else 0 end) * 350 + sum(case when l.description = 'Listing Coordination Fee' then 1 else 0 end) * 125 as retail_value,
    sum(case when l.description = 'Transaction Coordination Fee' then l.agent_pays + l.office_pays else 0 end + case when l.description = 'Listing Coordination Fee' then l.agent_pays + l.office_pays else 0 end) as agent_charged,
    sum(case when l.description = 'Transaction Coordination Fee' and l.due_date is not null then l.agent_pays + l.office_pays else 0 end) + sum(case when l.description = 'Listing Coordination Fee' and l.due_date is not null then l.agent_pays + l.office_pays else 0 end) as agent_due,
    sum(case when l.description = 'Transaction Coordination Fee' and l.paid = 1 then l.agent_pays + l.office_pays else 0 end) + sum(case when l.description = 'Listing Coordination Fee' and l.paid = 1 then l.agent_pays + l.office_pays else 0 end) as agent_paid,
    sum(case when l.description in ('Applied Credit', 'Applied Discount') then l.agent_pays else 0 end) as discounts_given
from fivetran.transactly_app_production_rec_accounts.line_item l
where
    l.status not in ('withdrawn', 'cancelled')
group by l.user_id
order by 1
;
