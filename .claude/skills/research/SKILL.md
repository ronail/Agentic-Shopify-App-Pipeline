---
name: research
description: "Market research for a Shopify app: validates the merchant problem, maps competitors and their pricing and review complaints, and writes a build/kill recommendation under production/research/<app>/. Use before gate-1-research, when a new app slug has no research folder, or when the merchant problem needs evidence instead of opinion."
argument-hint: "<app-slug> [original|competitor-killer]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
model: sonnet
---

# Research — Market Evidence for a Shopify App

## Purpose

Turn an app idea into evidence a decision can rest on: is this a real merchant
problem, who already solves it, what do they charge, and what would make a
merchant switch. The output is what `product-director` reads before approving
`gate-1-research`. Research that cannot be traced to a source is not research.

## When to use

- A slug in `docs/registry/apps.json` has `stage: research` and no folder under
  `production/research/`.
- `request.md` lists a new app in "Apps in scope".
- Existing research is stale and needs a refresh — use `/update-research`
  instead, which preserves prior findings and appends a delta.

## Inputs

| Path | Required | What you take from it |
|------|----------|-----------------------|
| `request.md` | yes | Goal, success criteria, the app's stated purpose |
| `request-history.md` | optional | Prior intent, asks that were superseded |
| `docs/registry/apps.json` | yes | Canonical slug, stage, last approved gate |
| `production/research/<app>/` | optional | Existing research to extend, never to overwrite |
| `docs/shopify-api-reference/` | optional | Whether the required API surface even exists |

## Steps

1. **Resolve the slug.** Read `docs/registry/apps.json` and take the `slug`
   field. Do not invent a slug from the app name; directory names are slugs.
2. **Pick the mode.** `original` (default) means find the gap and own it.
   `competitor-killer` means name the incumbent and the specific complaint you
   will fix. If the argument is missing, ask — the two modes produce different
   recommendations.
3. **State the problem in merchant language.** One paragraph: what a merchant
   does today, what it costs them (minutes per order, support tickets, refunds,
   lost conversion). No feature talk in this section.
4. **Search the Shopify App Store** for the problem keywords and record for
   each listing: name, rating, review count, pricing tiers, install count band,
   and the recurring complaint in the 1-3 star reviews. Complaints are the
   useful signal — a five-star listing tells you the problem is real, not that
   it is solved.
5. **Search outside listings** for the same problem (help-center threads,
   merchant forums, published pricing pages). Note where merchants describe a
   workaround — a workaround is an unserved need.
6. **Check build feasibility** against `docs/shopify-api-reference/`. If the app
   needs an API surface that is not available or is deprecated, say so now, with
   the surface and the deprecation date. This is the most common reason a
   research phase ends in "kill".
7. **Score the opportunity.** Rate each of: problem pain, competitive density,
   differentiation available, build cost band, review-surface risk. Give one
   sentence of justification per score.
8. **Write the recommendation.** Exactly one of `build`, `build-narrow`,
   `defer`, or `kill`, with the single fact that drove the call. Then list the
   three assumptions that would reverse it.
9. **Ask before writing** if the target folder does not exist yet, since this
   creates `production/research/<app>/`.

## Outputs

All under `production/research/<app>/`:

- `research.md` — problem statement, market scan, opportunity scoring
- `competitors.md` — one row per listing: name, rating, reviews, pricing,
  recurring complaint, differentiation hook
- `sources.md` — every URL read, with the date and what it supported
- `recommendation.md` — the verdict, the driving fact, the reversal conditions

## Ownership

Owned by **research-specialist**. `growth-lead` is consulted on positioning and
pricing story, `api-lead` on whether the required API surface is viable,
`app-architect` on rough build cost band. `product-director` consumes the output
and runs `gate-1-research` — do not self-approve the gate.

## Rules

- **Cite or cut.** Any claim in `research.md` that has no entry in `sources.md`
  is removed, not softened.
- **Never overwrite** an earlier research file. Add a dated section.
- **No pricing guesses.** If a listing hides pricing, write "not published" and
  note what the listing shows instead.
- **A kill recommendation is a success.** Ending an app before it costs a build
  is the cheapest outcome this skill can produce.
