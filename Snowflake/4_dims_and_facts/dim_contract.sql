-- dim_contract

/*
use prod.dimensional;
use stage.dimensional;
use dev.dimensional;
 */


merge into dim_contract target
using(

    select
        c.id as contract_id
        ,p.name as party
        ,cast(c.closing_date as date) as contract_closing_date
        ,current_timestamp() as load_datetime
        ,current_timestamp() as update_datetime
    from
        fivetran.transactly_app_production_rec_accounts.contract c
        left join fivetran.transactly_app_production_rec_accounts.offer o
            on o.id = c.accepted_offer_id
            and o._fivetran_deleted = 'FALSE'
        left join fivetran.transactly_app_production_rec_accounts.offer_type ot
            on o.type_id = ot.id
            and ot._fivetran_deleted = 'FALSE'
        left join fivetran.transactly_app_production_rec_accounts.offer_status os
            on o.status_id = os.id
            and os._fivetran_deleted = 'FALSE'
        left join fivetran.transactly_app_production_rec_accounts.party p
            on o.party_id = p.id
            and p._fivetran_deleted = 'FALSE'
    where
        c._fivetran_deleted = 'FALSE'

    union select 0, null, null, null, null

) source
    on target.contract_id = source.contract_id

when matched
    and(
        ifnull(target.party, '1') <> ifnull(source.party, '1')
        or ifnull(target.contract_closing_date, '1/1/1900') <> ifnull(source.contract_closing_date, '1/1/1900')
    )
    then update set
        target.party = source.party
        ,target.contract_closing_date = source.contract_closing_date
        ,target.update_datetime = current_timestamp()

when not matched then
    insert(contract_pk, contract_id, party, contract_closing_date, load_datetime, update_datetime)
    values(working.seq_dim_contract.nextval, source.contract_id, source.party, source.contract_closing_date, current_timestamp(), current_timestamp())
;