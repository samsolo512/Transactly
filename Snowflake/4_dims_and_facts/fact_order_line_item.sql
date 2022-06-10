-- fact_order_line_item

/*
use prod.dimensional;
use stage.dimensional;
use dev.dimensional;
 */


merge into fact_order_line_item as target
using(
    
    select
        --grain
        ifnull(ordr.transaction_order_pk, (select transaction_order_pk from dim_transaction_order where transaction_id = 0)) as transaction_order_pk
        ,ifnull(line.line_item_pk, (select line_item_pk from dim_line_item where line_item_id = 0)) as line_item_pk

        --dims
        ,usr.user_pk
        ,create_date.date_pk as line_item_created_date_pk
        ,due_date.date_pk as line_item_due_date_pk
        ,cancel_date.date_pk as line_item_cancelled_date_pk
        ,case
            when
                line.description in ('Listing Coordination Fee','Transaction Coordination Fee')
                and line.status not in ('cancelled', 'withdrawn')
            then datediff(day, create_date.date_id, due_date.date_id)
            else null
            end as days_to_close
        ,cast(c.agent_pays as number) as agent_pays
        ,cast(a.price as number) as price
        ,datediff(d, b.created, a.created) as order_transact_start_lag
        ,case when line.status = 'in progress' then 1 else 0 end as in_progress_flag
        ,case when line.status = 'withdrawn' and cancel_date.date_pk is not null then 1 else 0 end as withdrawn_flag
        ,case when line.status = 'cancelled' and cancel_date.date_pk is not null then 1 else 0 end as cancelled_flag
        ,current_timestamp() as load_datetime
        ,current_timestamp() as update_datetime
    from 
        fivetran.transactly_app_production_rec_accounts.transaction a
        left join fivetran.transactly_app_production_rec_accounts.tc_order b
            on a.id = b.transaction_id
            and b._fivetran_deleted = 'FALSE'
        left join fivetran.transactly_app_production_rec_accounts.line_item c
            on b.id = c.order_id
            and c._fivetran_deleted = 'FALSE'
        left join dim_line_item line on c.id = line.line_item_id
        left join dim_transaction_order ordr on a.id = ordr.transaction_id
        left join dim_user usr on b.assigned_tc_id = usr.user_id
        left join dim_date create_date on cast(c.created as date) = create_date.date_id
        left join dim_date due_date on cast(c.due_date as date) = due_date.date_id
        left join dim_date cancel_date on cast(c.cancelled_date as date) = cancel_date.date_id
//    where 
//        b.type in('listing_transaction', 'transaction')
        -- and a.created between '2022-03-01' and '2022-03-11'
        -- and trim(lower(b.status)) <> 'withdrawn'  -- for received/placed orders
        -- and trim(lower(b.status)) not in ('withdrawn', 'cancelled', 'in progress')  -- for closed orders

) as source
    on target.transaction_order_pk = source.transaction_order_pk
    and target.line_item_pk = source.line_item_pk
    
when matched
    and(
        ifnull(target.user_pk, -1) <> ifnull(source.user_pk, -1)
        or ifnull(target.line_item_created_date_pk, -1) <> ifnull(source.line_item_created_date_pk, -1)
        or ifnull(target.line_item_due_date_pk, -1) <> ifnull(source.line_item_due_date_pk, -1)
        or ifnull(target.line_item_cancelled_date_pk, -1) <> ifnull(source.line_item_cancelled_date_pk,-1)
        or ifnull(target.days_to_close, -1) <> ifnull(source.days_to_close, -1)
        or ifnull(target.agent_pays, -1) <> ifnull(source.agent_pays, -1)
        or ifnull(target.price, -1) <> ifnull(source.price, -1)
        or ifnull(target.order_transact_start_lag, -1) <> ifnull(source.order_transact_start_lag, -1)
        or ifnull(target.in_progress_flag, -1) <> ifnull(source.in_progress_flag, -1)
        or ifnull(target.withdrawn_flag, -1) <> ifnull(source.withdrawn_flag, -1)
        or ifnull(target.cancelled_flag, -1) <> ifnull(source.cancelled_flag, -1)
    )
    then update set
        target.user_pk = source.user_pk
        ,target.line_item_created_date_pk = source.line_item_created_date_pk
        ,target.line_item_due_date_pk = source.line_item_due_date_pk
        ,target.line_item_cancelled_date_pk = source.line_item_cancelled_date_pk
        ,target.days_to_close = source.days_to_close
        ,target.agent_pays = source.agent_pays
        ,target.price = source.price
        ,target.order_transact_start_lag = source.order_transact_start_lag
        ,target.in_progress_flag = source.in_progress_flag
        ,target.withdrawn_flag = source.withdrawn_flag
        ,target.cancelled_flag = source.cancelled_flag
        ,target.update_datetime = current_timestamp()
        
when not matched then
    insert(transaction_order_pk, line_item_pk, user_pk, line_item_created_date_pk, line_item_due_date_pk, line_item_cancelled_date_pk, days_to_close, agent_pays, price,order_transact_start_lag, in_progress_flag, withdrawn_flag, cancelled_flag, load_datetime, update_datetime)
    values(source.transaction_order_pk, source.line_item_pk, source.user_pk, source.line_item_created_date_pk, source.line_item_due_date_pk, source.line_item_cancelled_date_pk, source.days_to_close, source.agent_pays, source.price, source.order_transact_start_lag, source.in_progress_flag, source.withdrawn_flag, source.cancelled_flag, current_timestamp(), current_timestamp())
;


/*

 select * from fact_order_line_item where days_to_close is not null;

 */
