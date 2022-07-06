-- https://github.com/dbt-labs/dbt-snowflake/issues/169

{% macro unload_data_to_GCP() %}

{% call statement('load_GCP_fact_order', fetch_result=true, auto_begin=true) %}

    -- begin;
        copy into @GCP_stage/GCP_fact_order
        from(
            select
                -- status (complete, tc paid)
                o.address
                ,o.state
                ,line.description
                ,line.agent_pays as agent_pays_amt
                ,line.office_pays as office_pays_amt
                ,u.user_id as assigned_tc_id
                ,u.fullname as assigned_tc_name
                ,o.order_type
                ,o.order_side
                ,o.order_id
                ,o.transaction_id
                ,line.paid
                ,client.pays_at_title
                ,line.tc_paid
                ,client.user_id as client_id
                ,client.fullname
                ,client.brokerage as client_brokerage
                ,client.tier_1 as tier_1_date  -- due date of 5th sale
                ,client.tier_2 as tier_2_date  -- due date of 1st sale
                ,client.tier_3 as tier_3_date  -- user created date
                ,o.created_date
                ,line.due_date
                ,o.closed_date
                ,line.cancelled_date as cancelled_date
                -- brokerage growth manager/ company id  (prob from Hubspot)
                ,client.last_order_placed as last_order_placed_date
                ,client.last_order_due as last_order_due_date
                ,client.first_order_placed as first_order_placed_date
                ,client.first_order_closed as first_order_closed_date
                ,client.fifth_order_closed as fifth_order_closed_date
            //    ,agent.tc_is_tc_client as tc_client_flag

            from
                fact_order fact
            //    join dim_agent agent on fact.agent_pk = agent.agent_pk
                join dim_line_item line on fact.line_item_pk = line.line_item_pk
                left join dim_client client on fact.client_pk = client.client_pk
                left join dim_order o on fact.order_pk = o.order_pk
                left join dim_user u on fact.assigned_tc_pk = u.user_pk
                left join dim_date line_item_created_date on fact.created_date_pk = line_item_created_date.date_pk
                left join dim_date line_item_due_date on fact.created_date_pk = line_item_due_date.date_pk
                left join dim_date line_item_cancelled_date on fact.created_date_pk = line_item_cancelled_date.date_pk
                left join dim_date closed_date on cast(fact.closed_date_pk as date) = closed_date.date_id
        )
        overwrite = true
        single = true;
    -- commit;

{% endcall %}

{% endmacro %}

-- dbt run-operation unload_data_to_GCP