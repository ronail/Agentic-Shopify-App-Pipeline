---
name: update-research
description: "Refreshes existing market and competitor research for a Shopify app without losing prior findings: re-checks competitor listings, pricing and complaints, appends a dated delta, and records what changed in the recommendation. Use when research is stale, a competitor shipped, or gate-5-update needs current evidence."
argument-hint: "[app-slug]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
model: haiku
---

# Update Research — Refresh the Evidence

## Purpose

Research ages fast: a competitor adds the feature you were differentiating on, or
drops its price, or disappears. This skill re-checks the evidence and appends a
delta — it never rewrites history, because the original finding is part of why
the app exists.

## When to use

- `gate-5-update` is being prepared for an app already released.
- A merchant or reviewer mentions a competitor that was not in the original scan.
- Research is more than one release old.
- The app's differentiation hook is being questioned.

## Inputs

| Path | Required | What you take from it |
|------|----------|-----------------------|
| `production/research/<app>/` | yes | Existing `research.md`, `competitors.md`, `sources.md`, `recommendation.md` |
| `docs/registry/apps.json` | yes | The app slug and its current stage |
| `request.md` | yes | Whether the app's purpose changed since the research |
| `apps/<app>/status.md` | optional | What has actually been built |

## Steps

1. **Read the prior research in full** before searching. The delta is only
   meaningful against a baseline you can quote.
2. **List the claims to re-verify** — one line each, pulled from
   `competitors.md` and `recommendation.md`: each competitor's price, rating,
   feature claim, and the differentiation hook. These are the only things worth
   re-checking.
3. **Re-check each listing** and record for each claim: `unchanged`, `changed`
   (with old and new value), `gone` (listing removed), or `new` (a competitor not
   in the original scan). Note the date checked.
4. **Search for the new entrant case** — the same problem keywords as the
   original research, sorted by newest. A new listing that solves the
   differentiation hook is the finding that matters.
5. **Re-test the kill conditions** from the prior recommendation. If any now
   holds, the app's premise changed and that must be stated plainly.
6. **Append a dated delta section** to each existing file. Do not rewrite earlier
   sections; a reader must be able to see what was believed when.
7. **Update `recommendation.md` with a revision block**, not an edit: the new
   verdict if it changed, the fact that changed it, and what the change implies
   for the app's next scope decision.
8. **Add every new URL to `sources.md`** with the date read. Uncited claims in
   the delta are removed.

## Outputs

Appended to `production/research/<app>/`:

- `research.md` — dated delta section
- `competitors.md` — per-listing status changes plus any new entrants
- `sources.md` — newly read URLs with dates
- `recommendation.md` — revision block: prior verdict, new verdict, driving fact

## Ownership

Owned by **research-specialist**. `growth-lead` interprets pricing moves;
`product-director` decides whether a changed verdict alters the app's roadmap;
`producer` schedules the re-scope if it does.

## Rules

- **Append only.** Never delete or rewrite a prior finding.
- **Date every changed line.** An undated delta is unusable six months later.
- **A changed verdict is not an automatic re-scope** — report it, and let
  `product-director` decide through `/mmmvp-proposals`.
- **Compare like with like.** Re-check the same listings first, then widen the
  search; a new keyword set silently changes the comparison.
