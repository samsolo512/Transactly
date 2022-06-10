------------------------------------------------------------------------------
-- orders

-- C11 transactions added
select count(*)
from transaction
where created between '2022-01-01' and '2022-03-22'
;


-- C12 orders placed
-- see current CEO dashboard


-- C13 orders in process
SELECT count(*)
from line_item
where status = 'in progress'
;


-- C14 orders withdrawn
SELECT count(*)
from line_item
where
    cancelled_date between '2021-12-01' and '2022-01-01'
    and status = 'withdrawn'
;


-- C15 orders cancelled
SELECT count(*)
from line_item
where
    cancelled_date between '2021-12-01' and '2022-01-01'
    and status = 'cancelled'
;


-- C16 orders closed


-- C17 orders placed
-- see current CEO dashboard


-- C18 # Vendor Connections Made
-- see Salesforce


-- C19 New Brokerage Memberships
-- get access to another Google Sheet


-- C20 New Pro Agent/Team Memberships
select count(*)
from user_agent_subscription_tier
where
    user_agent_subscription_tier.start_date between '2021-06-01' and '2022-02-03'
    and user_agent_subscription_tier.agent_subscription_tier_id = 2;
;


-- C22 New Freemium Users
-- agents who specifically chose basic membership
select count(*)
from user_agent_subscription_tier uast
where
    uast.agent_subscription_tier_id = 1
    and uast.start_date between '2022-03-01' and '2022-03-15'
;


-- C24 Total Brokerage Accounts
select count(*)
from office
where
    disabled = 0
    and parent_office_id is null
;


-- C25 Total Active Monthly Users
select count(distinct user)
from request_log
where
    created between '2022-01-01' and '2022-02-01'
;


-- C26 Avg days to close coordination orders
select avg(days) as AvgDaysToClose
from(
    Select datediff(date(created),date(due_date)) as Days
    from line_item
    where
        due_date between '2022-03-01' and '2022-03-31'
        and description in ('Listing Coordination Fee','Transaction Coordination Fee')
        and status not in ('cancelled', 'withdrawn')
) data
;


-- C27 1099 Active TCs
select count(distinct assigned_tc_id)
from tc_order
where created between '2022-01-01' and '2022-02-01'
;