with src_tc_line_item as (
    select *
    from {{ ref('src_tc_line_item')}}
)

select
    working.seq_dim_line_item.nextval as line_item_pk
    ,l.id as line_item_id
    ,l.status
    ,l.description
from
    src_tc_line_item l

union select 0, null, null, null
