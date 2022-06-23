with src_sf_opportunity_line_item as(
    select *
    from fivetran.salesforce.opportunity_line_item
)

select
    o.product_revenue_c
    ,o.product_2_id
    ,o.opportunity_id
from src_sf_opportunity_line_item o
