with
    src_mls_listings as(
        select *
        from {{ ref('src_mls_listings') }}
    )

select
    working.seq_dim_listing.nextval as listing_pk
    ,l.mls_key  -- only unique id
    ,l.mls_id
    ,l.status
    ,l.listprice
    ,l.closeprice
    ,l.listingid
    ,l.streetdirprefix
    ,l.streetsuffix
    ,l.streetname
    ,l.streetnumber
    ,l.city
    ,l.stateorprovince
    ,L.postalcode
    ,l.listingContractDate
    ,l.closeDate
    ,l.calculated_date_on
    ,l.cumulativeDaysOnMarket
    ,l.listagent_id
    ,l.propertyType
    ,l.listoffice_id
    ,l.source
from src_mls_listings l
