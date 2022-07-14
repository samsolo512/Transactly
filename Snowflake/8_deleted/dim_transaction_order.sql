-- dim_transaction_order

/*
use prod.dimensional;
use stage.dimensional;
use dev.dimensional;
*/


create or replace procedure working.dim_transaction_order_sp()
    returns string not null
    language javascript
	execute as caller
    as
    $$

    table_name = 'dim_transaction_order';

    //delete from target if record isn't in source
    var set_query = `

    merge into dimensional.dim_transaction_order as target
    using(

        select
            target.transaction_id
        from
            dimensional.dim_transaction_order target
            left join(
                select
                    t.id as transaction_id
                from
                    fivetran.transactly_app_production_rec_accounts.transaction t

                union select '0'

        ) source
            on target.transaction_id = source.transaction_id

        where
            source.transaction_id is null

    ) as source
        on target.transaction_id = source.transaction_id

    when matched then delete

    `;

    var query_statement = snowflake.createStatement( {sqlText: set_query} );
    var query_run = query_statement.execute();



    // update or insert into target
    var set_query = `

    merge into dim_transaction_order target
    using(

        select
            t.id as transaction_id
            ,o.id as order_id
            ,usr.full_name as assigned_TC
            ,t_create.full_name as transaction_created_by
            ,cast(t.created as date) as transaction_created_date
            ,cast(t.closed_date as date) as transaction_closed_date
            ,o.status as order_status
            ,o.type as order_type
            ,o.created as order_created_date
            ,current_timestamp() as load_datetime
            ,current_timestamp() as update_datetime
        from
            fivetran.transactly_app_production_rec_accounts.transaction t
            left join fivetran.transactly_app_production_rec_accounts.tc_order o on t.id = o.transaction_id
            left join fivetran.transactly_app_production_rec_accounts.user u on o.assigned_tc_id = u.id
            left join dim_user usr on u.id = u.google_user_id
            left join dim_user t_create on t.created_by_id = t_create.user_id

        union select 0, null, null, null, null, null, null, null, null, null, null

    ) as source
        on target.transaction_id = source.transaction_id

    when matched
        and(
            ifnull(target.order_id, -1) <> ifnull(source.order_id, -1)
            or ifnull(target.assigned_TC, '1') <> ifnull(source.assigned_TC, '1')
            or ifnull(target.transaction_created_by, '1') <> ifnull(source.transaction_created_by, '1')
            or ifnull(target.transaction_created_date, '1/1/1900') <> ifnull(source.transaction_created_date, '1/1/1900')
            or ifnull(target.transaction_closed_date, '1/1/1900') <> ifnull(source.transaction_closed_date, '1/1/1900')
    --         or ifnull(target.title_agent, '1') <> ifnull(source.title_agent, '1')
            or ifnull(target.order_status, '1') <> ifnull(source.order_status, '1')
            or ifnull(target.order_type, '1') <> ifnull(source.order_type, '1')
            or ifnull(target.order_created_date, '1/1/1900') <> ifnull(source.order_created_date, '1/1/1900')
    --         or ifnull(target.days_to_create_tran, -1) <> ifnull(source.days_to_create_tran, -1)
        )
        then update set
            target.order_id = source.order_id
            ,target.assigned_tc = source.assigned_tc
            ,target.transaction_created_by = source.transaction_created_by
            ,target.transaction_created_date = source.transaction_created_date
            ,target.transaction_closed_date = source.transaction_closed_date
    --         ,target.title_agent = source.order_id
            ,target.order_status = source.assigned_tc
            ,target.order_type = source.order_type
            ,target.order_created_date = source.order_created_date
    --         ,target.days_to_create_tran = source.days_to_create_tran
            ,target.update_datetime = current_timestamp()

    when not matched then
        insert(transaction_order_pk, transaction_id, order_id, assigned_TC, transaction_created_by, transaction_created_date, transaction_closed_date, order_status, order_type, order_created_date, load_datetime, update_datetime)
        values(working.seq_dim_transaction_order.nextval, source.transaction_id, source.order_id, source.assigned_TC, source.transaction_created_by, source.transaction_created_date, source.transaction_closed_date, source.order_status, source.order_type, source.order_created_date, current_timestamp(), current_timestamp())

   `;

    var query_statement = snowflake.createStatement( {sqlText: set_query} );
    var query_run = query_statement.execute();

    result = "Complete!";
    return result;

    $$
;


/*

truncate table dimensional.dim_transaction_order;
call working.dim_transaction_order_sp();
create or replace table load.dim_transaction_order as select * from dimensional.dim_transaction_order;
select top 100 * from load.dim_transaction_order;

*/
