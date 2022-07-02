with src_HS_owners as(
    select *
    from hubspot_extract.v2_daily.owners
)

select
    ownerid
    ,firstname
    ,lastname
from src_HS_owners
