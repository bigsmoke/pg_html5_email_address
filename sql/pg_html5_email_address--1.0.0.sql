-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION pg_html5_email_address" to load this file. \quit

--------------------------------------------------------------------------------------------------------------

comment on extension pg_html5_email_address is
$markdown$
# The `pg_html5_email_address` PostgreSQL extension

`pg_html5_email_address` is a tiny PostgreSQL extension that offers email address validation that is consistent with the [`<input type="email">`](https://html.spec.whatwg.org/multipage/input.html#e-mail-state-(type=email)) validation in HTML5.

## HTML5 email validation

When it comes to determining what a [valid email address](https://html.spec.whatwg.org/multipage/input.html#valid-e-mail-address) is, the HTML5 specification makes more sense than [RFC 5322](https://www.rfc-editor.org/rfc/rfc5322), “which [according to the HTML5 spec writers] defines a syntax for email addresses that is simultaneously too strict (before the "@" character), too vague (after the "@" character), and too lax (allowing comments, whitespace characters, and quoted strings in manners unfamiliar to most users) to be of practical use here.”

Evan Carroll, in [response](https://dba.stackexchange.com/a/165923/79909) to a Stack Exchange question on what is the best way to store an email address in PostgreSQL, goes a bit deeper:

> The spec for an email address is so complex, it's not even self-contained. Complex is truly an understatement, [those making the spec don't even understand it](https://www.rfc-editor.org/errata_search.php?rfc=3696&eid=1690). From the docs on regular-expression.info:
>
> > Neither of these regexes enforce length limits on the overall email address or the local part or the domain names. RFC 5322 does not specify any length limitations. Those stem from limitations in other protocols like the SMTP protocol for actually sending email. RFC 1035 does state that domains must be 63 characters or less, but does not include that in its syntax specification. The reason is that a true regular language cannot enforce a length limit and disallow consecutive hyphens at the same time.

Apart from RFC 5322 its simultaneous too-looseness and not-loose-enoughness, sticking with HTML5 is a good idea simply to be consistent with the uniquitous HTML5, especially if you're dealing with a PostgreSQL backend—[PostgREST](https://postgrest.org/)-powered I so hope for you—with a HTML5 front.

If you have an irrational fear of reading W3C specs (and I do urge you to get over that fear), MDN, as usual, also has a most excellent write-up about HTML5 email address validation: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/email#validation

Finally there is the question of Unicode: are non-ASCII characters allowed in HTML5 email addresses. The HTML5 spec is unclear about this, but domain names definitely can (and often _do_) contain non-ASCII characters, and, since [RFC 6532](https://www.rfc-editor.org/rfc/rfc6532), this is also formally allowed in email addresses.

## Reference

<?pg-readme-reference ?>

## `pg_html5_email_address` raison d'etre

The author of `pg_html5_email_address`—Rowan—deemed it useful to split off this tiny extension from the PostgreSQL backend of the [FlashMQ SaaS MQTT hosting service](https://www.flashmq.com/).  Even though the objects in this extension almost seem too insignificant to justify an extension, Rowan couldn't think of any other extension to put this in.  And there really is no lower limit to how small PostgreSQL extensions may be.

## Authors & contributors

* Rowan Rodrik van der Molen

<?pg-readme-colophon?>
$markdown$;

--------------------------------------------------------------------------------------------------------------

create collation if not exists html5_email_ci (
    provider = 'icu',
    locale = '@colStrength=secondary',
    deterministic = false
);

comment on collation html5_email_ci is
$markdown$A collation for case-insensitive email address comparisons.

RFC 5322 says that the local part of email addresses may be treated case sensitively, but this is widely ignored, and even according to the same spec not a great idea for portability.  Therefore, let's ignore case.

Accents are _not_ ignored by this collation. Ignoring accents requires _primary strength_, whereas this collation is defined as `@colStrength=secondary`.  See Daniel Verite his excellent blog post about [PostgreSQL non-deterministic collations](https://postgresql.verite.pro/blog/2019/10/14/nondeterministic-collations.html) for further exploration of this topic:
$markdown$;

--------------------------------------------------------------------------------------------------------------

create function html5_email_regexp(with_capturing_groups$ bool default false)
    returns text
    immutable
    leakproof
    parallel safe
    set pg_readme.include_this_routine_definition to true
    language sql
    return $re$(?x)
^
($re$ || case when with_capturing_groups$ then '' else '?:' end || $re$
  [[:word:]0-9.!#$%&''*+/=?^_`{|}~-]+
)
@
($re$ || case when with_capturing_groups$ then '' else '?:' end || $re$
  [[:word:]0-9](?:[[:word:]0-9-]{0,61}[[:word:]0-9])?
  (?:[.][[:word:]0-9](?:[[:word:]0-9-]{0,61}[[:word:]0-9])?)*
)
$
$re$;

comment on function html5_email_regexp(bool) is
$markdown$Returns a regular expression that matches email addresses which the HTML5 spec would consider valid.

The optional boolean argument puts capturing groups around both the local (before the ‘@’) and the server part.  (Anything more sophisticated than that can only apply to a narrow band of _valid_ email addresses.  See the [_HTML5 email validation_](#html5-email-validation) section of this readme for details about why this is so.)
$markdown$;

--------------------------------------------------------------------------------------------------------------

create domain html5_email
    as text collate html5_email_ci
    check (
        value is null
        or value ~ html5_email_regexp()
    );

comment on domain html5_email is
$markdown$The `html5_email` domain type enforces that the underlying `text` value conforms to the HTML 5 validation rules for email addresses.

See the [_HTML5 email validation_](#html5-email-validation) section of this readme for details.
$markdown$;

--------------------------------------------------------------------------------------------------------------

create procedure test__pg_html5_email_address()
    set pg_readme.include_this_routine_definition to true
    set plpgsql.check_asserts to true
    language plpgsql
as $$
declare
    _invalid_email text;
begin
    assert '#Rowan.de.man+Nelia-de~vrouw=$couple!@localhost' ~ html5_email_regexp(),
        'Yes, email addresses can contain all that, and more!';

    assert 'Rowan @example.com' !~ html5_email_regexp(),
        'But spaces are out of the question.';

    assert 'Rowan@' !~ html5_email_regexp(),
        'And there has to be _something_ behind the ‘@’';

    assert 'Rowan@A' ~ html5_email_regexp(),
        'Even if it''s just one character.';

    assert 'Rowan@1' ~ html5_email_regexp(),
        'Yes, even if it''s just a number.';

    assert 'Rówan@example.com' !~ html5_email_regexp(),
        'Accents and other non-ASCII characters are not allowed in the local part.';

    assert 'Rowan@éxamplé.com' !~ html5_email_regexp(),
        'Nor are non-ASCII Unicode characters allowed in the domain part.';

    begin
        select 'rowan @example.com'::html5_email;
        raise assert_failure
            using message = '`''rowan @example.com''::html5_email` cast should have raised a `check_violation`.';
    exception
        when check_violation then
    end;

    assert 'Rowan@example.com'::html5_email = 'rowan@example.com'::html5_email,
        'The case-insensitive collation of the "html5_email" domain should have made ''Rowan@example.com'''
        ' and ''rowan@example.com'' count as equal.';

    assert (regexp_matches('Rowan.de.man@example.com', html5_email_regexp(true)))[1] = 'Rowan.de.man';
    assert (regexp_matches('Rowan.de.man@example.com', html5_email_regexp(true)))[2] = 'example.com';
end;
$$;

comment on procedure test__pg_html5_email_address() is
$markdown$Tests the objects belonging to the `pg_html5_email_address` Postgres extension.

The routine name is compliant with the `pg_tst` extension.  An intentional choice has been made to not _depend_ on the `pg_tst` extension its test runner or developer-friendly assertions to keep the number of inter-extension dependencies to a minimum.
$markdown$;

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
        ,'gpl_3'
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

comment on function pg_html5_email_address_meta_pgxn() is
$md$Returns the JSON meta data that has to go into the `META.json` file needed for [PGXN—PostgreSQL Extension Network](https://pgxn.org/) packages.

The `Makefile` includes a recipe to allow the developer to: `make META.json` to
refresh the meta file with the function's current output, including the
`default_version`.

And indeed, `pg_html5_email_address` can be found on PGXN:
https://pgxn.org/dist/pg_html5_email_address/
$md$;

--------------------------------------------------------------------------------------------------------------

create or replace function pg_html5_email_address_readme()
    returns text
    volatile
    set search_path from current
    set pg_readme.include_view_definitions_like to 'true'
    set pg_readme.include_routine_definitions_like to '{test__%}'
    language plpgsql
    as $plpgsql$
declare
    _readme text;
begin
    create extension if not exists pg_readme;

    _readme := pg_extension_readme('pg_html5_email_address'::name);

    raise transaction_rollback;  -- to drop extension if we happened to `CREATE EXTENSION` for just this.
exception
    when transaction_rollback then
        return _readme;
end;
$plpgsql$;

-- Add previously missing comment.
comment
    on function pg_html5_email_address_readme()
    is $markdown$Generates the text for a `README.md` in Markdown format using the amazing power of the `pg_readme` extension.

This function temporarily installs `pg_readme` if it is not already installed in the current database.
$markdown$;

--------------------------------------------------------------------------------------------------------------
