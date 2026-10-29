---
name: localize
description: "Plan and implement merchant-facing localization for a Shopify app: Markets and regional settings, translation files, locale-aware money/date/address formatting, and Admin API @inContext requests. Audits hardcoded strings, produces a key inventory, and never ships a half-translated surface."
argument-hint: "[app: <slug>] [audit | plan | implement] [locale: <code>]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, AskUserQuestion, request_user_input, clarify
model: sonnet
agent: localization-lead
---

# Localize

Localization is a merchant-facing product decision, not a string-replacement
task. A merchant in a non-English market judges the app on whether the admin
surface reads like it belongs there and whether money, dates, and addresses are
formatted the way their customers expect.

**Outputs:**
- `audit` — key/string inventory and gap report, in conversation (optionally
  `production/apps/<app>/sprints/localization-<date>.md` with approval).
- `plan` — locale rollout plan: which locales, in what order, with what proof.
- `implement` — translation files and format fixes inside `apps/<app>/`, plus a
  test that fails on a missing key.

Read `.claude/docs/technical-preferences.md` first. Note what it actually says
about the primary market and supported languages — `[TO BE CONFIGURED]` means
ask, do not assume US English is the target forever.

---

## 1. Scope the Surface

Three surfaces, three different mechanisms. Do not mix them up.

| Surface | Lives in | Mechanism |
|---------|----------|-----------|
| Embedded admin UI | `apps/<app>/` React routes | translation files + the app's i18n layer; Polaris component strings come from the app's locale bundle |
| Theme app extension | app extension blocks | `locales/<locale>.json` beside the extension, keys referenced from Liquid |
| Checkout extension | checkout extension directory | its own locale files, restricted component set, no arbitrary HTML |
| Merchant-facing email / export | app server templates | server-side locale resolution from the shop's locale, not the browser's |

Also scope the **data** side:
- Money: format with the shop's currency and the market's format conventions.
- Dates/times: shop timezone, not server timezone.
- Addresses: country-specific field order and required fields.
- Units and number separators: market-dependent.

---

## 2. Audit — Find What Is Hardcoded

Run, from the app directory, and record counts per file:

- String literals in JSX/TSX that render to the merchant:
  grep for quoted text inside JSX and for `title=`/`label=`/`helpText=`/
  `placeholder=` props with literal values.
- Polaris props that take merchant-visible text: `title`, `label`, `helpText`,
  `placeholder`, `content`, `accessibilityLabel`, `error`, empty-state copy.
- Server-side messages: validation errors, webhook-triggered notifications,
  emails, export headers.
- Number/date/money formatting: raw `toFixed`, `$` concatenation, `toLocaleString`
  without a locale argument, `new Date().toLocaleDateString()` with no explicit
  locale, and any date arithmetic on server time.
- Existing translation files: `apps/<app>/locales/*.json` (or the extension's
  `locales/`). List keys present, keys used, and **keys used but missing** —
  that last set is the actual bug list.

Report as a table:

| File:line | Literal | Surface | Key (proposed) | Notes |

Key naming: `<surface>.<feature>.<element>` in `camelCase` segments, stable and
descriptive — `bundles.list.emptyTitle`, not `bundles.list.text3`. Never rename
an existing key without a migration of every reference; a renamed key is a
silent English fallback in production.

---

## 3. Plan the Locale Rollout

Order of work matters more than the locale list:

1. **Make the base locale complete first.** English keys, every string, no
   literals left. A second locale on top of hardcoded strings multiplies the
   problem.
2. **One pilot locale**, chosen from the actual merchant base — not from
   enthusiasm. State the evidence (existing installs, target market in
   technical-preferences, merchant requests).
3. **Prove the pilot** end to end: install, primary flow, error states, empty
   states, email/export, billing copy — in the pilot locale.
4. **Then** add further locales, in batches, each with the same proof.

Per-locale scope must state:
- which surfaces are translated (admin / theme extension / checkout / email),
- what is deliberately untranslated (third-party brand terms, API-level ids),
- who reviews the translation (a human who reads the language; machine
  translation without review is not a shipped locale),
- how a missing key is detected in CI.

Translation quality rules:
- Translate meaning and merchant intent, not words. Button labels stay short —
  German and Finnish expand; assume up to 35% growth and check the layout at
  that width.
- Never translate: API field names, webhook topics, plan identifiers, IDs, or
  anything that round-trips to the API.
- Keep interpolation placeholders (`{count}`, `{shopName}`) intact; a translated
  string that drops a placeholder is a runtime bug.
- Pluralization: use the translation library's plural forms, not
  `count === 1 ? ... : ...`. Some locales have more than two forms.
- Currency: format from the shop's currency code, never assume two decimals
  (some currencies have zero or three).

---

## 4. Implement

Rules for edits inside `apps/<app>/`:

- One change per concern: string extraction, then locale files, then formatting
  fixes. Do not mix a refactor into a localization change.
- Add keys to the base locale and to every existing locale in the same change —
  a key present in `en` and missing in `fr` is a defect, not a follow-up.
- Replace manual formatting with locale-aware formatting: `Intl.NumberFormat`
  and `Intl.DateTimeFormat` with an explicit locale and the shop's currency or
  timezone. Pass the shop's locale from App Bridge context or the session, not
  from `navigator.language`.
- GraphQL: requests that return translated content (product titles, collection
  names, metafield values) take the `@inContext(country:, language:)` directive.
  Read the pinned schema in `docs/shopify-api-reference/<version>/` for the
  exact argument shape and which fields are translatable at that version.
- Markets: a market determines currency, domain, and pricing. If the app creates
  or prices anything per market, the market context must come from the shop, not
  be guessed from the locale.
- Theme app extension: merchant-editable strings go in the extension's locale
  files with schema `locales` entries; never inline merchant-facing copy in
  Liquid.

**Test that must exist after implementation:**
- A test that loads every locale file and asserts the key set equals the base
  locale's key set. Missing key = failing test, in CI, on every app.
- A test for money formatting in at least one non-USD currency with a different
  decimal convention.
- A test that a translated string keeps its interpolation placeholders.

---

## 5. Report and Hand Off

```markdown
# Localization — <app>

> Date: <date> | Mode: audit | plan | implement | Locale: <code>
> Base locale: <code> | Surfaces: admin / theme / checkout / email

## Inventory
| Surface | Strings found | Keys existing | Hardcoded | Missing keys |

## Formatting findings
| File:line | Issue | Fix |

## Locale plan
| Order | Locale | Evidence | Surfaces | Reviewer | Missing-key CI gate |

## Changes made
| File | Change | Keys added |

## Verification
- Key-parity test: PASS/FAIL
- Pilot flow walked in <locale>: PASS/FAIL
- Layout at +35% string length: PASS/FAIL

## Verdict: READY / NEEDS WORK
```

Ask before writing any file. Route follow-ups:
- Translation review quality → `localization-lead` (human reviewer required)
- Polaris component copy, layout at longer strings → `polaris-specialist`
- Translatable GraphQL content, `@inContext` → `graphql-specialist`
- Extension locale files → `liquid-specialist` / `checkout-specialist`
- Markets and pricing behaviour → `billing-specialist` (if pricing) or
  `api-lead`

---

## Rules

- **No half-translated surface ships.** Either a surface is fully in the locale
  or it is explicitly out of scope for that locale, and the report says which.
- **No machine translation without a human reviewer.** Say it plainly when a
  locale has no reviewer — that locale is not ready.
- **Never infer locale from the browser inside the embedded admin.** The shop's
  locale and market are the authority.
- **Localization changes get a smoke pass.** Run `/smoke-check <app>` after
  implementing — a locale change that breaks the install flow is a regression.
