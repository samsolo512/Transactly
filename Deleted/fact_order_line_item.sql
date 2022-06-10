-- fact_order_line_item (GCP)
insert into `data-sandbox-343520`.load.fact_order_line_item
SELECT
    a.id as line_item_id  -- unique id
    ,b.id as order_id
    ,a.user_id as client_id
    -- ,c.id as transaction_id
    ,cast(b.created as date) as created_date
    ,cast(c.closed_date as date) as closed_date
    ,cast(a.agent_pays as bignumeric) as agent_pays
    ,cast(c.price as bignumeric) as price
    ,current_datetime('America/Mexico_City') as load_datetime
    ,current_datetime('America/Mexico_City') as update_datetime
FROM 
    business-analytics-337515.transactly_app_production_rec_accounts.line_item a
    left join business-analytics-337515.transactly_app_production_rec_accounts.tc_order b on a.order_id = b.id
    left join business-analytics-337515.transactly_app_production_rec_accounts.transaction c on b.transaction_id = c.id
where 
    b.type in('listing_transaction', 'transaction')
    -- and a.created between '2022-03-01' and '2022-03-11'
    -- and trim(lower(b.status)) <> 'withdrawn'  -- for received/placed orders
    -- and trim(lower(b.status)) not in ('withdrawn', 'cancelled', 'in progress')  -- for closed orders
-- limit 10
;