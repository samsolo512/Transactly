-- dim_listing

/*
use prod.dimensional;
use stage.dimensional;
use dev.dimensional;
*/


--Dim_Listing_sp

-- create or replace procedure working.dim_listing_sp()
--     returns string not null
--     language javascript
--     execute as caller
-- as
-- $$
--
-- table_name = 'Dim_Listing';
--
-- //delete from target if record isn't in source
-- var set_query = `
--
-- merge into dimensional.Dim_Listing as target
-- using(
--
--     with
--         unique_listing as(
--             select
--                 max(modificationtimestamp) as modificationtimestamp
--                 ,listingkey
--             from fivetran.production_mlsfarm2_public.listings_current
--             group by listingkey
--         )
--
--         ,max_id as(
--             select
--                 l.listingkey
--                 ,l.modificationtimestamp
--                 ,max(l.id) as id
--             from
--                 fivetran.production_mlsfarm2_public.listings_current l
--                 join unique_listing ul
--                     on l.modificationtimestamp = ul.modificationtimestamp
--                     and l.listingkey = ul.listingkey
--             group by l.listingkey, l.modificationtimestamp
--         )
--
--     select
--         target.listingkey
--     from
--         dimensional.dim_Listing target
--         left join(
--             select
--                 l.listingkey
--                 ,case
--                     when l.standardstatus in('active', 'activeundercontract', 'active under contract') then 'active'
--                     when l.standardstatus in('expired') then 'expired'
--                     when l.standardstatus in('cancelled', 'canceled', 'withdrawn') then 'cancelled'
--                     when l.standardstatus in('expired') then 'expired'
--                     when l.standardstatus in('sold', 'closed') then 'closed'
--                     else 'other'
--                     end as status
--                 ,lotsizeacres
--                 ,bedroomstotal
--                 ,listprice
--                 ,closeprice
--                 ,listingid
--                 ,city
--             from
--                 fivetran.production_mlsfarm2_public.listings_current l
--                 join max_id ul
--                     on l.listingkey = ul.listingkey
--                     and l.modificationtimestamp = ul.modificationtimestamp
--                     and l.id = ul.id
--             where
--                 l._fivetran_deleted = 'FALSE'
--
--             union select '0', null, null, null, null, null, null, null
--
--     ) source
--         on target.listingkey = source.listingkey
--
--     where
--         source.listingkey is null
--
-- ) as source
--     on target.listingkey = source.listingkey
--
-- when matched then delete
--
-- `;
--
-- var query_statement = snowflake.createStatement( {sqlText: set_query} );
-- var query_run = query_statement.execute();
--
--
--
-- // update or insert into target
-- var set_query = `
--
-- merge into dim_listing target
-- using(



create or replace table dimensional.dim_listing as

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
    ,l.postalcode
    ,l.listingContractDate
    ,l.cumulativeDaysOnMarket
    ,l.listagent_id
    ,l.propertyType
    ,l.listoffice_id
    ,l.source

from
    working.listings_current l
;




-- ) as source
--     on target.listingkey = source.listingkey
--
-- when matched
--     and (
--         ifnull(target.status, '1') <> ifnull(source.status, '1')
--         or ifnull(target.listprice, '1') <> ifnull(source.listprice, '1')
--         or ifnull(target.closeprice, '1') <> ifnull(source.closeprice, '1')
--         or ifnull(target.listingid, '1') <> ifnull(source.listingid, '1')
--         or ifnull(target.streetdirprefix, '1') <> ifnull(source.streetdirprefix, '1')
--         or ifnull(target.streetsuffix, '1') <> ifnull(source.streetsuffix, '1')
--         or ifnull(target.streetname, '1') <> ifnull(source.streetname, '1')
--         or ifnull(target.streetnumber, '1') <> ifnull(source.streetnumber, '1')
--         or ifnull(target.listingContractDate, '1') <> ifnull(source.listingContractDate, '1')
--         or ifnull(target.closeDate, '1') <> ifnull(source.closeDate, '1')
--         or ifnull(target.cumulativeDaysOnMarket, '1') <> ifnull(source.cumulativeDaysOnMarket, '1')
--
--     )
--     then update set
--         target.status = source.status
--         ,target.listprice = source.listprice
--         ,target.closeprice = source.closeprice
--         ,target.listingid = source.listingid
--         ,target.streetdirprefix = source.streetdirprefix
--         ,target.streetsuffix = source.streetsuffix
--         ,target.streetname = source.streetname
--         ,target.streetnumber = source.streetnumber
--         ,target.listingContractDate = source.listingContractDate
--         ,target.closeDate = source.closeDate
--         ,target.cumulativeDaysOnMarket = source.cumulativeDaysOnMarket
--         ,target.update_datetime = current_timestamp()
--
-- when not matched then
--     insert(listing_pk, listingkey, status, listprice, closeprice, listingid, streetdirprefix, streetsuffix, streetname, streetnumber, listingContractDate, closeDate, cumulativeDaysOnMarket, update_datetime)
--     values(working.seq_dim_listing.nextval, source.listingkey, source.status, source.listprice, source.closeprice, source.listingid, source.streetdirprefix, source.streetsuffix, source.streetname, source.streetnumber, source.listingContractDate, source.closeDate, source.cumulativeDaysOnMarket, current_timestamp())
--
-- `;
--
-- var query_statement = snowflake.createStatement( {sqlText: set_query} );
-- var query_run = query_statement.execute();









 //update rows that are no longer active
--  var set_query = `
--
-- update dim_listing l
-- set
--     l.current_record_flag = cast(w.new_flag as int)
--     ,l.end_time = w.new_end_time
-- from(
--     select
--         id
--         ,start_time
--         --,tablehash
--         ,case
--             when lead(start_time) over (partition by id order by start_time) is not null
--             then 0
--             else current_record_flag
--             end as new_flag
--         ,case
--             when lead(start_time) over (partition by id order by start_time) is not null
--             then dateadd(second, -1, lead(start_time) over (partition by id order by start_time))
--             else end_time
--             end as new_end_time
--     from dim_listing
-- ) w
-- where
--     l.id = w.id
--
--  `;
--
-- var query_statement = snowflake.createStatement( {sqlText: set_query} );
-- var query_run = query_statement.execute();
--
--
-- result = "Complete!";
-- return result;
--
-- $$
-- ;




/*

truncate table dimensional.dim_listing;
call working.dim_listing_sp();
create or replace table load.dim_listing as select * from dimensional.dim_listing;
select top 100 * from load.dim_listing;

*/

