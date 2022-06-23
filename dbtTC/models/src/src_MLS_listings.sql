with src_MLS_listings as(
    select
        listingkey
        ,id
        ,standardstatus
        ,listprice
        ,closeprice
        ,listingid
        ,streetdirprefix
        ,streetsuffix
        ,streetname
        ,streetnumber
        ,city
        ,stateorprovince
        ,postalcode
        ,listingContractDate
        ,closeDate
        ,calculated_date_on
        ,cumulativeDaysOnMarket
        ,listagent_id
        ,propertyType
        ,listoffice_id
        ,source
        ,modificationtimestamp
        ,updated_at
    from airbyte.postgresql.listings
    where
        to_date(listingcontractdate) >= '1/1/2021'
        and to_date(listingcontractdate) <= current_date()
)

select
    l.listingkey as mls_key
    ,l.id as mls_id
    ,case
        when l.standardstatus in('active', 'activeundercontract', 'active under contract') then 'active'
        when l.standardstatus in('sold', 'closed') then 'closed'
        when l.standardstatus in('comingsoon', 'coming soon') then 'coming soon'
        when l.standardstatus in('pending') then 'pending'
        when l.standardstatus in('deleted', 'hold', 'new', 'backonmarket', 'pricechange', 'expired', 'delete', 'incomplete', 'rentalleased', 'rentalunavailable') then 'other'
        when l.standardstatus in('cancelled', 'canceled', 'withdrawn') then 'other'  -- was 'cancelled
        else '?'
        end as status
    ,l.listprice
    ,l.closeprice
    ,l.listingid
    ,l.streetdirprefix
    ,l.streetsuffix
    ,l.streetname
    ,l.streetnumber
    ,l.city
    ,l.stateorprovince
    ,l.postalcode
    ,l.listingContractDate
    ,l.closeDate
    ,l.calculated_date_on
    ,l.cumulativeDaysOnMarket
    ,l.listagent_id
    ,l.propertyType
    ,l.listoffice_id
    ,l.source
    ,l.modificationtimestamp
    ,l.updated_at
from src_MLS_listings l
