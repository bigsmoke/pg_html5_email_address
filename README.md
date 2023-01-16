---
pg_extension_name: pg_html5_email_address
pg_extension_version: 1.1.0
pg_readme_generated_at: 2023-01-16 16:26:23.934916+00
pg_readme_version: 0.4.0
---

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

Finally there is the question of Unicode: are non-ASCII characters allowed in HTML5 email addresses? The HTML5 spec is unclear about this, but domain names definitely can (and now occasionally _do_) contain non-ASCII characters, and, since [RFC 6532](https://www.rfc-editor.org/rfc/rfc6532), this seems to be also formally allowed in email addresses. But HTML5 goes its own way, as do the browser makers. As of 2023-01-16,

* WebKit does not allow unicode chacters in `<input type="email">` _at all_.
* Firefox allows unicode characters only in the domain part, not in the local part.
* Safari …

## Reference

## Object reference

### Routines

#### Function: `html5_email_regexp (boolean)`

Returns a regular expression that matches email addresses which the HTML5 spec would consider valid.

The optional boolean argument puts capturing groups around both the local (before the ‘@’) and the server part.  (Anything more sophisticated than that can only apply to a narrow band of _valid_ email addresses.  See the [_HTML5 email validation_](#html5-email-validation) section of this readme for details about why this is so.)

Function arguments:

| Arg. # | Arg. mode  | Argument name                                                     | Argument type                                                        | Default expression  |
| ------ | ---------- | ----------------------------------------------------------------- | -------------------------------------------------------------------- | ------------------- |
|   `$1` |       `IN` | `with_capturing_groups$`                                          | `boolean`                                                            | `false` |

Function return type: `text`

Function attributes: `IMMUTABLE`, `LEAKPROOF`, `PARALLEL SAFE`

Function-local settings:

  *  `SET pg_readme.include_this_routine_definition TO true`

```
CREATE OR REPLACE FUNCTION ext.html5_email_regexp("with_capturing_groups$" boolean DEFAULT false)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE LEAKPROOF
 SET "pg_readme.include_this_routine_definition" TO 'true'
RETURN (((('(?x)
^
('::text || CASE WHEN "with_capturing_groups$" THEN ''::text ELSE '?:'::text END) || '
  [a-zA-Z0-9.!#$%&''''*+/=?^_`{|}~-]+
)
@
('::text) || CASE WHEN "with_capturing_groups$" THEN ''::text ELSE '?:'::text END) || '
  [a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?
  (?:[.][a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*
)
$
'::text)
```

#### Function: `pg_html5_email_address_meta_pgxn ()`

Returns the JSON meta data that has to go into the `META.json` file needed for [PGXN—PostgreSQL Extension Network](https://pgxn.org/) packages.

The `Makefile` includes a recipe to allow the developer to: `make META.json` to
refresh the meta file with the function's current output, including the
`default_version`.

And indeed, `pg_html5_email_address` can be found on PGXN:
https://pgxn.org/dist/pg_html5_email_address/

Function return type: `jsonb`

Function attributes: `STABLE`

#### Function: `pg_html5_email_address_readme ()`

Generates the text for a `README.md` in Markdown format using the amazing power of the `pg_readme` extension.

This function temporarily installs `pg_readme` if it is not already installed in the current database.

Function return type: `text`

Function-local settings:

  *  `SET search_path TO ext, pg_temp`
  *  `SET pg_readme.include_view_definitions_like TO true`
  *  `SET pg_readme.include_routine_definitions_like TO {test__%}`

#### Procedure: `test__pg_html5_email_address ()`

Tests the objects belonging to the `pg_html5_email_address` Postgres extension.

The routine name is compliant with the `pg_tst` extension.  An intentional choice has been made to not _depend_ on the `pg_tst` extension its test runner or developer-friendly assertions to keep the number of inter-extension dependencies to a minimum.

Procedure-local settings:

  *  `SET pg_readme.include_this_routine_definition TO true`
  *  `SET plpgsql.check_asserts TO true`

```
CREATE OR REPLACE PROCEDURE ext.test__pg_html5_email_address()
 LANGUAGE plpgsql
 SET "pg_readme.include_this_routine_definition" TO 'true'
 SET "plpgsql.check_asserts" TO 'true'
AS $procedure$
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
$procedure$
```

### Types

The following extra types have been defined _besides_ the implicit composite types of the [tables](#tables) and [views](#views) in this extension.

#### Domain: `html5_email`

The `html5_email` domain type enforces that the underlying `text` value conforms to the HTML 5 validation rules for email addresses.

See the [_HTML5 email validation_](#html5-email-validation) section of this readme for details.

```sql
CREATE DOMAIN html5_email AS text
  CHECK (((VALUE IS NULL) OR (VALUE ~ html5_email_regexp())))
  COLLATE html5_email_ci;
```

## `pg_html5_email_address` raison d'etre

The author of `pg_html5_email_address`—Rowan—deemed it useful to split off this tiny extension from the PostgreSQL backend of the [FlashMQ SaaS MQTT hosting service](https://www.flashmq.com/).  Even though the objects in this extension almost seem too insignificant to justify an extension, Rowan couldn't think of any other extension to put this in.  And there really is no lower limit to how small PostgreSQL extensions may be.

## Authors & contributors

* Rowan Rodrik van der Molen

## Colophon

This `README.md` for the `pg_html5_email_address` `extension` was automatically generated using the [`pg_readme`](https://github.com/bigsmoke/pg_readme) PostgreSQL extension.
