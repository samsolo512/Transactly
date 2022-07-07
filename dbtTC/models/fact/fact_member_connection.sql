with
    src_tc_transaction_transactly_vendor as(
        select *
        from {{ ref('src_tc_transaction_transactly_vendor') }}
    )

    ,src_tc_transaction_transactly_vendor_member_notified as(
        select *
        from {{ ref('src_tc_transaction_transactly_vendor_member_notified') }}
    )

    ,src_tc_transactly_vendor as(
        select *
        from {{ ref('src_tc_transactly_vendor') }}
    )

   ,src_tc_user_transactly_vendor_opt_out as(
        select *
        from {{ ref('src_tc_user_transactly_vendor_opt_out') }}
    )

    ,src_tc_member as(
        select *
        from {{ ref('src_tc_member') }}
    )

    ,src_tc_order as(
        select *
        from {{ ref('src_tc_order') }}
    )

    ,src_tc_transaction as(
        select *
        from {{ ref('src_tc_transaction') }}
    )

-- 1 row/agent/connection
select
    o.agent_id
    ,utvoo.created_date
from
    src_tc_transaction_transactly_vendor_member_notified ttvmn
    join src_tc_member m on m.member_id = ttvmn.member_id
    join src_tc_transaction_transactly_vendor ttv on ttvmn.transaction_transactly_vendor_id = ttv.transaction_transactly_vendor_id
    join src_tc_transactly_vendor tv on ttv.transactly_vendor_id = tv.vendor_id
    join src_tc_transaction t on m.transaction_id = t.transaction_id
    join src_tc_order o
        on t.transaction_id = o.transaction_id
        and o.transaction_id is not null
    left join src_tc_user_transactly_vendor_opt_out utvoo on utvoo.user_id = o.agent_id
where tv.vendor_type_id = 10