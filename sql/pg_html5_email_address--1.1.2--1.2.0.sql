-- Complain if script is sourced in `psql`, rather than via `CREATE EXTENSION`
\echo Use "CREATE EXTENSION pg_html5_email_address" to load this file. \quit

--------------------------------------------------------------------------------------------------------------

create or replace function pg_html5_email_address_meta_pgxn()
    returns jsonb
    stable
    language sql
    return jsonb_build_object(
        'name'
        ,'pg_html5_email_address'
        ,'abstract'
        ,'Email validation that is consistent with the HTML5 spec.'
        ,'description'
        ,'pg_html5_email_address is a tiny PostgreSQL extension that offers email address validation that is'
         'consistent with the <input type="email"> validation from the HTML5 spec.'
        ,'version'
        ,(
            select
                pg_extension.extversion
            from
                pg_catalog.pg_extension
            where
                pg_extension.extname = 'pg_html5_email_address'
        )
        ,'maintainer'
        ,array[
            'Rowan Rodrik van der Molen <rowan@bigsmoke.us>'
        ]
        ,'license'
        ,'postgresql'
        ,'prereqs'
        ,'{
            "test": {
                "requires": {
                    "pgtap": 0
                }
            },
            "develop": {
                "recommends": {
                    "pg_readme": 0
                }
            }
        }'::jsonb
        ,'provides'
        ,('{
            "pg_html5_email_address": {
                "file": "pg_html5_email_address--1.0.0.sql",
                "version": "' || (
                    select
                        pg_extension.extversion
                    from
                        pg_catalog.pg_extension
                    where
                        pg_extension.extname = 'pg_html5_email_address'
                ) || '",
                "docfile": "README.md"
            }
        }')::jsonb
        ,'resources'
        ,'{
            "homepage": "https://blog.bigsmoke.us/tag/pg_html5_email_address",
            "bugtracker": {
                "web": "https://github.com/bigsmoke/pg_html5_email_address/issues"
            },
            "repository": {
                "url": "https://github.com/bigsmoke/pg_html5_email_address.git",
                "web": "https://github.com/bigsmoke/pg_html5_email_address",
                "type": "git"
            }
        }'::jsonb
        ,'meta-spec'
        ,'{
            "version": "1.0.0",
            "url": "https://pgxn.org/spec/"
        }'::jsonb
        ,'generated_by'
        ,'`select pg_html5_email_address_meta_pgxn()`'
        ,'tags'
        ,array[
            'domain',
            'email',
            'html5',
            'plpgsql',
            'type',
            'validation'
        ]
    );

--------------------------------------------------------------------------------------------------------------
