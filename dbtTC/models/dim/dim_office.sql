with
    src_tc_office as(
        select *
        from {{ ref('src_tc_office') }}
    )

select
    working.seq_dim_office.nextval as office_pk
    ,o.office_id
    ,o.office_name
from src_tc_office o

union select 0, 0, null
