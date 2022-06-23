with src_sf_partner_payout_c as(
    select *
    from fivetran.salesforce.partner_payout_c
)

select
    p.name
    ,p.amount_c
    ,p.period_c
    ,p.date_c
from src_sf_partner_payout_c p
