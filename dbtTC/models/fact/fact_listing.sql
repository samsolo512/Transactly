with
    src_mls_listings as(
        select *
        from {{ ref('src_mls_listings') }}
    )

    ,dim_listing as(
        select *
        from {{ ref('dim_listing') }}
    )

    ,dim_agent as(
        select *
        from {{ ref('dim_agent') }}
    )

    ,dim_brokerage as(
        select *
        from {{ ref('dim_brokerage') }}
    )

    ,dim_date as(
        select *
        from {{ ref('dim_date') }}
    )

select
    --grain
    list.listing_pk
    ,b.brokerage_pk
    ,a.agent_pk
    ,dt.date_pk
    ,sum(case when l.status in('active') then 1 end) as active_count
    ,sum(case when l.status in('coming soon') then 1 end) as coming_soon_count
    ,sum(case when l.status in('pending') then 1 end) as pending_count
    ,sum(case when l.status in('closed') then 1 end) as closed_count
    ,sum(case when l.status in('other', '?') then 1 end) as other_count
    ,count(1) as total_listings
from
    src_mls_listings l
    join dim_listing list on l.mls_key = list.mls_key
    join dim_agent a on a.id = l.listagent_id
    join dim_brokerage b on l.listoffice_id = b.id
    join dim_date dt on cast(l.listingcontractdate as date) = dt.date_id
group by list.listing_pk, b.brokerage_pk, a.agent_pk, dt.date_pk

