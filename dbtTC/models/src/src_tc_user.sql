with src_tc_user as(
    select *
    from fivetran.transactly_app_production_rec_accounts.user
    where lower(_fivetran_deleted) = 'false'
)

select
    u.id
    ,u.join_date
    ,u.is_active
    ,u.is_tc_client
    ,u.assigned_transactly_tc_id
    ,u.last_online_date
    ,u.first_name
    ,u.last_name
    ,concat(u.first_name, ' ', u.last_name) as fullname
    ,u.email
    ,u.first_login
    ,u.autopay_date
    ,u.created
from src_tc_user u
