with
    src_tc_user as(
        select *
        from {{ ref('src_tc_user') }}
    )

select
    working.seq_dim_user.nextval as user_pk
    ,u.user_id
    ,u.fullname
    ,u.brokerage
from
    src_tc_user u
