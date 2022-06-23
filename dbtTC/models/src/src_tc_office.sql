with src_tc_office as(
    select *
    from fivetran.transactly_app_production_rec_accounts.office
    where lower(_fivetran_deleted) = 'false'
)

select
    o.id
    ,o.name
    ,o.parent_office_id
from src_tc_office o
