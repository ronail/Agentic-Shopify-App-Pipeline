---
name: mmmvp-proposals
description: "Proposes minimal-market-viable slices for the current request: the smallest shippable version of a Shopify app that a merchant would pay for, with explicit cuts and the gate-3-scope decision each slice forces. Use when scope is unclear, when a build is drifting large, or before gate-3-scope."
argument-hint: "[app-slug]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
model: sonnet
---

# MMMVP Proposals — Smallest Shippable Slice

## Purpose

Most app builds fail at the scope line, not the technical line. This skill cuts
a request down to the smallest version a merchant would install and pay for,
states exactly what is excluded, and gives `product-director` a decision instead
of a feature list. Three slices, not one — a single proposal is not a choice.

## When to use

- An app passed `gate-1-research` and the build scope is still a paragraph of
  wishes.
- A sprint is over budget because the app grew.
- A new request line adds features to an app already in build.
- Before `gate-3-scope`, always.

## Inputs

| Path | Required | What you take from it |
|------|----------|-----------------------|
| `request.md` | yes | Goal, success criteria, the app's purpose |
| `production/research/<app>/recommendation.md` | yes | The problem being solved and the differentiation hook |
| `production/research/<app>/competitors.md` | optional | What incumbents charge for, to price the slice |
| `apps/<app>/status.md` | optional | Where the build actually is |
| `production/apps/<app>/sprints/` | optional | What is already committed |

## Steps

1. **Extract the job.** Write the merchant's job-to-be-done as one sentence:
   "When a merchant ___, they want ___, so they can ___." If you cannot fill all
   three blanks from the research, stop — the slice would be a guess.
2. **List every candidate capability** mentioned anywhere in the request and
   research, one line each, no grouping yet. This is the raw scope.
3. **Classify each capability** as: `core` (the job cannot be done without it),
   `thin` (needed to be credible but can be minimal), or `later` (real value,
   not needed to be paid for once).
4. **Build three slices**, each independently shippable:
   - **S1 — Thinnest**: `core` only, one workflow, one screen, no settings.
   - **S2 — Credible**: S1 plus the `thin` items a reviewer or merchant would
     notice missing in the first ten minutes.
   - **S3 — Complete**: S2 plus the `later` items that fit one release window.
5. **For each slice record**: what a merchant can do that they could not before,
   what is explicitly excluded, the Shopify surfaces it touches (admin API,
   webhooks, theme app extension, checkout extension), and a build size band
   (S / M / L) with one sentence of justification.
6. **Name the pricing consequence.** A slice with no monetizable surface is not
   a proposal. State the plan tier each slice supports, or "free, growth-led" if
   that is the intent.
7. **Name the kill condition** for each slice: the fact that would make it not
   worth shipping (no merchant asks for it in reviews, the API surface is
   deprecated, the incumbent bundles it free).
8. **Ask before writing** to `production/apps/<app>/`.

## Outputs

`production/apps/<app>/mmmvp-proposals.md`, containing:

- The job-to-be-done sentence
- A capability table: capability | class | slice(s) it lands in
- Three slice blocks with scope, exclusions, surfaces, size band, pricing story,
  kill condition
- A recommendation: which slice to take to `gate-3-scope`, and why

## Ownership

Owned by **product-director**. `producer` sizes the slices against the sprint
calendar; `app-architect` validates the surface list; `growth-lead` checks the
pricing story. The slice decision itself is the user's — present the three
options and recommend, do not pick unilaterally.

## Rules

- **Three slices minimum.** One proposal hides the trade-off.
- **Exclusions are mandatory.** A slice with no "not in this version" list is
  not a slice, it is the full scope relabelled.
- **No capability without a job.** Anything that only serves internal elegance
  goes in `later`, and the reason is written down.
- **Never edit `request.md`.** Scope changes to the request are
  `/update-request`; this skill only proposes.
