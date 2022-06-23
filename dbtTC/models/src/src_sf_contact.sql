with src_sf_contact as(
    select *
    from fivetran.salesforce.contact
)

select
    c.agent_c
    ,c.agent_brokerage_c
    ,c.id
from src_sf_contact c
