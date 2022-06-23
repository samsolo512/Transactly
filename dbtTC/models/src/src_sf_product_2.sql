with src_sf_product_2 as(
    select *
    from fivetran.salesforce.product_2
)

select
    p.name
    ,p.id
from src_sf_product_2 p
