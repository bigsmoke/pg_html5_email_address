\pset tuples_only
\pset format unaligned

begin;

create extension pg_html5_email_address
    cascade;

select jsonb_pretty(pg_html5_email_address_meta_pgxn());

rollback;
