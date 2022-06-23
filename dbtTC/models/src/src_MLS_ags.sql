with src_MLS_ags as(
    select *
    from airbyte.postgresql.ags
)

select
    agt.id
    ,agt.key as MLS_key
    ,agt.MLSID as MLS_ID
    ,agt.fullname as MLS_fullname
    ,agt.email as MLS_email
    ,agt.city as MLS_city
    ,agt.stateorprovince as MLS_state
    ,agt.postalcode as MLS_zip
    ,agt.directphone as MLS_direct_phone
    ,agt.mobilephone as MLS_cell_phone
    ,agt.OfficePhone as MLS_agent_Office_Phone
    ,agt.Address as MLS_agent_Address
    ,agt.source as MLS_source
    ,agt.mainOfficeMLSID as MLS_main_office_MLS_ID
    ,agt.officeMLSID as MLS_office_MLS_ID
    ,agt.brokerMLSID as MLS_broker_MLS_ID
from src_MLS_ags agt