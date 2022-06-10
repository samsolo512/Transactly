-- dim_user (GCP)
insert into `data-sandbox-343520`.load.dim_user
select
    a.id as user_id
    ,a.first_name
    ,a.last_name
    ,concat(a.first_name, ' ', a.last_name) as full_name
    ,a.email
    ,a.license_state
    ,a.brokerage
    ,current_datetime('America/Mexico_City') as load_datetime
    ,current_datetime('America/Mexico_City') as update_datetime
from business-analytics-337515.transactly_app_production_rec_accounts.user a
;