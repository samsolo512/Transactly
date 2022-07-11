with src_tc_line_item as (
    select *
    from {{ ref('src_tc_line_item')}}
)

select
    working.seq_dim_line_item.nextval as line_item_pk
    ,l.id as line_item_id
    ,l.status
    ,l.description
    ,l.agent_pays
    ,l.office_pays
    ,l.due_date
    ,case l.paid
        when 'TRUE' then 'yes'
        when 'FALSE' then 'no'
        else null
        end as paid
    ,case l.tc_paid
        when 'TRUE' then 'yes'
        when 'FALSE' then 'no'
        else null
        end as tc_paid
    ,l.cancelled_date
    ,l.created_date
from
    src_tc_line_item l

union select 0, null, null, null, null, null, null, null, null, null, null
