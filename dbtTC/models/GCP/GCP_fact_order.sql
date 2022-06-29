with
    fact_order as(
        select *
        from {{ ref('fact_order') }}
    )

    ,dim_agent as(
        select *
        from {{ ref('dim_agent') }}
    )

    ,dim_line_item as(
        select *
        from {{ ref('dim_line_item') }}
    )

    ,dim_date as(
        select *
        from {{ ref('dim_date') }}
    )

select
    line.description as fee_type
    ,agent.tc_is_tc_client as tc_client_flag
    --,first_order_placed_flag
    --,tier
    ,fact.*
from
    fact_order fact
    join dim_agent agent on fact.agent_pk = agent.agent_pk
    join dim_line_item line on fact.line_item_pk = line.line_item_pk
    left join dim_date line_item_created_date on fact.created_date_pk = line_item_created_date.date_pk
    left join dim_date line_item_due_date on fact.created_date_pk = line_item_due_date.date_pk
    left join dim_date line_item_cancelled_date on fact.created_date_pk = line_item_cancelled_date.date_pk
    left join dim_date closed_date on cast(fact.closed_date_pk as date) = closed_date.date_id
