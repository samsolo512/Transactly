-- Salesforce report: Closed Won Opportunities with Contacts
select
    u.name as opportunity_owner
    ,o.contact_id
    ,o.name as opportunity_name
    ,o.close_date
    ,o.stage_name as stage
    ,sum(oli.product_revenue_c) as total_revenue
from
    fivetran.salesforce.opportunity o
    left join fivetran.salesforce.opportunity_line_item oli on o.id = oli.opportunity_id  -- select top 10 * from fivetran.salesforce.opportunity_line_item
    join fivetran.salesforce.user u on o.owner_id = u.id
where
    close_date between '6/1/2022' and getdate()
    and stage = 'Closed Won'
group by o.contact_id, o.name, o.close_date, o.stage_name, u.name
having total_revenue > 0
order by opportunity_owner, close_date desc
;




-- Salesforce report: Monthly Revenue Report by Partner
select
    a.name
    ,cast(a.created_date as date) as created_date
    ,o.name as opportunity_name
    ,sum(oli.product_revenue_c) as total_revenue
    ,o.close_date
    ,p.name as product_name
    ,u.name as opportunity_owner
    ,f.name as fulfillment_processor
    ,p.family as product_family
    ,c.mailing_state
    ,c.mailing_street
from
    fivetran.salesforce.opportunity o
    left join fivetran.salesforce.opportunity_line_item oli on o.id = oli.opportunity_id  -- select top 10 * from fivetran.salesforce.opportunity_line_item
    join fivetran.salesforce.user u on o.owner_id = u.id
    left join fivetran.salesforce.user f on o.fulfillment_processor_c = f.id
    left join fivetran.salesforce.account a on o.account_id = a.id
    left join fivetran.salesforce.product_2 p on oli.product_2_id = p.id
    left join fivetran.salesforce.contact c on o.contact_id = c.id
group by a.name, cast(a.created_date as date), opportunity_name, close_date, product_name, opportunity_owner, fulfillment_processor, product_family, mailing_state, mailing_street
order by opportunity_owner, close_date desc
;




-- Salesforce report: Partner Revenue Share
select top 10
    o.close_date
    ,ppc.date_c as payout_date
    ,ppc.period_c as period
    ,o.name as opportunity_name
    ,u.name as opportunity_owner
    ,a.partner_recruiter_rate_c as recruiter_rate
    ,vpc.name as vendor_payout_name
    ,p.name as product_name
    ,vpc.amount_c as vendor_paid
    ,ppc.name as partner_payout_name
    ,ppc.amount_c as partner_paid_amount
    ,c.agent_c as agent
    ,c.agent_brokerage_c as agent_brokerage
    ,sum(vpc.amount_c) * .03 as expected_amount
    ,sum(oli.product_revenue_c) as total_revenue
from
    fivetran.salesforce.opportunity o
    left join fivetran.salesforce.opportunity_line_item oli on o.id = oli.opportunity_id  -- select top 10 * from fivetran.salesforce.opportunity_line_item
    join fivetran.salesforce.user u on o.owner_id = u.id
    left join fivetran.salesforce.product_2 p on oli.product_2_id = p.id
    left join fivetran.salesforce.contact c on o.contact_id = c.id
    left join fivetran.salesforce.partner_payout_c ppc on p.id = ppc.product_c
    left join fivetran.salesforce.vendor_payout_c vpc on p.id = vpc.product_c
    left join fivetran.salesforce.account a on o.account_id = a.id
where
    ppc.date_c between '6/1/2022' and getdate()
group by o.close_date, ppc.period_c, o.name, u.name, vpc.name, p.name, vpc.amount_c, ppc.name, ppc.amount_c, c.agent_c, c.agent_brokerage_c, a.partner_recruiter_rate_c, ppc.date_c
order by opportunity_owner, close_date desc
;