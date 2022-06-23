with src_sf_opportunity as(
    select *
    from fivetran.salesforce.opportunity
)

select
    o.contact_id
    ,o.account_id
    ,o.close_date
    ,o.name
    ,o.owner_id
from src_sf_opportunity o
