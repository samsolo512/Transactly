--fact_order

create or replace table data-sandbox-343520.load.fact_order (
    address string
    ,state string
    ,description string
    ,agent_pays_amt numeric
    ,office_pays_amt numeric
    ,assigned_tc_id string
    ,assigned_tc_name string
    ,order_type string
    ,order_side string
    ,order_id string
    ,transaction_id string
    ,paid string
    ,pays_at_title string
    ,tc_paid string
    ,client_id string
    ,client_fullname string
    ,client_brokerage string
    ,tier_1_date date
    ,tier_2_date date
    ,tier_3_date date
    ,created_date date
    ,due_date date
    ,closed_date date
    ,cancelled_date date
    ,last_order_placed_date date
    ,last_order_due_date date
    ,first_order_placed_date date
    ,first_order_closed_date date
    ,fifth_order_closed_date date
)