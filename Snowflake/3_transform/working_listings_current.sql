-- listings_current

create or replace table working.listings_current as

with
    unique_listing as(
        select
            listingkey
            ,max(modificationtimestamp) as modificationtimestamp
        from
--             fivetran.production_mlsfarm2_public.listings_current
            airbyte.postgresql.listings_current l
        group by listingkey
    )

    ,max_updated as(
        select
            l.listingkey
            ,l.modificationtimestamp
            ,max(l.updated_at) as updated_at
        from
--             fivetran.production_mlsfarm2_public.listings_current l
            airbyte.postgresql.listings_current l
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
--             fivetran.production_mlsfarm2_public.listings_current l
            airbyte.postgresql.listings_current l
            join max_updated ul
                on l.modificationtimestamp = ul.modificationtimestamp
                and l.listingkey = ul.listingkey
                and l.updated_at = ul.updated_at
        group by l.listingkey, l.modificationtimestamp, l.updated_at
    )

select distinct
    l.listingkey as mls_key  -- only unique id
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
--     fivetran.production_mlsfarm2_public.listings_current l
    airbyte.postgresql.listings_current l
    join max_id ul
        on l.listingkey = ul.listingkey
        and l.modificationtimestamp = ul.modificationtimestamp
        and l.updated_at = ul.updated_at
        and l.id = ul.id
where
    lower(l.propertytype) in ('residential', 'land', 'farm', 'attached dwelling')
--     and l._fivetran_deleted = 'FALSE'
;


-- select distinct standardstatus from fivetran.production_mlsfarm2_public.listings_current