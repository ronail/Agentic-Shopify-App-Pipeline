---
name: scaffold
description: "Creates the per-app directory skeleton for a Shopify app: apps/<app>/ with README, status, approvals and prototype, the production/apps/<app> work folders, and the docs/registry/apps.json entry. Use when an approved app has no directory yet, or before any per-app work can run."
argument-hint: "--app <app-slug>"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
model: sonnet
---

# Scaffold — Create the Per-App Skeleton

## Purpose

Every per-app step in the pipeline assumes a fixed layout: source in
`apps/<app>/`, build and planning artefacts in `production/apps/<app>/`. Nothing
works on an app whose shell is missing — approval writes fail, session state has
nowhere to land, sprints have no home.

This skill is the **only** task that creates that layout. It must finish before
any per-app skill runs, and it must finish before anything tries to read the app.

## When to use

- `product-director` approved `gate-1-research` and the slug has no directory.
- `docs/registry/apps.json` lists an app but `apps/<app>/` is missing.
- A hand-added folder exists but is incomplete (missing `approvals.json` or one
  of the three `production/apps/<app>/` subfolders).

## Inputs

| Path | Required | What you take from it |
|------|----------|-----------------------|
| `--app <app-slug>` | yes | The directory name; must match the registry slug exactly |
| `request.md` | yes | The app's purpose sentence, for README and status |
| `docs/registry/apps.json` | yes | Whether the slug already exists |
| `production/research/<app>/recommendation.md` | optional | Scope hint for the README |

## Steps

1. **Validate the slug.** Lowercase, hyphen-separated, no spaces or underscores.
   Reject `--app "Discount Bundles"` and ask for `discount-bundles`. If the slug
   is in neither `request.md` nor the registry, stop and say so — scaffolding an
   unrequested app is how phantom directories appear.
2. **Check for an existing directory.** If `apps/<app>/` exists, do not
   overwrite. Diff what is present against the required list and create only the
   missing entries. Report what was already there.
3. **Create the source shell** `apps/<app>/`:
   - `README.md` — app name, one-paragraph purpose from `request.md`, the
     current gate, and the owner agents.
   - `status.md` — a header with `Stage:`, `Last Updated:`, `Owner:` and an
     empty `## Notes` section.
   - `approvals.json` — an object with one key per gate, each
     `{"status": "pending", "date": null, "approver": null, "note": null}`:
     `gate-1-research`, `gate-2-prototype`, `gate-3-scope`, `gate-4-release`,
     `gate-5-update`.
   - `prototype/.gitkeep` — the merchant-facing prototype goes here later.
4. **Create the work shell** `production/apps/<app>/`:
   - `sprints/.gitkeep`
   - `milestones/.gitkeep`
   - `session-state/.gitkeep`
5. **Register the app** in `docs/registry/apps.json`. Append an entry with
   `slug`, `name`, `purpose`, `stage: "research"`, `last_approved_gate: null`,
   `created` (today, `YYYY-MM-DD`). Keep the file's existing key order and
   two-space indentation; append, never rewrite the other entries.
6. **Verify the result** with a directory listing plus a JSON parse of
   `apps/<app>/approvals.json` and `docs/registry/apps.json`. Both must parse.
   A malformed registry entry breaks every downstream step that reads it.
7. **Report** the created paths as a list, and name the next skill:
   `/research <app>` if research is not written, `/build-prototype <app>` if
   `gate-1-research` is already approved.

## Outputs

Created or completed:

```
apps/<app>/README.md
apps/<app>/status.md
apps/<app>/approvals.json
apps/<app>/prototype/.gitkeep
production/apps/<app>/sprints/.gitkeep
production/apps/<app>/milestones/.gitkeep
production/apps/<app>/session-state/.gitkeep
```

Modified: `docs/registry/apps.json` (one appended entry).

## Ownership

Owned by **app-architect**. `producer` confirms the slug against the board
before scaffolding; `product-director` confirms the app was actually approved.

## Rules

- **Never overwrite** an existing `approvals.json` — it is the gate record.
- **Never scaffold without a request line.** The slug must trace to
  `request.md` or the registry.
- **No source code.** This skill produces folders and metadata, not an app.
  Implementation belongs to `lead-engineer` and the specialist agents.
- **Idempotent.** Running it twice on the same slug must change nothing and
  report "already complete".

Template: `.claude/docs/templates/merchant-onboarding.md` — the first-run contract every new app directory must satisfy.
