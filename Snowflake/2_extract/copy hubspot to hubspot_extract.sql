-- create multiple copy statements
select concat('create or replace table hubspot_extract.v2_daily.', table_name, ' as select * from hubspot.v2_daily.', table_name, ';')
from hubspot.information_schema.tables
where table_schema in('V2_DAILY')
;


-- copy statements
create or replace table hubspot_extract.v2_daily.ASSOCIATIONS as select * from hubspot.v2_daily.ASSOCIATIONS;
create or replace table hubspot_extract.v2_daily.ASSOCIATION_DEFINITIONS as select * from hubspot.v2_daily.ASSOCIATION_DEFINITIONS;
-- create or replace table hubspot_extract.v2_daily.EVENTS_AD_CLICKED as select * from hubspot.v2_daily.EVENTS_AD_CLICKED;
create or replace table hubspot_extract.v2_daily.EVENTS_AD_METRICS_IMPORTED_V0 as select * from hubspot.v2_daily.EVENTS_AD_METRICS_IMPORTED_V0;
create or replace table hubspot_extract.v2_daily.EVENTS_CALL_MENTIONED_KEYWORD as select * from hubspot.v2_daily.EVENTS_CALL_MENTIONED_KEYWORD;
create or replace table hubspot_extract.v2_daily.EVENTS_CLICKED_LINK_IN_EMAIL_V2 as select * from hubspot.v2_daily.EVENTS_CLICKED_LINK_IN_EMAIL_V2;
create or replace table hubspot_extract.v2_daily.EVENTS_CLICKED_LINK_IN_TRACKED_INBOX_EMAIL_V8 as select * from hubspot.v2_daily.EVENTS_CLICKED_LINK_IN_TRACKED_INBOX_EMAIL_V8;
create or replace table hubspot_extract.v2_daily.EVENTS_COOKIE_BANNER_CLICKED as select * from hubspot.v2_daily.EVENTS_COOKIE_BANNER_CLICKED;
create or replace table hubspot_extract.v2_daily.EVENTS_COOKIE_BANNER_VIEWED as select * from hubspot.v2_daily.EVENTS_COOKIE_BANNER_VIEWED;
create or replace table hubspot_extract.v2_daily.EVENTS_DOCUMENT_COMPLETED_V2 as select * from hubspot.v2_daily.EVENTS_DOCUMENT_COMPLETED_V2;
create or replace table hubspot_extract.v2_daily.EVENTS_DOCUMENT_SHARED_V2 as select * from hubspot.v2_daily.EVENTS_DOCUMENT_SHARED_V2;
create or replace table hubspot_extract.v2_daily.EVENTS_DOCUMENT_VIEWED_V2 as select * from hubspot.v2_daily.EVENTS_DOCUMENT_VIEWED_V2;
create or replace table hubspot_extract.v2_daily.EVENTS_HS_SCHEDULED_EMAIL_V2 as select * from hubspot.v2_daily.EVENTS_HS_SCHEDULED_EMAIL_V2;
create or replace table hubspot_extract.v2_daily.EVENTS_MB_MEDIA_PLAYED as select * from hubspot.v2_daily.EVENTS_MB_MEDIA_PLAYED;
create or replace table hubspot_extract.v2_daily.EVENTS_MTA_BOUNCED_EMAIL_V2 as select * from hubspot.v2_daily.EVENTS_MTA_BOUNCED_EMAIL_V2;
create or replace table hubspot_extract.v2_daily.EVENTS_MTA_DELIVERED_EMAIL_V2 as select * from hubspot.v2_daily.EVENTS_MTA_DELIVERED_EMAIL_V2;
create or replace table hubspot_extract.v2_daily.EVENTS_OPENED_EMAIL_V2 as select * from hubspot.v2_daily.EVENTS_OPENED_EMAIL_V2;
create or replace table hubspot_extract.v2_daily.EVENTS_OPENED_TRACKED_INBOX_EMAIL_V8 as select * from hubspot.v2_daily.EVENTS_OPENED_TRACKED_INBOX_EMAIL_V8;
create or replace table hubspot_extract.v2_daily.EVENTS_REPORTED_SPAM_EMAIL_V2 as select * from hubspot.v2_daily.EVENTS_REPORTED_SPAM_EMAIL_V2;
create or replace table hubspot_extract.v2_daily.EVENTS_SOCIAL_MEDIA_FLOW___BASIC as select * from hubspot.v2_daily.EVENTS_SOCIAL_MEDIA_FLOW___BASIC;
create or replace table hubspot_extract.v2_daily.EVENTS_SOCIAL_MEDIA_FLOW___EMAIL as select * from hubspot.v2_daily.EVENTS_SOCIAL_MEDIA_FLOW___EMAIL;
create or replace table hubspot_extract.v2_daily.EVENTS_SOCIAL_MEDIA_FLOW___EMAIL_VERIFICATION as select * from hubspot.v2_daily.EVENTS_SOCIAL_MEDIA_FLOW___EMAIL_VERIFICATION;
create or replace table hubspot_extract.v2_daily.EVENTS_SOCIAL_MEDIA_FLOW___FIRST_NAME as select * from hubspot.v2_daily.EVENTS_SOCIAL_MEDIA_FLOW___FIRST_NAME;
create or replace table hubspot_extract.v2_daily.EVENTS_SOCIAL_MEDIA_FLOW___LAST_NAME as select * from hubspot.v2_daily.EVENTS_SOCIAL_MEDIA_FLOW___LAST_NAME;
create or replace table hubspot_extract.v2_daily.EVENTS_SOCIAL_MEDIA_FLOW___PHONE_NUMBER as select * from hubspot.v2_daily.EVENTS_SOCIAL_MEDIA_FLOW___PHONE_NUMBER;
create or replace table hubspot_extract.v2_daily.EVENTS_SOCIAL_MEDIA_FLOW___PHONE_VERIFICATION as select * from hubspot.v2_daily.EVENTS_SOCIAL_MEDIA_FLOW___PHONE_VERIFICATION;
create or replace table hubspot_extract.v2_daily.EVENTS_SOCIAL_MEDIA_FLOW___PRO as select * from hubspot.v2_daily.EVENTS_SOCIAL_MEDIA_FLOW___PRO;
create or replace table hubspot_extract.v2_daily.EVENTS_SOCIAL_MEDIA_FLOW___SIGN_UP_CONTINUE as select * from hubspot.v2_daily.EVENTS_SOCIAL_MEDIA_FLOW___SIGN_UP_CONTINUE;
create or replace table hubspot_extract.v2_daily.EVENTS_UPDATED_EMAIL_SUBSCRIPTION_STATUS_V2 as select * from hubspot.v2_daily.EVENTS_UPDATED_EMAIL_SUBSCRIPTION_STATUS_V2;
create or replace table hubspot_extract.v2_daily.EVENTS_V2_CONTACT_BOOKED_MEETING_THROUGH_SEQUENCE as select * from hubspot.v2_daily.EVENTS_V2_CONTACT_BOOKED_MEETING_THROUGH_SEQUENCE;
create or replace table hubspot_extract.v2_daily.EVENTS_V2_CONTACT_ENROLLED_IN_SEQUENCE as select * from hubspot.v2_daily.EVENTS_V2_CONTACT_ENROLLED_IN_SEQUENCE;
create or replace table hubspot_extract.v2_daily.EVENTS_V2_CONTACT_FINISHED_SEQUENCE as select * from hubspot.v2_daily.EVENTS_V2_CONTACT_FINISHED_SEQUENCE;
create or replace table hubspot_extract.v2_daily.EVENTS_V2_CONTACT_REPLIED_SEQUENCE_EMAIL as select * from hubspot.v2_daily.EVENTS_V2_CONTACT_REPLIED_SEQUENCE_EMAIL;
create or replace table hubspot_extract.v2_daily.EVENTS_V2_CONTACT_UNENROLLED_FROM_SEQUENCE as select * from hubspot.v2_daily.EVENTS_V2_CONTACT_UNENROLLED_FROM_SEQUENCE;
create or replace table hubspot_extract.v2_daily.EVENTS_V2_CONTACT_UNENROLLED_MANUALLY_FROM_SEQUENCE as select * from hubspot.v2_daily.EVENTS_V2_CONTACT_UNENROLLED_MANUALLY_FROM_SEQUENCE;
create or replace table hubspot_extract.v2_daily.EVENTS_V2_CONTACT_UNSUBSCRIBED_SEQUENCE_EMAIL as select * from hubspot.v2_daily.EVENTS_V2_CONTACT_UNSUBSCRIBED_SEQUENCE_EMAIL;
create or replace table hubspot_extract.v2_daily.EVENTS_V2_SEQUENCE_EMAIL_BOUNCED as select * from hubspot.v2_daily.EVENTS_V2_SEQUENCE_EMAIL_BOUNCED;
create or replace table hubspot_extract.v2_daily.EVENTS_V2_SEQUENCE_ERRORED as select * from hubspot.v2_daily.EVENTS_V2_SEQUENCE_ERRORED;
create or replace table hubspot_extract.v2_daily.EVENTS_V2_SEQUENCE_STEP_EXECUTED as select * from hubspot.v2_daily.EVENTS_V2_SEQUENCE_STEP_EXECUTED;
create or replace table hubspot_extract.v2_daily.EVENTS_VISITED_PAGE as select * from hubspot.v2_daily.EVENTS_VISITED_PAGE;
create or replace table hubspot_extract.v2_daily.LISTS as select * from hubspot.v2_daily.LISTS;
create or replace table hubspot_extract.v2_daily.LIST_MEMBERSHIPS as select * from hubspot.v2_daily.LIST_MEMBERSHIPS;
create or replace table hubspot_extract.v2_daily.OBJECTS as select * from hubspot.v2_daily.OBJECTS;
create or replace table hubspot_extract.v2_daily.OBJECT_AND_EVENT_TYPE_DEFINITIONS as select * from hubspot.v2_daily.OBJECT_AND_EVENT_TYPE_DEFINITIONS;
create or replace table hubspot_extract.v2_daily.OBJECT_PROPERTIES as select * from hubspot.v2_daily.OBJECT_PROPERTIES;
create or replace table hubspot_extract.v2_daily.OBJECT_WITH_OBJECT_PROPERTIES as select * from hubspot.v2_daily.OBJECT_WITH_OBJECT_PROPERTIES;
create or replace table hubspot_extract.v2_daily.OWNERS as select * from hubspot.v2_daily.OWNERS;
create or replace table hubspot_extract.v2_daily.PIPELINES as select * from hubspot.v2_daily.PIPELINES;
create or replace table hubspot_extract.v2_daily.PIPELINE_STAGES as select * from hubspot.v2_daily.PIPELINE_STAGES;
create or replace table hubspot_extract.v2_daily.PROPERTY_DEFINITIONS as select * from hubspot.v2_daily.PROPERTY_DEFINITIONS;

