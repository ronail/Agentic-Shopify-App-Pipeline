---
name: onboard
description: "Onboard a developer, a merchant reviewer, or a dev store to this Shopify app pipeline. Three modes with verified checklists: dev environment (clone, CLI, tunnel, tests), merchant/reviewer walkthrough (what to click, what to expect), and test-store setup routing to create-test-store."
argument-hint: "[dev | merchant | store] [app: <slug>] [--rebuild]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, AskUserQuestion, request_user_input, clarify
model: sonnet
agent: producer
---

# Onboard

Three different people arrive here and need three different first hours. Ask
which one, then run the matching checklist end to end — verifying each step, not
listing it.

**Outputs:**
- `dev` — no file by default; offer `apps/<app>/ONBOARDING.md` only if the team
  wants it checked in (ask first).
- `merchant` — a walkthrough script printed in conversation, or written to
  `production/apps/<app>/milestones/demo-<date>.md` with approval.
- `store` — routes to `/create-test-store`; writes nothing itself.

---

## 0. Establish Who Is Arriving

- **dev** — an engineer who will write code. Needs a working app on a dev store
  and a green test run.
- **merchant** — a store owner or reviewer who will use the app. Needs a store
  with the app installed and a scripted path through the merchant-visible
  features.
- **store** — someone who only needs a development store with the app installed
  so others can test.

If the mode is ambiguous, ask. Do not run the dev checklist for a merchant.

---

## Mode: dev

Read first: `apps/<app>/README.md`, `apps/<app>/status.md`,
`apps/<app>/shopify.app.toml`, `.claude/docs/technical-preferences.md`,
`.claude/docs/quick-start.md` if present.

**Checklist — each item is verified, not assumed:**

1. **Toolchain**
   - [ ] Node 20 LTS: `node -v`
   - [ ] npm present; run installs with the repo's lockfile, not a fresh resolve
   - [ ] Shopify CLI installed and version reporting: `shopify version`
   - [ ] Git identity configured; on a feature branch, not `main` for work
2. **Repository**
   - [ ] Clone and `npm install` at the repo root; then per-app install if the
         app is its own package
   - [ ] `npm test -- --run` executes (a failing suite is expected for some
         apps — record the state rather than "fixing" it on day one)
   - [ ] `.claude/docs/directory-structure.md` read: one writer per app, no
         shared mutable file except `docs/registry/apps.json`
3. **Shopify CLI auth**
   - [ ] `shopify auth login` completes (browser flow) — never paste a token
         into chat or a file
   - [ ] The partner account has access to the app's dev store
   - [ ] `shopify app config link` points at the right app and store; verify by
         reading the resolved `shopify.app.toml`
4. **Local run**
   - [ ] `shopify app dev` starts, opens a tunnel, and installs/updates the app
         on the dev store
   - [ ] The embedded admin route loads inside the Shopify admin iframe
   - [ ] A webhook from the store reaches the tunnel (check the CLI webhook log)
5. **Local configuration**
   - [ ] `.env.local` created from the documented template; every required key
         present — list key **names** only, never values
   - [ ] `.env.local` is git-ignored (`git check-ignore -v .env.local` returns a
         rule)
   - [ ] Database reachable (local Postgres or the dev database), migrations
         applied
6. **First safe change**
   - [ ] Pick one open item from `apps/<app>/status.md` or an existing sprint
   - [ ] Run `/story-readiness` before `/dev-story` — onboarding is not the time
         to skip the readiness check

**Report format:** a table of step / result / evidence / blocker. Anything not
verified is `BLOCKED` with the exact error, not "should work".

Common blockers and the honest answer:
- *No partner account access* → ask the app owner to invite; nothing else works.
- *Tunnel fails* → check CLI version, port conflict, network/firewall; do not
  work around it with a public URL.
- *Migrations fail* → the DB user lacks privileges or the dev DB is behind; do
  not hand-edit the production schema.

---

## Mode: merchant

Read: `apps/<app>/README.md`, the app's prototype or built routes, and its
`status.md` for what is explicitly not built yet.

Produce a walkthrough that a non-engineer can follow:

```markdown
# <app> — Merchant Walkthrough

## What this app does
<one paragraph, merchant language, no API vocabulary>

## Before you start
- Store: <dev store handle> (development store — charges are test charges)
- The app is installed / install link: <link>

## Path
1. Open the app from Shopify admin → Apps.
   Expect: <what should appear>
2. <primary merchant action — create a bundle, tag orders, etc.>
   Expect: <visible result, including where to verify it in Shopify admin>
3. <second action — the value moment>
   Expect: ...
4. <billing step if applicable — test charge, no real money>
   Expect: ...

## What is not built yet
<from status.md — be explicit; a reviewer who finds a missing feature trusts the
rest more, not less>

## If something looks wrong
Report: screen, action, what you expected, what happened. Do not retry destructive
actions (delete, bulk apply) more than once.
```

Rules for this mode:
- Never expose API terms, scope names, or internal stage vocabulary to a merchant.
- Never promise a feature that `status.md` lists as unbuilt.
- If the app is still at `prototype` stage, say clearly that it runs against
  mock data on a dev store.
- Test charges only; if a real charge could occur, stop and escalate to
  `billing-specialist` before the walkthrough.

---

## Mode: store

Do not create stores by hand. Route to `/create-test-store`, which handles
development-store creation, app installation, sample data, and credential
storage in the git-ignored app-local file.

What this mode does provide:
- [ ] Confirm which app needs the store and at what stage.
- [ ] Confirm the store will be a **development store** — never a live merchant
      store, never a Plus production store.
- [ ] Confirm where credentials will live: `apps/<app>/credentials.<store>.json`,
      git-ignored. Never in chat, never in a committed file.
- [ ] After `/create-test-store` completes, verify installation and run
      `/smoke-check <app> --after-deploy` so the store is known-good before
      anyone builds on it.

---

## Write Rules

- Ask before writing any file: *"May I write this walkthrough to
  `production/apps/<app>/milestones/demo-<date>.md`?"*
- Never write credentials, tokens, or store passwords anywhere.
- `ONBOARDING.md` inside an app is optional and per-app; do not create it in
  `docs/` (that would be a shared doc about one app).
- Do not add setup steps that only work on your machine. If a step needs a
  personal account, say so explicitly and offer the shared alternative.

---

## Done Means

- dev: the engineer has a running embedded app on a dev store, a green (or
  explained-red) test run, and one assigned first task.
- merchant: a walkthrough exists, the store is installed, and the reviewer knows
  what is deliberately missing.
- store: a development store exists with the app installed and a passing smoke
  check.
