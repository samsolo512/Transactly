with
    src_tc_user as(
        select *
        from {{ ref('src_tc_user') }}
    )

    ,src_tc_line_item as(
        select *
        from {{ ref('src_tc_line_item') }}
    )

    ,src_tc_office as(
        select *
        from {{ ref('src_tc_office') }}
    )

    ,src_tc_order as(
        select *
        from {{ ref('src_tc_order') }}
    )

    ,src_tc_office_user as(
        select *
        from {{ ref('src_tc_office_user') }}
    )

    ,last_order_created as (
        select
            l.user_id
            ,max(l.created) as last_order_created
        from
            src_tc_user u
            join src_tc_line_item l on l.user_id = u.user_id
        where
            l.user_id = u.user_id
            and l.description in ('Listing Coordination Fee', 'Transaction Coordination Fee')
            and l.status not in ('withdrawn', 'cancelled')
        group by l.user_id
    )

    ,fifth_order as(
        select * from(
            select
                l.user_id
                ,l.due_date
                ,row_number() over (partition by l.user_id order by l.due_date) as row_num
            from
                src_tc_user u
                join src_tc_line_item l on l.user_id = u.user_id
            where
                l.due_date is not null
                and l.description in ('Listing Coordination Fee', 'Transaction Coordination Fee')
            )
        where row_num = 5
    )

select
    working.seq_dim_client.nextval as client_pk
    ,*
from(
    select
        user_id
        ,first_name
        ,last_name
        ,email
        ,max(last_order_created) as last_order_created
        ,max(last_order_due) as last_order_due
        ,max(tier_3) as tier_3
        ,max(tier_2) as tier_2
        ,max(tier_1) as tier_1
        ,max(pays_at_title) as pays_at_title
    from(
        select
            u.user_id
            ,u.first_name as first_name
            ,u.last_name as last_name
            ,u.email as email
            ,loc.last_order_created
            ,max(li.due_date) as last_order_due
            ,u.created as tier_3
            ,min(li.due_date) as tier_2
            ,fifth.due_date as tier_1
            ,case u.pays_at_title
                when 'TRUE' then 'yes'
                when 'FALSE' then 'no'
                else null
                end as pays_at_title
        from
            src_tc_user u
            join src_tc_line_item li on li.user_id = u.user_id
            left join last_order_created loc on u.user_id = loc.user_id
            left join fifth_order fifth on u.user_id = fifth.user_id
        where
            u.is_tc_client = 1
            and li.status not in ('withdrawn', 'cancelled')
            and li.due_date is not null
            and lower(li.description) like ('%coordination fee')
        group by u.user_id, u.first_name, u.last_name, u.email, loc.last_order_created, u.created, fifth.due_date, u.pays_at_title


        -- users without orders
        union
        select
            u.user_id
            ,u.first_name as first_name
            ,u.last_name as last_name
            ,u.email as email
            ,null as last_order_created
            ,null as last_order_due
            ,u.created as tier_3
            ,null as tier_2
            ,null as tier_1
            ,null as pays_at_title
        from
            src_tc_user u
            left join src_tc_order o on u.user_id = o.agent_id
        where
            u.is_tc_client = 1
            and o.agent_id is null
    )
    group by user_id, first_name, last_name, email
)
