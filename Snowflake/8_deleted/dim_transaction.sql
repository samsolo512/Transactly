-- dim_transaction

create or replace table dim_transaction as

select
    working.seq_dim_transaction.nextval as transaction_pk
    ,id as transaction_id
    ,created_by_id as user_id
    ,created as created_date
from fivetran.transactly_app_production_rec_accounts.transaction
;

create or replace sequence working.seq_dim_transaction start=1 increment=1;
