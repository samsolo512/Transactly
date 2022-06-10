-- fact_user_month

/*
use prod.dimensional;
use stage.dimensional;
use dev.dimensional;
 */

merge into fact_user_month as target
using(

    select
        --grain
//        ifnull(usr.user_pk, (select user_pk from dim_user where user_id = 0)) as user_pk
//        ifnull(o_create_date.date_pk, (select date_pk from dim_date where date_id = '1/1/1900')) as order_month_pk
  
        usr.user_pk
        ,o_create_date.date_pk as order_month_pk
  
        --dims
        ,count(distinct ordr.order_id) as order_count
        ,sum(cast(c.agent_pays as number)) as agent_pays_sum
        ,sum(cast(a.price as number)) as price_sum
        ,current_timestamp() as load_datetime
        ,current_timestamp() as update_datetime
    from 
        fivetran.transactly_app_production_rec_accounts.transaction a
        left join fivetran.transactly_app_production_rec_accounts.tc_order b on a.id = b.transaction_id
        left join fivetran.transactly_app_production_rec_accounts.line_item c on b.id = c.order_id
        join dim_transaction_order ordr on b.id = ordr.order_id
        join dim_user usr on b.assigned_tc_id = usr.user_id
        join dim_date o_create_date on trunctimestamptomonth(cast(b.created as date)) = o_create_date.date_id
//    where
//        b.type in('listing_transaction', 'transaction')
    group by usr.user_pk, o_create_date.date_pk
  
) as source
    on target.user_pk = source.user_pk
    and target.order_month_pk = source.order_month_pk
    
when matched
    and(
        ifnull(target.order_count, -1) <> ifnull(source.order_count, -1)
        or ifnull(target.agent_pays_sum, -1) <> ifnull(source.agent_pays_sum, -1)
        or ifnull(target.price_sum, -1) <> ifnull(source.price_sum, -1)
    )
    then update set
        target.order_count = source.order_count
        ,target.agent_pays_sum = source.agent_pays_sum
        ,target.price_sum = source.price_sum
        ,target.update_datetime = current_timestamp()
        
when not matched then
    insert(user_pk, order_month_pk, order_count, agent_pays_sum, price_sum, load_datetime, update_datetime)
    values(source.user_pk, source.order_month_pk, source.order_count, source.agent_pays_sum, source.price_sum, current_timestamp(), current_timestamp())
;