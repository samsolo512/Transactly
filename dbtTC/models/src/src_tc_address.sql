with src_tc_address as(
    select *
    from fivetran.transactly_app_production_rec_accounts.address
    where lower(_fivetran_deleted) = 'false'
)

select
    a.id as address_id
    ,a.address_line_1 as street
    ,a.city
    ,a.state
    ,a.zip
from src_tc_address a
