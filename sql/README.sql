\pset tuples_only
\pset format unaligned

begin;

create schema ext;

create extension pg_html5_email_address
    with schema ext
    cascade;

select ext.pg_html5_email_address_readme();

rollback;
