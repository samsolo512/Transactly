with src_tc_user as(
    select *
    from fivetran.transactly_app_production_rec_accounts.user
    where lower(_fivetran_deleted) = 'false'
)

select
    u.id as user_id
    ,u.join_date
    ,u.is_active
    ,u.is_tc_client
    ,u.assigned_transactly_tc_id
    ,cast(u.last_online_date as date) as last_online_date
    ,u.first_name
    ,u.last_name
    ,concat(u.first_name, ' ', u.last_name) as fullname
    ,u.email
    ,u.first_login
    ,cast(u.autopay_date as date) as autopay_date
    ,cast(u.created as date) as created
    ,u.google_user_id
    ,u.pays_at_title
    ,u.brokerage
from src_tc_user u
