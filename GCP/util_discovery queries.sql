-- information schema  -- https://cloud.google.com/bigquery/docs/information-schema-tables
select *
from business-analytics-337515.transactly_app_production_rec_accounts.INFORMATION_SCHEMA.COLUMNS
where column_name like '%date%'
order by column_name
