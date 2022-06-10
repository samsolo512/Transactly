------------------------------------------------------------------------------------------------------------------------
-- Brokerage MLS to Hubspot

-- with hubspot_orig as(
-- create or replace table dev.working.mls_hubspot_listing as

select
    jarowinkler_similarity(
        concat(
            trim(lower(ofs.officename))
            ,trim(lower(ofs.officecity))
            ,trim(lower(ofs.stateorprovince))
        )
        ,concat(
            trim(lower(hb.company_name))
            ,trim(lower(hb.city))
            ,trim(lower(hb.state))
        )
    ) pct_similar
    ,editdistance(trim(lower(ofs.officename)), trim(lower(hb.company_name))) name_distance

    ,ofs.officeName as MLS_name
    ,hb.company_name as Hubspot_name
    ,hb.company_id as Hubspot_company_id
    ,ofs.mlsid as MLS_ID
    ,ofs.source as MLS_source
    ,hb.mls_id as Hubspot_MLS_id
    ,hb.mls_system_name as Hubspot_MLS_System_name

    ,ofs.url as MLS_url
    ,hb.website_url as Hubspot_url

    ,case
        when left(regexp_replace(ofs.phone, '[^0-9]'), 1) = '1'
        then ltrim(regexp_replace(ofs.phone, '[^0-9]'), 1)
        else regexp_replace(ofs.phone, '[^0-9]')
        end as MLS_phone
    ,case
        when left(regexp_replace(hb.phone_number, '[^0-9]'), 1) = '1'
        then ltrim(regexp_replace(hb.phone_number, '[^0-9]'), 1)
        else regexp_replace(hb.phone_number, '[^0-9]')
        end as Hubspot_phone

    ,ofs.officeAddress as MLS_street
    ,concat(hb.street_address_1, ' ', hb.street_address_2) as Hubspot_street

    ,ofs.officeCity as MLS_city
    ,hb.city as Hubspot_city

    ,ofs.stateOrProvince as MLS_state
    ,hb.state as Hubspot_state

    ,ofs.postalCode as MLS_zip
    ,hb.postal_code as Hubspot_zip

from
--     dev.working.hubspot_brokerages hb
    dev.working.mls_hubspot_brokerage hb
    left join dev.dimensional.dim_brokerage ofs

where
    -- when the mls id's match exactly
    ofs.mlsid = hb.mls_id

    -- individual combination of name, state, office, city, and zip matches
    or(
        jarowinkler_similarity(trim(lower(ofs.stateorprovince)), trim(lower(hb.state))) >= 90
        and jarowinkler_similarity(trim(lower(ofs.officename)), trim(lower(hb.company_name))) >= 90
        and jarowinkler_similarity(trim(lower(ofs.officecity)), trim(lower(hb.city))) >= 94
        and jarowinkler_similarity(
            trim(lower(regexp_replace(ofs.postalcode, '[^0-9]'))),
            trim(lower(regexp_replace(hb.postal_code, '[^0-9]')))
        ) = 100
    )

    -- concatenated name, city, state are similar and the zip codes match
    or(
        jarowinkler_similarity(
            concat(
                trim(lower(ofs.officename))
                ,trim(lower(ofs.officecity))
                ,trim(lower(ofs.stateorprovince))
            )
            ,concat(
                trim(lower(hb.company_name))
                ,trim(lower(hb.city))
                ,trim(lower(hb.state))
            )
        ) >= 90
        and jarowinkler_similarity(
                trim(lower(regexp_replace(ofs.postalcode, '[^0-9]'))),
                trim(lower(regexp_replace(hb.postal_code, '[^0-9]')))
        ) = 100
    )

    -- the websites are similar
    or jarowinkler_similarity(trim(lower(ofs.url)), trim(lower(hb.website_url))) >= 98

    -- the phone numbers match and the zip codes match
    or (
        case
            when left(regexp_replace(ofs.phone, '[^0-9]'), 1) = '1'
                then ltrim(regexp_replace(ofs.phone, '[^0-9]'), 1)
            else regexp_replace(ofs.phone, '[^0-9]')
            end =
        case
            when left(regexp_replace(hb.phone_number, '[^0-9]'), 1) = '1'
                then ltrim(regexp_replace(hb.phone_number, '[^0-9]'), 1)
            else regexp_replace(hb.phone_number, '[^0-9]')
            end
        and jarowinkler_similarity(
                trim(lower(regexp_replace(ofs.postalcode, '[^0-9]'))),
                trim(lower(regexp_replace(hb.postal_code, '[^0-9]')))
        ) = 100
    )

order by 1 desc nulls last, 2 desc nulls last
-- )
--
-- select *
-- from
--     working.hubspot_brokerages hb
--     left join hubspot_orig ho on hb.company_name = ho.Hubspot_name
-- where
--     ho.Hubspot_name is null
;







------------------------------------------------------------------------------------------------------------------------
-- Agent MLS to Hubspot

select
    jarowinkler_similarity(
        concat(
            trim(lower(agt.fullname))
            ,trim(lower(agt.agentcity))
            ,trim(lower(agt.agentstate))
        )
        ,concat(
            trim(lower(concat(hb.first_name, ' ', hb.last_name)))
            ,trim(lower(hb.city))
            ,trim(lower(hb.state_province))
        )
    ) pct_similar
    ,editdistance(trim(lower(agt.fullname)), trim(lower(concat(hb.first_name, ' ', hb.last_name)))) name_distance

    ,agt.agentMLSID
    ,agt.source as MLS_source
    ,agt.mainOfficeMLSID
    ,agt.officeMLSID
    ,agt.brokerMLSID

     ,hb.contact_id as Hubspot_contact_id

     ,agt.fullname as MLS_fullname
     ,concat(hb.first_name, ' ', hb.last_name) as Hubspot_fullname

    ,agt.agentemail as MLS_email
    ,hb.email as Hubspot_email

    ,agt.agentcity as MLS_city
    ,hb.city as Hubspot_city

    ,agt.agentstate as MLS_state
    ,hb.state_province as Hubspot_state

    ,agt.agentzipcode as MLS_zip
    ,hb.zip as Hubspot_zip

    ,case
        when left(regexp_replace(agt.agentdirectphone, '[^0-9]'), 1) = '1'
        then ltrim(regexp_replace(agt.agentdirectphone, '[^0-9]'), 1)
        else regexp_replace(agt.agentdirectphone, '[^0-9]')
        end as agentdirectphone
    ,case
        when left(regexp_replace(agt.agentcellphone, '[^0-9]'), 1) = '1'
        then ltrim(regexp_replace(agt.agentcellphone, '[^0-9]'), 1)
        else regexp_replace(agt.agentcellphone, '[^0-9]')
        end as agentcellphone
    ,case
        when left(regexp_replace(hb.mobile_phone_number, '[^0-9]'), 1) = '1'
        then ltrim(regexp_replace(hb.mobile_phone_number, '[^0-9]'), 1)
        else regexp_replace(hb.mobile_phone_number, '[^0-9]')
        end as Hubspot_phone

from
    (select top 1000 * from dev.working.mls_hubspot_agent) hb
    left join dim_agent agt

where
    -- individual combination of name, state, city are similar and zip matches or is null
    (
        jarowinkler_similarity(trim(lower(agt.agentstate)), trim(lower(hb.state_province))) >= 94
        and jarowinkler_similarity(trim(lower(agt.fullname)), trim(lower(concat(hb.first_name, ' ', hb.last_name)))) >= 90
        and jarowinkler_similarity(trim(lower(agt.agentcity)), trim(lower(hb.city))) >= 94
        and(
            jarowinkler_similarity(
            trim(lower(regexp_replace(agt.agentzipcode, '[^0-9]'))),
            trim(lower(regexp_replace(hb.zip, '[^0-9]')))
            ) = 100
--             or agt.agentzipcode is null
--             or hb.zip is null
        )
    )

    -- concatenated name, city, state are similar and the zip matches or is null
    or(
        jarowinkler_similarity(
            concat(
                trim(lower(agt.fullname))
                ,trim(lower(agt.agentcity))
                ,trim(lower(agt.agentstate))
            )
            ,concat(
                trim(lower(concat(hb.first_name, ' ', hb.last_name)))
                ,trim(lower(hb.city))
                ,trim(lower(hb.state_province))
            )
        ) >= 95
        and(
            jarowinkler_similarity(
            trim(lower(regexp_replace(agt.agentzipcode, '[^0-9]'))),
            trim(lower(regexp_replace(hb.zip, '[^0-9]')))
            ) = 100
--             or agt.agentzipcode is null
--             or hb.zip is null
        )
    )

    -- emails are similar
    or jarowinkler_similarity(trim(lower(agt.agentemail)), trim(lower(hb.email))) >= 98

    -- phone numbers match and the zip codes match or are null
    or(
        (
            case
                when left(regexp_replace(agt.agentdirectphone, '[^0-9]'), 1) = '1' then ltrim(regexp_replace(agt.agentdirectphone, '[^0-9]'), 1)
                else regexp_replace(agt.agentdirectphone, '[^0-9]')
                end =
            case
                when left(regexp_replace(hb.mobile_phone_number, '[^0-9]'), 1) = '1' then ltrim(regexp_replace(hb.mobile_phone_number, '[^0-9]'), 1)
                else regexp_replace(hb.mobile_phone_number, '[^0-9]')
                end
            or
            case
                when left(regexp_replace(agt.agentcellphone, '[^0-9]'), 1) = '1' then ltrim(regexp_replace(agt.agentcellphone, '[^0-9]'), 1)
                else regexp_replace(agt.agentcellphone, '[^0-9]')
                end =
            case
                when left(regexp_replace(hb.mobile_phone_number, '[^0-9]'), 1) = '1' then ltrim(regexp_replace(hb.mobile_phone_number, '[^0-9]'), 1)
                else regexp_replace(hb.mobile_phone_number, '[^0-9]')
                end
--             or
--             case
--                 when left(regexp_replace(agt.agentofficephone, '[^0-9]'), 1) = '1' then ltrim(regexp_replace(agt.agentofficephone, '[^0-9]'), 1)
--                 else regexp_replace(agt.agentofficephone, '[^0-9]')
--                 end =
--             case
--                 when left(regexp_replace(hb.mobile_phone_number, '[^0-9]'), 1) = '1' then ltrim(regexp_replace(hb.mobile_phone_number, '[^0-9]'), 1)
--                 else regexp_replace(hb.mobile_phone_number, '[^0-9]')
--                 end
        )
        and(
            jarowinkler_similarity(
                trim(lower(regexp_replace(agt.agentzipcode, '[^0-9]')))
                , trim(lower(regexp_replace(hb.zip, '[^0-9]')))
            ) = 100
--             or agt.agentzipcode is null
--             or hb.zip is null
        )
    )

order by 1 desc nulls last, 2 desc nulls last
;