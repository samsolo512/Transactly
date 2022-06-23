with
    src_mls_listings as(
        select *
        from {{ ref('src_mls_listings') }}
    )

    ,unique_listing as(
        select
            listingkey
            ,max(modificationtimestamp) as modificationtimestamp
        from
            {{ ref('src_mls_listings') }} l
        group by listingkey
    )

    ,max_updated as(
        select
            l.listingkey
            ,l.modificationtimestamp
            ,max(l.updated_at) as updated_at
        from
            {{ ref('src_mls_listings') }} l
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
            ,max(l.id) as id
        from
            {{ ref('src_mls_listings') }} l
            join max_updated ul
                on l.modificationtimestamp = ul.modificationtimestamp
                and l.listingkey = ul.listingkey
                and l.updated_at = ul.updated_at
        group by l.listingkey, l.modificationtimestamp, l.updated_at

select
    l.listingkey as mls_key  -- only unique id
    ,l.id as mls_id
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
from
    src_mls_listings l
    join max_id ul
        on l.listingkey = ul.listingkey
        and l.modificationtimestamp = ul.modificationtimestamp
        and l.updated_at = ul.updated_at
        and l.id = ul.id
where
    lower(l.propertytype) in ('residential', 'land', 'farm', 'attached dwelling')
