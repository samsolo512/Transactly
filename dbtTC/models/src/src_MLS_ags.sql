with src_MLS_ags as(
    select *
    from airbyte.postgresql.ags
)

select
    agt.id
    ,agt.key
    ,agt.MLSID
    ,agt.fullname
    ,agt.email
    ,agt.city
    ,agt.stateorprovince
    ,agt.postalcode
    ,agt.directphone
    ,agt.mobilephone
    ,agt.OfficePhone
    ,agt.Address
    ,agt.source
    ,agt.mainOfficeMLSID
    ,agt.officeMLSID
    ,agt.brokerMLSID
from src_MLS_ags agt