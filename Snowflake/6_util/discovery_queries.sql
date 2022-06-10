
------------------------------------------------------------------------------------------------------------------------
-- listings discovery

with unique_listing as(
    select
        max(modificationtimestamp) as moddate
         ,listingkey
    from listings
    group by listingkey
)

select
    cast(l.onmarkettimestamp as date) as on_market_date
    ,brokerage.name
    ,count(l.listingkey) as listingkey
from
    listings l
    join unique_listing ul
on l.modificationtimestamp = ul.moddate
    and l.listingkey = ul.listingkey
    left join ofs brokerage  -- select top 10 * from ofs
    on l.listoffice_id = brokerage.id
where
    on_market_date between '4/1/2022' and '4/30/2022'
group by on_market_date, brokerage.name
order by on_market_date, name desc;






------------------------------------------------------------------------------------------------------------------------
-- sample table

-- prepare sample table:
-- working.temp_stage_listings

create table working.temp_stage_listings as
select top 10 id, bathroomsfull, streetdirprefix, streetname from fivetran.production_mlsfarm2_public.listings
;

select * from working.temp_stage_listings;

insert into working.temp_stage_listings
    (id, bathroomsfull, streetdirprefix, streetname)
    values('9e22415b-c08b-4433-b8d3-62da3713ad3w', 3, 'w', 'kilmington')
;
-- delete from working.temp_stage_listings where id = '9e22415b-c08b-4433-b8d3-62da3713ad3w';

update working.temp_stage_listings
set bathroomsfull = 20
where id = '0f760f5e-75b7-41c4-bf49-a301fcc87244'
;




------------------------------------------------------------------------------------------------------------------------
-- merge
merge into dim_listing target
using(

    select
        l.*
        ,hash(*) as tablehash
    from working.temp_stage_listings l

) as source
    on target.id = source.id
    and target.tablehash = source.tablehash

when not matched then
    insert(id, bathroomsfull, streetdirprefix, streetname, current_record_flag, start_time, end_time, tablehash, update_date)
    values(source.id, source.bathroomsfull, source.streetdirprefix, source.streetname, 1, current_timestamp(0), '9999-12-31', source.tablehash, current_timestamp(0))
;


-- update rows that are no longer active
update dim_listings l
set
    l.current_record_flag = cast(w.new_flag as int)
    ,l.end_time = w.new_end_time
from(
    select
        id
        ,start_time
        ,tablehash
        ,case
            when lead(start_time) over (partition by id order by start_time) is not null
            then 0
            else current_record_flag
            end as new_flag
        ,case
            when lead(start_time) over (partition by id order by start_time) is not null
            then dateadd(second, -1, lead(start_time) over (partition by id order by start_time))
            else end_time
            end as new_end_time
    from dim_listings
) w
where
    l.id = w.id
    and l.tablehash = w.tablehash
;





------------------------------------------------------------------------------------------------------------------------
-- Cathy's self help query

select top 1000
    --agent
    ags.MlsId as AgentMLS_ID
    ,ags.FullName
    ,ags.Email as Agent_email
    ,ags.MobilePhone as Agent_CellPhone
    ,ags.OfficePhone as Agent_OfficePhone
    ,ags.Address as AgentAddress
    ,ags.City as AgentCity
    ,ags.StateOrProvince as AgentState
    ,ags.PostalCode as AgentZipCode
    --office
    ,ofs.Name as OfficeName
    ,ofs.MlsId as OfficeMLS_ID
    ,ofs.OriginatingSystemName
    ,ofs.Address as OfficeAddress
    ,ofs.City as OfficeCity
    ,ofs.StateOrProvince
    ,ofs.PostalCode
    ,ofs.Phone
    ,ofs.source
    --measures
    ,sum(case when l.standardstatus in('active', 'activeundercontract', 'active under contract') then 1 end) as active_count
    ,sum(case when l.standardstatus in('canceled', 'cancelled', 'withdrawn') then 1 end) as cancelled_or_withdrawn_count
    ,sum(case when l.standardstatus in('closed') then 1 end) as closed_count
from
    ags
    join ofs on ags.OfficeMlsId = ofs.MlsId
    left join listings l on l.listagent_id = ags.id
where
--     lower(ofs.MlsId) = 'wcinc'
    officename = 'stanberry realtors'
group by
    ofs.name, ofs.mlsid, ags.mlsid, ags.fullname, ags.MobilePhone, ofs.MlsId, ags.MlsId, ags.FullName, ags.Email, ofs.Name, ags.OfficePhone, ags.Address, ags.City, ags.StateOrProvince, ags.PostalCode, ofs.OriginatingSystemName, ofs.Address, ofs.City, ofs.StateOrProvince, ofs.PostalCode, ofs.Phone, ofs.source
;


-- brokerage unique ID
select key, mlsid, max(updated_at) updated_at from ofs group by key, mlsid

-- agent unique ID
select key, mlsid, max(updated_at) as updated_at from ags group by key, mlsid;



------------------------------------------------------------------------------------------------------------------------
--discovery queries

select
--     max(modificationtimestamp) as modificationtimestamp
    listingid
    ,listoffice_id
    ,count(1)
from fivetran.production_mlsfarm2_public.listings
group by listingid, listoffice_id
order by count(1) desc
;

select * from fivetran.production_mlsfarm2_public.listings where listingid = '2204924';
-- listingkey is unique to the property, max 2 dups, no nulls
-- listingid is meaningless, even when paired with sourcesystemkey, sourcesystem_id, or listoffice_id

select count(1) from fivetran.production_mlsfarm2_public.listings;








------------------------------------------------------------------------------------------------------------------------
-- find date fields
select column_name, data_type
from fivetran.information_schema.columns
where
    table_name = 'LISTINGS'
    and (
            data_type like '%TIME%'
        or data_type like '%DATE%'
    )
;

--created_at  --2021-2022
select
    date_part(year,created_at) as created_at
    ,count(1)
from fivetran.production_mlsfarm2_public.listings
group by date_part(year,created_at)
order by 1
;


--onmarketdate  ~1991-2022
select
    date_part(year, to_timestamp(onmarketdate)) as created_at
    ,count(1)
from
--     fivetran.production_mlsfarm2_public.listings
    airbyte.postgresql.listings l
group by date_part(year, to_timestamp(onmarketdate))
order by 1
;


--calculated_date_on   ~1991-2022
select
    date_part(year, to_timestamp(calculated_date_on)) as created_at
    ,count(1)
from
--     fivetran.production_mlsfarm2_public.listings
    airbyte.postgresql.listings l
group by date_part(year, to_timestamp(calculated_date_on))
order by 1
;


--listingcontractdate  ~1991-2022
select
    date_part(year, to_timestamp(listingcontractdate)) as created_at
    ,count(1)
from
--     fivetran.production_mlsfarm2_public.listings
    airbyte.postgresql.listings l
group by date_part(year, to_timestamp(listingcontractdate))
order by 1
;


--activationdate  ~2002-2022
select
    date_part(year,activationdate) as created_at
    ,count(1)
from fivetran.production_mlsfarm2_public.listings
group by date_part(year,activationdate)
order by 1
;


--created_at  --2021-2022 / listingcontractdate  ~1991-2022
select
    date_part(year,modificationtimestamp) as modificationtimestamp_year
    ,date_part(month,modificationtimestamp) as modificationtimestamp_month
    ,date_part(year,listingcontractdate) as listingcontractdate
    ,count(1)
from fivetran.production_mlsfarm2_public.listings
group by date_part(year,modificationtimestamp), date_part(year,listingcontractdate), date_part(month,modificationtimestamp)
order by 1,2,3
;

