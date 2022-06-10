-- fact_contract

/*
use prod.dimensional;
use stage.dimensional;
use dev.dimensional;
 */

merge into fact_contract as target
using (

    select
        -- grain
        tran.transaction_order_pk
        ,cont.contract_pk

        ,datediff(day, t.closed_date, c.closing_date) as days_tran_closed_before_contract
        ,current_timestamp() as load_datetime
        ,current_timestamp() as update_datetime
    from
        fivetran.transactly_app_production_rec_accounts.transaction t
        left join fivetran.transactly_app_production_rec_accounts.tc_order ord
        on t.id = ord.transaction_id
            and ord._fivetran_deleted = 'FALSE'
        left join fivetran.transactly_app_production_rec_accounts.contract c
        on t.id = c.transaction_id
            and c._fivetran_deleted = 'FALSE'
        join dim_transaction_order tran on t.id = tran.transaction_id
        join dim_contract cont on c.id = cont.contract_id
    where
        t._fivetran_deleted = 'FALSE'

) source
    on target.transaction_pk = source.transaction_order_pk
    and target.contract_pk = source.contract_pk

when matched
    and(
        ifnull(target.days_tran_closed_before_contract, -1111) <> ifnull(source.days_tran_closed_before_contract, -1111)
    )
    then update set
        target.days_tran_closed_before_contract = source.days_tran_closed_before_contract
        ,target.update_datetime = current_timestamp()

when not matched then
    insert(transaction_pk, contract_pk, days_tran_closed_before_contract, load_datetime, update_datetime)
    values(source.transaction_order_pk, source.contract_pk, source.days_tran_closed_before_contract, current_timestamp(), current_timestamp())
;