with cte_my_date AS (
    select dateadd(day, seq4(), '2016-01-01') AS date_id
    from table(generator(rowcount => 10000))  -- Number of days after reference date in previous line
)

select
    to_char(concat(year(date_id), '-', month(date_id), '-', day(date_id))::date, 'yyyymmdd') as date_pk
    ,date_id
    ,year(date_id) as year
    ,month(date_id) as month
    ,monthname(date_id) as month_name
    ,day(date_id) as day_of_mon
    ,dayofweek(date_id) as day_of_week
    ,weekofyear(date_id) as week_of_year
    ,dayofyear(date_id) as day_of_year
from cte_my_date

union select
    '19000101' as date_pk
    ,'1900-01-01' as date_id
    ,year(to_date('1900-01-01')) as year
    ,month(to_date('1900-01-01')) as month
    ,monthname(to_date('1900-01-01')) as month_name
    ,day(to_date('1900-01-01')) as day_of_mon
    ,dayofweek(to_date('1900-01-01')) as day_of_week
    ,weekofyear(to_date('1900-01-01')) as week_of_year
    ,dayofyear(to_date('1900-01-01')) as day_of_year

