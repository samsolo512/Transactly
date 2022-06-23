with src_sf_user as(
    select *
    from fivetran.salesforce.user
)

select
    u.name
    ,u.id
from src_sf_user u
