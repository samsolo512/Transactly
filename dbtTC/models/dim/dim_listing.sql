with
    src_mls_listings as(
        select *
        from {{ ref('src_mls_listings') }}
    )

    ,unique_listing as(
        select
            mls_key
            ,max(modificationtimestamp) as modificationtimestamp
        from
            src_mls_listings l
        group by mls_key
    )

    ,max_updated as(
        select
            l.mls_key
            ,l.modificationtimestamp
            ,max(l.updated_at) as updated_at
        from
            src_mls_listings l
            join unique_listing ul
                on l.modificationtimestamp = ul.modificationtimestamp
                and l.mls_key = ul.mls_key
        group by l.mls_key, l.modificationtimestamp
    )

    ,max_id as(
        select
            l.mls_key
            ,l.modificationtimestamp
            ,l.updated_at
            ,max(l.mls_id) as mls_id
        from
            src_mls_listings l
            join max_updated ul
                on l.modificationtimestamp = ul.modificationtimestamp
                and l.mls_key = ul.mls_key
                and l.updated_at = ul.updated_at
        group by l.mls_key, l.modificationtimestamp, l.updated_at
    )

select
    l.mls_key  -- only unique id
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
from
    src_mls_listings l
    join max_id ul
        on l.mls_key = ul.mls_key
        and l.modificationtimestamp = ul.modificationtimestamp
        and l.updated_at = ul.updated_at
        and l.mls_id = ul.mls_id
where
    lower(l.propertytype) in ('residential', 'land', 'farm', 'attached dwelling')
