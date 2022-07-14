--dim_line_item

merge into dim_line_item as target
using(
    select
        l.id as line_item_id
        ,l.status
        ,l.description
        ,current_timestamp() as load_datetime
        ,current_timestamp() as update_datetime
    from 
        fivetran.transactly_app_production_rec_accounts.line_item l
    where
        _fivetran_deleted = 'FALSE'
  
    union select 0, null, null, null, null
  
) as source
    on target.line_item_id = source.line_item_id
    
when matched
    and(
        ifnull(target.status, '1') <> ifnull(source.status, '1')
        or ifnull(target.description, '1') <> ifnull(source.description, '1')
    )
    then update set
        target.status = source.status
        ,target.description = source.description
        ,target.update_datetime = current_timestamp()
    
when not matched then
    insert(line_item_pk, line_item_id, status, description, load_datetime, update_datetime)
    values(working.seq_dim_line_item.nextval, source.line_item_id, source.status, source.description, current_timestamp(), current_timestamp())
;
