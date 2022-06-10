-- MLS Orders Aggregation:
SELECT
    count(distinct lst.ID),
    lst."LISTAGENT_ID",
    lst."LISTOFFICE_ID",
    lst."STANDARDSTATUS"
FROM listings_current as lst
WHERE
    lst."MODIFICATIONTIMESTAMP" = (
        SELECT MAX(lst2."MODIFICATIONTIMESTAMP")
        FROM "FIVETRAN"."PRODUCTION_MLSFARM2_PUBLIC"."LISTINGS" AS lst2
        WHERE lst2.ID = lst.ID
    )
    AND lst."LISTAGENT_ID" IS NOT NULL
    AND lst."PROPERTYTYPE"  IN ('residential','land','farm','attached dwelling')
group by
    lst."LISTAGENT_ID",
    lst."LISTOFFICE_ID",
    lst."STANDARDSTATUS"
;



-- Transactly Orders Aggregation:
select
    user.id
    ,user.first_name
    ,user.last_name
    ,user.brokerage
--     ,diy_trans.diy_cnt
    ,case
        when
            line_item.description in ('Listing Coordination Fee','Transaction Coordination Fee')
            and line_item.status not in ('cancelled','withdrawn')
        then 1
        end as nbr_placed
    ,case
        when
            line_item.description in ('Listing Coordination Fee','Transaction Coordination Fee')
            and line_item.status = 'closed'
        then 1
        end as nbr_closed
    ,case
        when
            line_item.description in ('Listing Coordination Fee')
            and line_item.status not in ('cancelled','withdrawn')
        then 1
        end as nbr_TCOrders

--     (
--         select count(*)
--         from fivetran.transactly_app_production_rec_accounts.line_item
--         where
--             line_item.user_id = user.id
--             and description in ('Listing Coordination Fee','Transaction Coordination Fee')
--             and status not in ('cancelled','withdrawn')
--     ) as nbr_placed,
--     (
--         select count(*)
--         from fivetran.transactly_app_production_rec_accounts.line_item
--         where
--             line_item.user_id = user.id
--             and description in ('Listing Coordination Fee','Transaction Coordination Fee')
--             and status = 'closed'
--     ) as nbr_closed,
--     (
--         select count(*)
--         from fivetran.transactly_app_production_rec_accounts.line_item
--         where
--             line_item.user_id = user.id
--             and description in ('Listing Coordination Fee')
--             and status not in ('cancelled','withdrawn')
--     ) as nbr_TCOrders


from
    fivetran.transactly_app_production_rec_accounts.user
--     left join (
--         select
--             u.id
--             ,count(distinct transaction.id) as diy_cnt
--         from
--             fivetran.transactly_app_production_rec_accounts.transaction transaction
--             join fivetran.transactly_app_production_rec_accounts.user u on transaction.created_by_id = u.id
--         where
--             transaction.id not in (
--                 select transaction_id
--                 from fivetran.transactly_app_production_rec_accounts.tc_order tc_order
--                 where transaction_id is not null
--             )
--         group by u.id
--     ) diy_trans on diy_trans.id = user.id
    join fivetran.transactly_app_production_rec_accounts.user_role user_role
        on user_role.user_id = user.id
        and user_role.role_id = 5
    left join fivetran.transactly_app_production_rec_accounts.line_item on line_item.user_id = user.id
where
    user.email not like '%@transactly.com'
    and user.email not like '%test%'
;




-- Transactly Revenue:
select
    u.id
    ,u.first_name
    ,u.last_name
    ,u.email
    ,(u.created) as AgentJoinedDate
    ,count(*) as order_count
    ,(min(tco.due_date)) as first_order
    ,(max(tco.due_date)) as last_order
    ,DateAdd(day, 365, u.created) as LastOrderforOSR
    ,sum(tco.office_pays) + sum(tco.agent_pays) as Revenue
    ,(
        select sum(cli.agent_pays)
        from line_item as cli
        where
            cli.description = 'Applied Credit'
            and cli.order_id = tco.order_id
    ) as Credit
    ,(
        select ast.price
        from user_agent_subscription_tier ast
        where
            ast.user_id = u.id
            and ast.end_date < current_date()
            and ast.agent_subscription_tier_id = 2
    ) as ProMembership
from
    user u
    join line_item tco on tco.user_id = u.id
where
    u.is_tc_client = 1
    and u.is_active = 1
    and tco.due_date is not null
    and tco.description in ('Listing Coordination Fee','Transaction Coordination Fee')
group by u.id, u.first_name, u.last_name, u.email, AgentJoinedDate, u.created, tco.order_id

UNION
select
    u.id
     ,u.first_name
     ,u.last_name
     ,u.email
     ,(u.created) as AgentJoinedDate
     ,0
     ,null
     ,null
     ,null
     ,0
     ,0
     ,ast.price as ProMembership
from
    user u
    join user_agent_subscription_tier ast on ast.user_id = u.id
where
    ast.agent_subscription_tier_id = 2
    and u.id not in (
        select distinct user_id
        from line_item
        where u.id = line_item.user_id
    )
group by u.id, u.first_name, u.last_name, u.email, AgentJoinedDate, ast.price
;