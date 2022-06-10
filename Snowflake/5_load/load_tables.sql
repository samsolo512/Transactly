-- load tables

/*
use prod.dimensional;
use stage.dimensional;
use dev.dimensional;
 */


-- dev.dimensional -> stage.dimensional
create or replace table stage.dimensional.dim_agent as select * from dev.dimensional.dim_agent;
create or replace table stage.dimensional.dim_brokerage as select * from dev.dimensional.dim_brokerage;
create or replace table stage.dimensional.dim_transaction as select * from dev.dimensional.dim_transaction;
create or replace table stage.dimensional.dim_line_item as select * from dev.dimensional.dim_line_item;
create or replace table stage.dimensional.dim_listing as select * from dev.dimensional.dim_listing;
create or replace table stage.dimensional.fact_listing as select * from dev.dimensional.fact_listing;
create or replace table stage.dimensional.fact_tc_diy as select * from dev.dimensional.fact_tc_diy;
create or replace table stage.dimensional.fact_tc_line_item as select * from dev.dimensional.fact_tc_line_item;

-- dev.dimensional -> prod.dimensional
create or replace table prod.dimensional.dim_agent as select * from dev.dimensional.dim_agent;
create or replace table prod.dimensional.dim_brokerage as select * from dev.dimensional.dim_brokerage;
create or replace table prod.dimensional.dim_transaction as select * from dev.dimensional.dim_transaction;
create or replace table prod.dimensional.dim_line_item as select * from dev.dimensional.dim_line_item;
create or replace table prod.dimensional.dim_listing as select * from dev.dimensional.dim_listing;
create or replace table prod.dimensional.fact_listing as select * from dev.dimensional.fact_listing;
create or replace table prod.dimensional.fact_tc_diy as select * from dev.dimensional.fact_tc_diy;
create or replace table prod.dimensional.fact_tc_line_item as select * from dev.dimensional.fact_tc_line_item;

-- dev.dimensional -> dev.load
create or replace table dev.load.dim_agent as select * from dev.dimensional.dim_agent;
create or replace table dev.load.dim_brokerage as select * from dev.dimensional.dim_brokerage;
create or replace table dev.load.dim_transaction as select * from dev.dimensional.dim_transaction;
create or replace table dev.load.dim_line_item as select * from dev.dimensional.dim_line_item;
create or replace table dev.load.dim_listing as select * from dev.dimensional.dim_listing;
create or replace table dev.load.fact_listing as select * from dev.dimensional.fact_listing;
create or replace table dev.load.fact_tc_diy as select * from dev.dimensional.fact_tc_diy;
create or replace table dev.load.fact_tc_line_item as select * from dev.dimensional.fact_tc_line_item;

-- stage.dimensional -> stage.load
create or replace table stage.load.dim_agent as select * from stage.dimensional.dim_agent;
create or replace table stage.load.dim_brokerage as select * from stage.dimensional.dim_brokerage;
create or replace table stage.load.dim_transaction as select * from stage.dimensional.dim_transaction;
create or replace table stage.load.dim_line_item as select * from stage.dimensional.dim_line_item;
create or replace table stage.load.dim_listing as select * from stage.dimensional.dim_listing;
create or replace table stage.load.fact_listing as select * from stage.dimensional.fact_listing;
create or replace table stage.load.fact_tc_diy as select * from stage.dimensional.fact_tc_diy;
create or replace table stage.load.fact_tc_line_item as select * from stage.dimensional.fact_tc_line_item;

-- prod.dimensional -> prod.load
create or replace table prod.load.dim_agent as select * from prod.dimensional.dim_agent;
create or replace table prod.load.dim_brokerage as select * from prod.dimensional.dim_brokerage;
create or replace table prod.load.dim_transaction as select * from prod.dimensional.dim_transaction;
create or replace table prod.load.dim_line_item as select * from prod.dimensional.dim_line_item;
create or replace table prod.load.dim_listing as select * from prod.dimensional.dim_listing;
create or replace table prod.load.fact_listing as select * from prod.dimensional.fact_listing;
create or replace table prod.load.fact_tc_diy as select * from prod.dimensional.fact_tc_diy;
create or replace table prod.load.fact_tc_line_item as select * from prod.dimensional.fact_tc_line_item;



-- dims
create or replace table load.dim_contract as select * from dimensional.dim_contract;
create or replace table load.dim_date as select * from dimensional.dim_date;
create or replace table load.dim_line_item as select * from dimensional.dim_line_item;
create or replace table load.dim_task as select * from dimensional.dim_task;
create or replace table load.dim_transaction_order as select * from dimensional.dim_transaction_order;
create or replace table load.dim_user as select * from dimensional.dim_user;

-- facts
create or replace table load.fact_contract as select * from dimensional.fact_contract;
create or replace table load.fact_order_line_item as select * from dimensional.fact_order_line_item;
create or replace table load.fact_user_month as select * from dimensional.fact_user_month;