begin;

create extension pg_html5_email_address cascade;

call test__pg_html5_email_address();

rollback;
