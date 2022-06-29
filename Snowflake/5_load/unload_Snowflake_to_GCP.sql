
---------------------------------------------------------------------------------------------------
-- unload to GCP
-- https://docs.snowflake.com/en/user-guide-data-unload.html
-- https://docs.snowflake.com/en/sql-reference/sql/copy-into-location.html#retaining-null-empty-field-data-in-unloaded-files


copy into @GCP_stage/GCP_fact_order from dimensional.GCP_fact_order overwrite = True;

-- views
copy into @GCP_stage/vw_order_line_item 
    from(
        select
            o_create_date.date_id as order_created_date
            ,t_create_date.date_id as transaction_created_date
            ,t_close_date.date_id as transaction_closed_date
            ,o.order_type
            ,o.order_status
            ,o.state as order_state
            ,u.first_name
            ,u.last_name
            ,u.full_name
            ,u.license_state
            ,u.brokerage
            ,cast(fact.agent_pays as number) as agent_pays
            ,cast(fact.price as number) as transaction_price
            ,datediff(d, o_create_date.date_id, t_create_date.date_id) as order_transact_start_lag
        from
            fact_order_line_item fact
            join dim_order o on fact.order_pk = o.order_pk
            join dim_transaction t on fact.transaction_pk = t.transaction_pk
            join dim_user u on fact.user_pk = u.user_pk
            join dim_line_item i on fact.line_item_pk = i.line_item_pk
            join dim_date o_create_date on fact.order_created_date_pk = o_create_date.date_pk
            join dim_date t_create_date on fact.transaction_created_date_pk = t_create_date.date_pk
            join dim_date t_close_date on fact.transaction_closed_date_pk = t_close_date.date_pk
    )
    overwrite = true
;


-- view stage
-- show stages;
-- list @gcp_stage;