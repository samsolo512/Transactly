-- fact_listing

/*
use prod.dimensional;
use stage.dimensional;
use dev.dimensional;
 */


--Fact_Listing_sp

-- create or replace procedure working.fact_listing_sp()
--     returns string not null
--     language javascript
--     execute as caller
-- as
-- $$
--
--     table_name = 'Fact_Listing';
--
--     //delete from target if record isn't in source
--     var set_query = `
--
--     merge into Fact_Listing as target
--     using(
--
--         select
--             target.listing_pk
--             ,target.brokerage_pk
--             ,target.agent_pk
--         from
--             dimensional.fact_Listing target
--             left join(
--                 select
--                     --grain
--                     list.listing_pk
--                     ,b.brokerage_pk
--                     ,a.agent_pk
--
--                 from
--                     fivetran.production_mlsfarm2_public.listings_current l
--                     join max_id ul
--                         on l.listingkey = ul.listingkey
--                         and l.modificationtimestamp = ul.modificationtimestamp
--                         and l.id = ul.id
--                         and l._fivetran_deleted = 'FALSE'
--                     join dim_listing list on l.listingkey = list.listingkey
--                     left join fivetran.production_mlsfarm2_public.ags ags
--                         join agent_maxUpdate amu
--                             on ags.key = amu.key
--                             and ags.mlsid = amu.mlsid
--                             and ags.updated_at = amu.updated_at
--                             and ags._fivetran_deleted = 'FALSE'
--                     on l.listagent_id = ags.id
--                     join dim_agent a
--                         on ags.key = a.key
--                         and ags.mlsid = a.agentmlsid
--                     left join fivetran.production_mlsfarm2_public.ofs ofs
--                         join brokerage_minCreated mc
--                             on ofs.key = mc.key
--                             and ofs.MLSID = mc.MLSID
--                             and ofs.updated_at = mc.updated_at
--                             and ofs.created_at = mc.created_at
--                             and ofs._fivetran_deleted = 'FALSE'
--                     on ags.officemlsid = ofs.mlsid
--                     join dim_brokerage b
--                         on ofs.key = b.key
--                         and ofs.mlsid = b.officemlsid
--
--                 group by list.listing_pk, agent_pk, brokerage_pk
--
--                 union select '0', '0', '0'
--
--         ) source
--             on target.listing_pk = source.listing_pk
--             and target.agent_pk = source.agent_pk
--             and target.brokerage_pk = source.brokerage_pk
--
--         where
--             source.listing_pk is null
--             and source.agent_pk is null
--             and source.brokerage_pk is null
--
--     ) as source
--         on target.listing_pk = source.listing_pk
--         and target.agent_pk = source.agent_pk
--         and target.brokerage_pk = source.brokerage_pk
--
--     when matched then delete
--
--     `;
--
--     var query_statement = snowflake.createStatement( {sqlText: set_query} );
--     var query_run = query_statement.execute();
--
--
--
--     // update or insert into target
--     var set_query = `
--
--     merge into fact_listing as target
--     using(


create or replace table dimensional.fact_listing as

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
        working.listings_current l
        join dim_listing list on l.mls_key = list.mls_key
        join dim_agent a on a.id = l.listagent_id
        join dim_brokerage b on l.listoffice_id = b.id
        join dim_date dt on l.calculated_date_on = dt.date_id
    group by list.listing_pk, b.brokerage_pk, a.agent_pk, dt.date_pk

--     group by l.status
;

-- select distinct status from working.listings_current

--     ) as source
--         on target.listing_pk = source.listing_pk
-- --         and target.agent_pk = source.agent_pk
-- --         and target.brokerage_pk = source.brokerage_pk
--
--     when matched
--         and(
--             ifnull(target.active_flag, -1) <> ifnull(source.active_flag, -1)
--             or ifnull(target.cancelled_or_withdrawn_flag, -1) <> ifnull(source.cancelled_or_withdrawn_flag,-1)
--             or ifnull(target.closed_flag, -1) <> ifnull(source.closed_flag, -1)
--         )
--         then update set
--             target.active_flag = source.active_flag
--             ,target.cancelled_or_withdrawn_flag = source.cancelled_or_withdrawn_flag
--             ,target.closed_flag = source.closed_flag
--             ,target.update_datetime = current_timestamp()
--
--     when not matched then
--         insert(listing_pk, brokerage_pk, agent_pk, active_flag, cancelled_or_withdrawn_flag, closed_flag, update_datetime)
--         values(source.listing_pk, source.brokerage_pk, source.agent_pk, source.active_flag, source.cancelled_or_withdrawn_flag, source.closed_flag, current_timestamp())
--
--     `;
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

truncate table dimensional.fact_listing;
call working.fact_listing_sp();
create or replace table load.fact_listing as select * from dimensional.fact_listing;
select count(1) from load.fact_listing;

*/

