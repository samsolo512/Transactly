-- dim_user

/*
use prod.dimensional;
use stage.dimensional;
use dev.dimensional;
*/


create or replace procedure working.dim_user_sp()
    returns string not null
    language javascript
	execute as caller
    as
    $$

    table_name = 'dim_user';

    //delete from target if record isn't in source
    var set_query = `

    merge into dimensional.dim_user as target
    using(

        select
            target.user_id
        from
            dimensional.dim_user target
            left join(
                select
                    u.id as user_id
                from
                    fivetran.transactly_app_production_rec_accounts.user u
                where
                    _fivetran_deleted = 'FALSE'

                union select 0

        ) source
            on target.user_id = source.user_id

        where
            source.user_id is null

    ) as source
        on target.user_id = source.user_id

    when matched then delete

    `;

    var query_statement = snowflake.createStatement( {sqlText: set_query} );
    var query_run = query_statement.execute();



    // update or insert into target
    var set_query = `

    merge into dim_user as target
    using(

        select
            u.id as user_id
            ,u.first_name
            ,u.last_name
            ,concat(u.first_name, ' ', u.last_name) as full_name

            /*
            ,replace(  -- replace two single quotes with one single quote
                replace(  -- replace double quotes with single quotes
                    u.first_name
                    ,'"'
                    ,'\''
                )
                ,'\'\''
                ,'\''
            ) as first_name
            ,replace(  -- replace two single quotes('') with one single quote(')
                replace(  -- replace double quotes(") with single quotes(')
                    u.last_name
                    ,'"'
                    ,'\''
                )
                ,'\'\''
                ,'\''
            ) as last_name
            ,concat(
                replace(  -- replace two single quotes with one single quote
                    replace(  -- replace double quotes with single quotes
                        u.first_name
                        ,'"'
                        ,'\''
                    )
                    ,'\'\''
                    ,'\''
                )
                ,' '
                ,replace(  -- replace two single quotes('') with one single quote(')
                    replace(  -- replace double quotes(") with single quotes(')
                        u.last_name
                        ,'"'
                        ,'\''
                    )
                    ,'\'\''
                    ,'\''
                )
            ) as full_name
            */

            ,u.email
            ,u.license_state
            ,u.brokerage
            ,case when u.is_active = 'TRUE' then 1 else 0 end as user_is_active_flag

            /*
            ,case
                when trim(u.email) regexp '^[a-zA-Z0-9._+\-]*@[a-zA-Z0-9._+\-]*\.[a-zA-Z0-9._+\-]*$' then 1
                else 0
                end as valid_email_flag
            */

            ,1 as valid_email_flag

            ,current_timestamp() as load_datetime
            ,current_timestamp() as update_datetime
        from
            fivetran.transactly_app_production_rec_accounts.user u
        where
            _fivetran_deleted = 'FALSE'

        union select 0, null, null, null, null, null, null, null, null, null, null

    ) as source
        on target.user_id = source.user_id

    when matched
        and(
            ifnull(target.first_name, '1') <> ifnull(source.first_name, '1')
            or ifnull(target.last_name, '1') <> ifnull(source.last_name, '1')
            or ifnull(target.full_name, '1') <> ifnull(source.full_name, '1')
            or ifnull(target.email, '1') <> ifnull(source.email, '1')
            or ifnull(target.license_state, '1') <> ifnull(source.license_state, '1')
            or ifnull(target.brokerage, '1') <> ifnull(source.brokerage, '1')
            or ifnull(target.user_is_active_flag, '1') <> ifnull(source.user_is_active_flag, '1')
            or ifnull(target.valid_email_flag, '1') <> ifnull(source.valid_email_flag, '1')
        )
        then update set
            target.first_name = source.first_name
            ,target.last_name = source.last_name
            ,target.full_name = source.full_name
            ,target.email = source.email
            ,target.license_state = source.license_state
            ,target.brokerage = source.brokerage
            ,target.user_is_active_flag = source.user_is_active_flag
            ,target.valid_email_flag = source.valid_email_flag
            ,update_datetime = current_timestamp()

    when not matched then
        insert(user_pk, user_id, first_name, last_name, full_name, email, license_state, brokerage, user_is_active_flag, valid_email_flag, load_datetime, update_datetime)
        values(working.seq_dim_user.nextval, source.user_id, source.first_name, source.last_name, source.full_name, source.email, source.license_state, source.brokerage, source.user_is_active_flag, source.valid_email_flag, current_timestamp(), current_timestamp())

   `;

    var query_statement = snowflake.createStatement( {sqlText: set_query} );
    var query_run = query_statement.execute();

    result = "Complete!";
    return result;

    $$
;


/*

truncate table dimensional.dim_user;
call working.dim_user_sp();
create or replace table load.dim_user as select * from dimensional.dim_user;
select top 100 * from load.dim_user;

*/