-- dimensional model

---------------------------------------------------------------------------------------------------------------
-- fact_listing
-- 1 row/listing

-- Agents with 5 closings in the last year
select
    l.source
    ,b.mls_id as brokerage_id
    ,b.mls_name as brokerage_name
    ,a.id as agent_id
    ,a.mls_fullname as agent_name
    ,a.MLS_email
    ,count(closed_count) as closed_count
    ,count(active_count) as active_count
from
    prod.load.fact_listing fact
    join prod.load.dim_brokerage b on fact.brokerage_pk = b.brokerage_pk
    join prod.load.dim_agent a on fact.agent_pk = a.agent_pk
    join prod.load.dim_listing l on fact.listing_pk = l.listing_pk
    join prod.load.dim_date dt on fact.date_pk = dt.date_pk
where
    mls_email is not null
    and dt.date_id >= '6/1/2021'
group by
    a.id, a.mls_fullname, b.mls_id, b.mls_name, a.MLS_email, a.mls_id, l.source
having
    count(closed_count) >= 5 or count(active_count) >= 5
order by
    closed_count desc
;


-- MLS aggregation by agent
select
    dt.year
    ,b.mls_id as brokerage_id
    ,b.mls_name as brokerage_name
    ,a.mls_id as agent_id
    ,a.mls_fullname as agent_name
    ,count(1)
from
    prod.load.fact_listing fact
    join prod.load.dim_brokerage b on fact.brokerage_pk = b.brokerage_pk
    join prod.load.dim_agent a on fact.agent_pk = a.agent_pk
    join prod.load.dim_listing l on fact.listing_pk = l.listing_pk
    join prod.load.dim_date dt on fact.date_pk = dt.date_pk  -- this is from the 'calculated_on field in MLS'
group by a.mls_id, a.mls_fullname, b.mls_id, b.mls_name, dt.year
order by count(1) desc
;


-- MLS aggregation by brokerage
select
    dt.year
    ,b.mls_name
    ,sum(fact.total_listings) as total_listings
    ,sum(fact.active_count) as active_count
    ,sum(fact.coming_soon_count) as coming_soon_count
    ,sum(fact.pending_count) as pending_count
    ,sum(fact.closed_count) as closed_count
    ,sum(fact.other_count) as other_count
from
    prod.load.fact_listing fact
    join prod.load.dim_brokerage b on fact.brokerage_pk = b.brokerage_pk
    join prod.load.dim_agent a on fact.agent_pk = a.agent_pk
    join prod.load.dim_listing l on fact.listing_pk = l.listing_pk
    join prod.load.dim_date dt on fact.date_pk = dt.date_pk  -- this is from the 'calculated_on field in MLS'
-- where lower(b.mls_name) like '%worth clark%'
group by dt.year, b.mls_name
order by total_listings desc
;


-- agent adoption rate
select
    b.mls_id as brokerage_id
    ,b.mls_name as brokerage_name
    ,count(distinct a.mls_id) as MLS_agent_count
    ,count(distinct a.tc_id) as TC_agent_count
    ,count(distinct a.tc_id) / count(distinct a.mls_id) as adoption_rate
from
    prod.load.fact_listing fact
    join prod.load.dim_brokerage b on fact.brokerage_pk = b.brokerage_pk
    join prod.load.dim_agent a on fact.agent_pk = a.agent_pk
    join prod.load.dim_listing l on fact.listing_pk = l.listing_pk
    join prod.load.dim_date dt on fact.date_pk = dt.date_pk  -- this is from the 'calculated_on field in MLS'
group by b.mls_id, b.mls_name, dt.year
having TC_agent_count > 0
order by tc_agent_count desc
;


---------------------------------------------------------------------------------------------------------------
-- fact_TC_diy
select
    dt.year
    ,agent.tc_fullname
    ,brokerage.tc_company_name as brokerage
    ,count(1) row_count
from
    prod.load.fact_TC_diy fact
    join prod.load.dim_transaction tran on fact.transaction_pk = tran.transaction_pk
    join prod.load.dim_agent agent on fact.agent_pk = agent.agent_pk
    join prod.load.dim_brokerage brokerage on fact.brokerage_pk = brokerage.brokerage_pk
    join prod.load.dim_date dt on fact.date_pk = dt.date_pk
group by dt.year, brokerage.tc_company_name, agent.tc_fullname
order by row_count desc
;



---------------------------------------------------------------------------------------------------------------
-- fact_TC_line_item
select
    dt.year
    -- uncomment out the following lines if you want to get specific by agent and brokerage
--     ,agent.tc_id as agent_id
--     ,agent.tc_fullname as agent_name
--     ,brokerage.tc_company_name as brokerage_name
    ,sum(office_pays) as office_pays
    ,sum(agent_pays) as agent_pays
    ,sum(revenue) as revenue
    ,sum(credit) as credit
    ,sum(fact.nbr_placed) as nbr_placed
    ,sum(fact.nbr_closed) as nbr_closed
    ,sum(fact.nbr_tcorders) as nbr_tcorders
from
    prod.load.fact_tc_line_item fact
    join prod.load.dim_agent agent on fact.agent_pk = agent.agent_pk
    join prod.load.dim_brokerage brokerage on fact.brokerage_pk = brokerage.brokerage_pk
    join prod.load.dim_line_item line on fact.line_item_pk = line.line_item_pk
    join prod.load.dim_date dt on fact.date_pk = dt.date_pk
group by dt.year//, agent.tc_id, agent.tc_fullname, brokerage.tc_company_name
order by revenue desc
;



---------------------------------------------------------------------------------------------------------------
-- fact_order
select
    *
from
    fact_order fact
    join dim_agent agent on fact.agent_pk = agent.agent_pk
    join dim_line_item line on fact.line_item_pk = line.line_item_pk
    join dim_date line_item_created_date on fact.line_item_created_date_pk = line_item_created_date.date_pk
    join dim_date line_item_due_date on fact.line_item_created_date_pk = line_item_due_date.date_pk
    join dim_date line_item_cancelled_date on fact.line_item_created_date_pk = line_item_cancelled_date.date_pk
;



---------------------------------------------------------------------------------------------------------------
-- fact_contract
select *
from
    fact_contract fact
    join dim_contract contract on fact.contract_pk = contract.contract_pk
    join dim_transaction tran on fact.transaction_pk = tran.transaction_pk
    left join dim_date cont_close on fact.contract_closing_date_pk = cont_close.date_pk
    left join dim_date off_close on fact.offer_closing_date_pk = off_close.date_pk
    left join dim_date accept_dt on fact.accepted_date_pk = accept_dt.date_pk
;



---------------------------------------------------------------------------------------------------------------
-- fact_order_line_item

select
    due_date.date_id
    ,sum(in_progress_flag) as in_progress_count
    ,sum(withdrawn_flag) as withdrawn_count
    ,sum(cancelled_flag) as cancelled_count
    ,avg(days_to_close) as avg_days_to_close
from
    fact_order_line_item fact
    join dim_transaction_order o on fact.transaction_order_pk = o.transaction_order_pk
    join dim_user u on fact.user_pk = u.user_pk
    join dim_line_item i on fact.line_item_pk = i.line_item_pk
    join dim_date cancelled_date on fact.line_item_cancelled_date_pk = cancelled_date.date_pk
    join dim_date due_date on fact.line_item_due_date_pk = due_date.date_pk
where
    cancelled_date.date_id > '1/1/2021'
group by due_date.date_id
order by due_date.date_id desc
;


select
    u.full_name
    ,to_varchar(o_created_date.date_id, 'yyyy-MM') as order_created_date
    ,count(distinct o.order_id)
//    ,avg(fact.order_transact_start_lag) avg_lag_time
from
    fact_order_line_item fact
    join dim_transaction_order o on fact.transaction_order_pk = o.transaction_order_pk
    join dim_user u on fact.user_pk = u.user_pk
    join dim_line_item i on fact.line_item_pk = i.line_item_pk
    join dim_date o_created_date on fact.order_created_date_pk = o_created_date.date_pk
//where
//    transaction_closed_date is not null
group by u.full_name, to_varchar(o_created_date.date_id, 'yyyy-MM')
;

-- select * from dimensional.dim_date;  -- desc table dimensional.dim_date;



---------------------------------------------------------------------------------------------------------------
-- transaction

select
    o.transaction_created_date
    ,count(1)
from
    fact_transaction fact
    join dim_transaction_order o on fact.transaction_order_pk = o.transaction_order_pk
group by o.transaction_created_date
order by 1 desc
;




---------------------------------------------------------------------------------------------------------------
-- fact_user_month
-- The # of New Orders a TC Takes on Per Month 
select
    u.user_id
    ,sum(order_count)
    ,avg(order_count) as avg_orders_per_month
from
    fact_user_month fact
    join dim_user u on fact.user_pk = u.user_pk
    join dim_date dt on fact.order_month_pk = dt.date_pk
group by u.user_id
order by u.user_id
;