-- fact_transaction

/*
use prod.dimensional;
use stage.dimensional;
use dev.dimensional;
 */

merge into fact_transaction as target
using (

    select
        -- grain
        dto.transaction_order_pk

        ,current_timestamp() as load_datetime
        ,current_timestamp() as update_datetime
    from
        fivetran.transactly_app_production_rec_accounts.transaction t
        left join fivetran.transactly_app_production_rec_accounts.tc_order ord
            on t.id = ord.transaction_id
            and ord._fivetran_deleted = 'FALSE'
        join dim_transaction_order dto on t.id = dto.transaction_id
    where
        t._fivetran_deleted = 'FALSE'

) source
    on target.transaction_order_pk = source.transaction_order_pk

-- when matched
--     and(
--         ifnull(target.title_agent_flag, -1) <> ifnull(source.title_agent_flag, -1)
--     )
--     then update set
--         target.title_agent_flag = source.title_agent_flag
--         ,target.update_datetime = current_timestamp()

when not matched then
    insert(transaction_order_pk, load_datetime, update_datetime)
    values(source.transaction_order_pk, current_timestamp(), current_timestamp())
;

