with src_HS_object_properties as(
    select
        objectid
        ,name
        ,value
    from hubspot_extract.v2_daily.object_properties
)

select
    objectid
    ,name
    ,value
from src_HS_object_properties
