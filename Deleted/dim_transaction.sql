-- dim_transaction (GCP)
insert into `data-sandbox-343520`.load.dim_transaction
select
    id as transaction_id
    ,cast(closed_date as date) as closed_date
    ,cast(price as number) as price
    ,current_timestamp() as load_datetime
    ,current_timestamp() as update_datetime
from business-analytics-337515.transactly_app_production_rec_accounts.transaction
;