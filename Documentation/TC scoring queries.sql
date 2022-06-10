-- TC scoring queries
-- https://docs.google.com/document/d/1MuCCDIeDJ2cklAGjjCZqpgRMHANAN8hjRtkqA-uHDh8/edit

----------------------------------------------------------------------------------------------
-- Individual Queries
-- Days Between Order Being Placed and Transaction Being Created (on average)
-- (how long it takes a TC to put it into the system once they get info from agent, should be less than 24 hours)
select 
      data.assigned_tc_id
      ,avg(lag_time) as dboat_lag
from(
    select 
        tc_order.assigned_tc_id
        ,datediff (day, transaction.created, tc_order.created) as lag_time
    from 
        tc_order
        join transaction on transaction.id = tc_order.transaction_id
    where 
        tc_order.assigned_tc_id <> transaction.created_by_id
) data
group by data.assigned_tc_id
;



----------------------------------------------------------------------------------------------
-- Days Taken to Close Transaction in App After Specified Closing Date (on average)
-- (closing date on contract very important, legally/goal to close date on system on or before contract date)
select 
      assigned_tc_id
      ,avg(lag_time) as tcvvccd_lag
from(
      select 
            o.assigned_tc_id
            ,datediff(day, t.closed_date, c.closing_date) as lag_time
            ,t.closed_date
            ,c.closing_date
      from 
            tc_order o
            join transaction t on t.id = o.transaction_id
            join contract c on c.id = t.current_contract_id
      where t.closed_date is not null
) data
group by assigned_tc_id
;



----------------------------------------------------------------------------------------------
-- Days Between a Task Due Date and the Day it was Completed (on average)
-- (task record has both dates)
select 
      assigned_tc_id, avg (lag_time) as ttct_lag
from
      (select 
            tco.assigned_tc_id
            ,datediff (day, tk.completed_date, tk.due_date) as lag_time
      from 
            transaction tr
            join tc_order tco on tco.transaction_id = tr.id
            join task tk on tk.transaction_id = tr.id
      where 
            tk.assigned_to_id = tco.assigned_tc_id
            and tk.completed = 1
            and tco.assigned_tc_id = tk.completed_by_id
            and tk.due_date is not NULL
      ) data
group by assigned_tc_id
;



----------------------------------------------------------------------------------------------
-- Percentage of Transactions with a Title Agent Added
-- (related to transaction teams, use vendor table to find vendor type = 'title', there should be a title agent added to every transaction)
select
    tco.assigned_tc_id
    ,count(*) as transaction_title_agent_count
    ,trans_cnt.total_transaction_cnt
    ,(count(*)/trans_cnt.total_transaction_cnt)*100 as twta_percent
from
      tc_order tco
      join (
            select transaction_id, count(*) as title_agent_cnt
            from contact
            where role_id in (12,13)
            group by transaction_id

            UNION ALL
            select transaction_id, count(*) as title_agent_cnt
            from transaction_vendor
            where vendor_type_id = 6
            group by transaction_id
      ) tat on tat.transaction_id = tco.transaction_id
      join (
            select tco.assigned_tc_id, count(*) as total_transaction_cnt
            from tc_order tco
            group by assigned_tc_id
      ) trans_cnt on trans_cnt.assigned_tc_id = tco.assigned_tc_id
group by tco.assigned_tc_id, trans_cnt.total_transaction_cnt
;



----------------------------------------------------------------------------------------------
-- The # of New Orders a TC Takes on Per Month
-- (tc_order.created is the date we are interested in)
select
      assigned_tc_id, sum(new_orders), count(*), avg(new_orders) as nopm_total
from (
      select assigned_tc_id, month(created), year(created), count(*) as new_orders
      from tc_order
      group by assigned_tc_id, month(created), year(created)
) opm
group by assigned_tc_id


