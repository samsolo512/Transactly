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
                ,line.due_date
                ,o.closed_date
                ,u.user_id as assigned_tc_id
                ,u.fullname as assigned_tc_name
                ,o.order_type
                ,o.order_side
                ,o.created_date
                ,o.order_id
                ,o.transaction_id
                ,line.paid
                ,client.pays_at_title
                ,line.tc_paid
                ,line.cancelled_date as date_cancelled
                -- brokerage growth manager/ company id  (prob from Hubspot)

                -- client data
                ,client.user_id as client_id
                ,u.brokerage as client_brokerage
                ,client.tier_1 as tier_1_date  -- due date of 5th sale
                ,client.tier_2 as tier_2_date  -- due date of 1st sale
                ,client.tier_3 as tier_3_date  -- user created date
                ,client.first_order_placed as date_first_order_placed
                ,client.first_order_closed as date_first_order_closed
                ,client.last_order_placed as date_last_order_placed
                ,client.last_order_due
                ,client.fifth_order_closed as date_5th_order_closed
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