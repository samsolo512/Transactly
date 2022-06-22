with src_TC_ofs as(
    select *
    from airbyte.postgresql.ofs
)

select
    ofs.id
    ,ofs.key as MLS_key
    ,ofs.mlsid as MLS_ID
    ,ofs.name as MLS_name
    ,ofs.source as MLS_source
    ,ofs.url as MLS_url
    ,ofs.phone as MLS_phone
    ,ofs.Address as MLS_street
    ,ofs.city as MLS_city
    ,ofs.stateOrProvince as MLS_state
    ,ofs.postalCode as MLS_zip
    ,ofs.brokerMLSID as MLS_broker_MLS_ID
    ,ofs.mainOfficeMLSID as MLS_office_MLS_ID
    ,ofs.ManagerMLSID as MLS_manager_MLS_ID
    ,ofs.status as MLS_status
    ,ofs.ca as MLS_ca
    ,ofs.ua as MLS_ua
    ,ofs.i1 as MLS_i1
    ,ofs.modificationTimestamp as MLS_modification_time_stamp
from src_TC_ofs ofs
