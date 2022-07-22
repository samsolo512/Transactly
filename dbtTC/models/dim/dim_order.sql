with
    src_tc_transaction as(
        select *
        from {{ ref('src_tc_transaction') }}
    )

    ,src_tc_order as(
        select *
        from {{ ref('src_tc_order') }}
    )

    ,src_tc_user as(
        select *
        from {{ ref('src_tc_user') }}
    )

    ,src_tc_address as(
        select *
        from {{ ref('src_tc_address') }}
    )

    ,src_tc_office as(
        select *
        from {{ ref('src_tc_office') }}
    )

    ,close_date as(
        select
            o.order_id
            ,case
                when check_json(o.order_data) is null
                then json_extract_path_text(o.order_data, 'contract.closing_date')
                end as closing_date
        from src_tc_order o
    )

select
    working.seq_dim_order.nextval as order_pk
    ,t.transaction_id
    ,o.order_id
    ,o.agent_id
    ,usr.fullname as assigned_TC
    ,t_create.fullname as created_by
    ,t.created_date
    ,case
        when t.expiration_date <= getdate() then 'expired'
        else o.order_status
        end as order_status
    ,o.order_type
    ,a.street as address
    ,o.state
    ,case
        when o.order_side_id = 1 then 'buyer'
        when o.order_side_id = 2 then 'seller'
        else null
        end as order_side
    ,iff(try_to_date(cd.closing_date) is not null, to_date(cd.closing_date), null) as closed_date
    ,case
        when check_json(order_data) is null
        then json_extract_path_text(order_data, 'agentUser.offices[0].name')
        end as office_name
    ,o.last_sync
from
    src_tc_transaction t
    left join src_tc_address a on t.address_id = a.address_id
    left join src_tc_order o on t.transaction_id = o.transaction_id
    left join close_date cd on o.order_id = cd.order_id
    left join src_tc_office offc on o.assigned_tc_office_id = offc.office_id
    left join src_tc_user u on o.assigned_tc_id = u.user_id
    left join src_tc_user usr on u.user_id = u.google_user_id
    left join src_tc_user t_create on t.created_by_id = t_create.user_id

union select 0, 0, 0, 0, null, null, null, null, null, null, null, null, null, null, null