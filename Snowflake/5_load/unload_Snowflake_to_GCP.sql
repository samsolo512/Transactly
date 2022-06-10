
---------------------------------------------------------------------------------------------------
-- unload to GCP
-- https://docs.snowflake.com/en/user-guide-data-unload.html
-- https://docs.snowflake.com/en/sql-reference/sql/copy-into-location.html#retaining-null-empty-field-data-in-unloaded-files

-- dims
copy into @GCP_stage/dim_date from dimensional.dim_date overwrite = True;
copy into @GCP_stage/dim_line_item from dimensional.dim_line_item overwrite = True;
copy into @GCP_stage/dim_order from dimensional.dim_order overwrite = True;
copy into @GCP_stage/dim_transaction from dimensional.dim_transaction overwrite = True;
copy into @GCP_stage/dim_user from dimensional.dim_user overwrite = True;

-- facts
copy into @GCP_stage/fact_order_line_item from dimensional.fact_order_line_item overwrite = True;
copy into @GCP_stage/fact_user_month from dimensional.fact_user_month overwrite = True;

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