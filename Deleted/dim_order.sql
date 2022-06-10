-- dim_order (GCP)
insert into `data-sandbox-343520`.load.dim_order
select
    a.id as order_id
    ,a.type as order_type
    ,a.status
    ,a.state
    ,current_datetime('America/Mexico_City') as load_datetime
    ,current_datetime('America/Mexico_City') as update_datetime
from business-analytics-337515.transactly_app_production_rec_accounts.tc_order a
-- limit 10
;