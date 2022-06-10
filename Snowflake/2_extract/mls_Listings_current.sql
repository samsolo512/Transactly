----------------------------------------------------------------------------------------------
-- postgres source

set search_path to 'mlsfarm2.public';

drop table if exists mlsfarm2.public.listings_current;


create table if not exists mlsfarm2.public.listings_current as  -- 7 min refresh
select
    *
from mlsfarm2.public.listings
where
    "ListingContractDate" >= current_date - interval '4 month'
    and "ListingContractDate" <= current_date
;


-- grant select on table listings_current to transactlyfivetran;
GRANT USAGE ON SCHEMA "public" TO transactlyfivetran;
-- GRANT SELECT ON ALL TABLES IN SCHEMA "public" TO transactlyfivetran;
GRANT SELECT on table public.ags to transactlyfivetran;
GRANT SELECT on table public.ags2021 to transactlyfivetran;
GRANT SELECT on table public.ao to transactlyfivetran;
GRANT SELECT on table public.dates to transactlyfivetran;
GRANT SELECT on table public.dates_saved to transactlyfivetran;
GRANT SELECT on table public.dump_fmls_listings to transactlyfivetran;
GRANT SELECT on table public.emails to transactlyfivetran;
GRANT SELECT on table public.exportlistings to transactlyfivetran;
GRANT SELECT on table public.knex_migrations to transactlyfivetran;
GRANT SELECT on table public.knex_migrations_lock to transactlyfivetran;
-- GRANT SELECT on table public.listings to transactlyfivetran;
GRANT SELECT on table public.listings_current to transactlyfivetran;
GRANT SELECT on table public.media to transactlyfivetran;
GRANT SELECT on table public.ofs to transactlyfivetran;
GRANT SELECT on table public.phones to transactlyfivetran;
GRANT SELECT on table public.process to transactlyfivetran;
GRANT SELECT on table public.queue to transactlyfivetran;
ALTER DEFAULT PRIVILEGES IN SCHEMA "public" GRANT SELECT ON TABLES TO transactlyfivetran;





----------------------------------------------------------------------------------------------
-- airbyte/snowflake source

create or replace table airbyte.postgresql.listings_current as  -- 7 min refresh
select
    *
from airbyte.postgresql.listings
where
    ListingContractDate >= dateadd(month, -13, getdate())
    and ListingContractDate <= current_date
;