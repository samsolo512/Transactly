with src_tc_transaction as(
    select *
    from {{ ref('src_tc_transaction') }}
)

select
    working.seq_dim_transaction.nextval as transaction_pk
    ,transaction_id
    ,user_id
    ,status_id
    ,type_id
    ,side_id
    ,category_id
from src_tc_transaction