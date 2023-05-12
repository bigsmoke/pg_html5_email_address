-- Complain if script is sourced in `psql`, rather than via `CREATE EXTENSION`
\echo Use "CREATE EXTENSION pg_html5_email_address" to load this file. \quit

--------------------------------------------------------------------------------------------------------------

-- CHANGE: Reflect Unicode reality and changes to regexp. and domain.
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

Finally there is the question of Unicode: are non-ASCII characters allowed in HTML5 email addresses? The HTML5 spec is unclear about this, but domain names definitely can (and now occasionally _do_) contain non-ASCII characters, and, since [RFC 6532](https://www.rfc-editor.org/rfc/rfc6532), this seems to be also formally allowed in email addresses. But HTML5 goes its own way, as do the browser makers. As of 2023-01-16,

* WebKit does not allow unicode chacters in `<input type="email">` _at all_.
* Firefox allows unicode characters only in the domain part, not in the local part.
* Safari …

## Reference

<?pg-readme-reference ?>

## `pg_html5_email_address` raison d'etre

The author of `pg_html5_email_address`—Rowan—deemed it useful to split off this tiny extension from the PostgreSQL backend of the [FlashMQ SaaS MQTT hosting service](https://www.flashmq.com/).  Even though the objects in this extension almost seem too insignificant to justify an extension, Rowan couldn't think of any other extension to put this in.  And there really is no lower limit to how small PostgreSQL extensions may be.

## Authors & contributors

* Rowan Rodrik van der Molen

<?pg-readme-colophon?>
$markdown$;

--------------------------------------------------------------------------------------------------------------

-- CHANGE: Make it clear why we're not interested in ignoring accented characters anyway.
comment on collation html5_email_ci is
$markdown$A non-deterministic collation for case-insensitive email address comparisons.

RFC 5322 says that the local part of email addresses may be treated case sensitively, but this is widely ignored, and even according to the same spec not a great idea for portability.  Therefore, let's ignore case.

Accents are _not_ ignored by this collation.  It would make no sense, since the `html5_email` doesn't even allow accented characters (or non-ASCII characters in general).  (Therefore this is a _secondary strength_ (`@colStrength=secondary`) non-deterministic collation, whereas ignoring accents requires a _primary strength_ non-deterministic collation.  See Daniel Verite his excellent blog post about [PostgreSQL non-deterministic collations](https://postgresql.verite.pro/blog/2019/10/14/nondeterministic-collations.html) for further exploration of this topic.)
$markdown$;

--------------------------------------------------------------------------------------------------------------

-- CHANGE: Only allow ASCII characters.
create or replace function html5_email_regexp(with_capturing_groups$ bool default false)
    returns text
    immutable
    leakproof
    parallel safe
    set pg_readme.include_this_routine_definition to true
    language sql
    return $re$(?x)
^
($re$ || case when with_capturing_groups$ then '' else '?:' end || $re$
  [a-zA-Z0-9.!#$%&''*+/=?^_`{|}~-]+
)
@
($re$ || case when with_capturing_groups$ then '' else '?:' end || $re$
  [a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?
  (?:[.][a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*
)
$
$re$;

--------------------------------------------------------------------------------------------------------------
