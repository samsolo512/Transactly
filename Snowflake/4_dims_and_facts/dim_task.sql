-- dim_task

/*
use prod.dimensional;
use stage.dimensional;
use dev.dimensional;
 */


merge into dim_task as target
using(

    select
        id as task_id
        ,party_id as party
        ,cast(due_date as date) as task_due_date
        ,cast(completed_date as date) as task_completed_date
        ,current_timestamp() as load_datetime
        ,current_timestamp() as update_datetime
    from
        FIVETRAN.TRANSACTLY_APP_PRODUCTION_REC_ACCOUNTS.TASK
    where
        _fivetran_deleted = 'FALSE'

    union select 0, null, null, null, null, null

) source
    on target.task_id = source.task_id

when matched
    and(
        ifnull(target.party, '1') <> ifnull(source.party, '1')
        or ifnull(target.task_due_date, '1/1/1900') <> ifnull(source.task_due_date, '1/1/1900')
        or ifnull(target.task_completed_date, '1/1/1900') <> ifnull(source.task_completed_date, '1/1/1900')
    )
    then update set
        target.party = source.party
        ,target.task_due_date = source.task_due_date
        ,target.task_completed_date = source.task_completed_date
        ,target.update_datetime = source.update_datetime

when not matched then
    insert(task_pk, task_id, party, task_due_date, task_completed_date, load_datetime, update_datetime)
    values(working.seq_dim_task.nextval, source.task_id, source.party, source.task_due_date, source.task_completed_date, current_timestamp(), current_timestamp)
;
