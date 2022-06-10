-- vw_order_line_item
select
    fact.line_item_id
    ,fact.order_id
    ,fact.client_id
    ,fact.created_date
    ,fact.closed_date
    ,fact.agent_pays
    ,fact.price
    ,o.order_type
    ,o.order_status
    ,o.state as order_state
    ,c.first_name
    ,c.last_name
    ,c.license_state
    ,c.brokerage
from
    dimensional.fact_order_line_item fact
    join dimensional.dim_order o on fact.order_id = o.order_id
    join dimensional.dim_client c on fact.client_id = c.client_id
where
    fact.closed_date is null
;