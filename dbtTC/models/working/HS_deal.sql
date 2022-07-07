with object_properties as(
    select *
    from {{ ref('src_hs_object_properties') }}
)

select
    hs_object_id as deal_id
    ,dealname as deal_name
    ,deal_value
    ,subscription_type
    ,hs_projected_amount as projected_amount
    ,to_timestamp(hs_lastmodifieddate) as last_modified_date

from(

    select
        objectid
        ,name
        ,value
    from object_properties
    where
        objecttypeid = '0-3'
        and name in(
            'hs_object_id'  -- deal id
            ,'dealname'
            ,'deal_value'
            ,'subscription_type'
            ,'hs_projected_amount'
            ,'hs_lastmodifieddate'
        )
)

pivot(
    max(value) for name in(
        'dealname'
        ,'deal_value'
        ,'subscription_type'
        ,'hs_projected_amount'
        ,'hs_lastmodifieddate'
    )
)
as p(
    hs_object_id
    ,dealname
    ,deal_value
    ,subscription_type
    ,hs_projected_amount
    ,hs_lastmodifieddate
)
