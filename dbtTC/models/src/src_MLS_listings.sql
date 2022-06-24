with
    src_mls_listings as(
        select *
        from airbyte.postgresql.listings
    )

    ,unique_listing as(
        select
            listingkey
            ,max(modificationtimestamp) as modificationtimestamp
        from
            src_mls_listings l
        group by listingkey
    )

    ,max_updated as(
        select
            l.listingkey
            ,l.modificationtimestamp
            ,max(l.updated_at) as updated_at
        from
            src_mls_listings l
            join unique_listing ul
                on l.modificationtimestamp = ul.modificationtimestamp
                and l.listingkey = ul.listingkey
        group by l.listingkey, l.modificationtimestamp
    )

    ,max_id as(
        select
            l.listingkey
            ,l.modificationtimestamp
            ,l.updated_at
            ,max(l.id) as mls_id
        from
            src_mls_listings l
            join max_updated ul
                on l.modificationtimestamp = ul.modificationtimestamp
                and l.listingkey = ul.listingkey
                and l.updated_at = ul.updated_at
        group by l.listingkey, l.modificationtimestamp, l.updated_at
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
from
    src_MLS_listings l
    join max_id ul
        on l.listingkey = ul.listingkey
        and l.modificationtimestamp = ul.modificationtimestamp
        and l.updated_at = ul.updated_at
        and l.id = ul.mls_id
where
    lower(l.propertytype) in ('residential', 'land', 'farm', 'attached dwelling')
    and to_date(listingcontractdate) >= '1/1/2021'
    and to_date(listingcontractdate) <= current_date()
