with src_sf_account as(
    select *
    from fivetran.salesforce.account
)

select
    a.partner_recruiter_rate_c
    ,a.id
from src_sf_account a
