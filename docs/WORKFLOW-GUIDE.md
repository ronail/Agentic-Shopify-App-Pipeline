# Agentic Shopify App Pipeline — Complete Workflow Guide

> **How to go from a merchant problem to a reviewed, released Shopify app.**
>
> This guide walks through every stage using the 31-agent roster, 66 skills, and
> the hooks in `.claude/hooks/`. It assumes you are working from the repository
> root, in Claude Code, Codex, or Hermes.
>
> The pipeline has 9 stages and 5 gates (`/gate-check`). The authoritative stage
> order lives in `.claude/docs/workflow-catalog.yaml`, which `/help` reads. Gate
> verdicts are **advisory** — they never hard-block you. They record whether the
> evidence exists, and that record is what every later skill trusts.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Stage 1: Request](#stage-1-request)
3. [Stage 2: Research](#stage-2-research)
4. [Stage 3: Architecture](#stage-3-architecture)
5. [Stage 4: Prototype](#stage-4-prototype)
6. [Stage 5: Scope](#stage-5-scope)
7. [Stage 6: Build](#stage-6-build)
8. [Stage 7: Test](#stage-7-test)
9. [Stage 8: Release](#stage-8-release)
10. [Stage 9: Update](#stage-9-update)
11. [Cross-Cutting Concerns](#cross-cutting-concerns)
12. [Appendix A: Agent Quick-Reference](#appendix-a-agent-quick-reference)
13. [Appendix B: Skill Quick-Reference](#appendix-b-skill-quick-reference)
14. [Appendix C: Common Workflows](#appendix-c-common-workflows)

---

## Quick Start

### What you need

- **Claude Code**, **Codex**, or **Hermes** (`/start claude|codex|hermes` routes)
- **Git**
- **Node 20 LTS** and **npm**
- **Shopify CLI** (`shopify app dev`, `shopify app deploy`)
- **A dev store** you control — see `/create-test-store`

### Step 1: Clone and open

```bash
git clone https://github.com/ronail/Agentic-Shopify-App-Pipeline.git my-pipeline
cd my-pipeline
```

### Step 2: Run `/start`

```
/start
```

`/start` reads `docs/registry/apps.json`, `request.md`, and each app's `status.md`
plus `approvals.json`, then routes you:

- **No idea yet** → `/brainstorm`
- **A rough idea** → `/research`
- **A written spec** → `/update-request`, then `/research`
- **An existing app** → `/project-stage-detect`, then `/adopt`

### Step 3: Verify the session context hook

Start a new session; `session-start.sh` should print branch, commits and pipeline
state:

```
=== Agentic Shopify App Pipeline — Session Context ===
Branch: main
Recent commits:
  ea78fa4 refactor(r6): hooks layer hardening ...
Apps: discount-bundles (research), order-tags (research)
=====================================================
```

If it does not appear, check `.claude/settings.json` — hooks are registered there.

### Step 4: Ask for help any time

```
/help
```

`/help` reads the current stage, checks which artefacts exist, and names the next
REQUIRED and OPTIONAL steps.

### Step 5: Know the layout

```
apps/<app>/                  one app per directory — isolated config, scopes, deps
  shopify.app.toml           pinned api_version + access scopes + webhooks
  app/                       embedded admin routes (Polaris, App Bridge)
  app/routes/webhooks.*.ts   webhook handlers, one per topic
  extensions/                theme app extension, checkout extension, functions
  db/migrations/             SQL migrations, one concern per file
  design/                    concept, UX specs, test-store plan
  prototype/                 throwaway prototypes, excluded from the app build
  tests/
docs/
  architecture/
    ADR-NNNN-*.md            cross-app decisions (API version policy)
    apps/<app>/
      requirements.yaml      stable REQ-<AREA>-NNN registry (append-only)
      control-manifest.md    flat Required / Forbidden / Guardrails per layer
      ADR-NNNN-*.md          that app's decisions
  registry/
    apps.json                the single shared mutable registry
    architecture.yaml        cross-app index: ADRs, stances, forbidden patterns
  shopify-api-reference/
    VERSION.md               the pinned Admin API version
    <version>/               immutable snapshot per version
  examples/                  collaborative session transcripts
production/apps/<app>/       epics, stories, sprints, session state
```

> **Tip:** create directories when the stage needs them. The **rules system**
> routes by path — code under `app/routes/` gets admin rules, webhook handlers get
> webhook rules — so the path matters more than the directory existing early.

---

## Stage 1: Request

### What happens

You turn "I think merchants need X" into a written request with a goal, success
criteria and non-goals. Everything downstream traces back to this file.

### Pipeline

```
/brainstorm  -->  request.md  -->  /mmmvp-proposals  -->  /quick-design
   (if needed)         |                  |                    |
                       v                  v                    v
               goal + success      minimal viable       lightweight spec
               criteria + gates    slices, ranked       for a small change
```

### Step 1.1: `/brainstorm` (only if you have no direction)

```
/brainstorm "merchants who sell 3-packs"
```

Asks about your own store experience, what is broken today, and who would pay.
Generates 8 concepts across three frames — fix an existing pain, replace a manual
process, unlock something new. Each carries the merchant job, the Shopify surface
it needs, build risk, and whether an existing app already owns it.

**You pick.** The concept document is written only after you choose.

### Step 1.2: Write or amend `request.md`

```
/update-request
```

Amends the master request without losing prior intent; history is appended to
`request-history.md`. The `track-request-changes.sh` hook enforces that any edit to
`request.md` has a matching history entry in the same working tree.

`request.md` states: goal, success criteria, non-goals, apps in scope, and the five
gate definitions.

### Step 1.3: Cut the first slice with `/mmmvp-proposals`

```
/mmmvp-proposals
```

Proposes minimal-market-viable slices: the smallest shippable version, what it
deliberately omits, and what the first merchant would notice. This is the cheapest
place to kill scope — before research spends a day validating a big idea.

### Step 1.4: Small changes get a quick spec

```
/quick-design "add a CSV export of tagged orders"
```

Creates a lightweight spec instead of a full concept document. `/design-review`
can still review it.

### Stage 1 exit

No formal gate. `request.md` is accepted when you say so; `/research` is next.

---

## Stage 2: Research

### What happens

You validate that the merchant problem is real, map the competing apps, and pick a
wedge. You also write the admin UX specs — before any code — because gate 1 needs
them and because accessibility is cheaper to fix in a spec than in a component.

### Pipeline

```
/research  -->  research.md  -->  /ux-design (x3+)  -->  /ux-review  -->  /gate-check gate-1-research
     |                                  |                    |
     v                                  v                    v
  original vs                    per-screen admin      Polaris + App Bridge
  competitor-killer              (Polaris) specs       + WCAG 2.1 AA check
  wedge + killed features
```

### Step 2.1: `/research`

```
/research discount-bundles
```

Two modes, chosen explicitly:

- **Original** — you believe the problem is unaddressed; validate demand and size.
- **Competitor-killer** — apps exist; find the specific weakness in their reviews.

Output: `apps/<app>/docs/research.md` with the merchant job in one sentence, a
competitor map with review themes, the wedge, the features you are **killing** and
why, and a pricing hypothesis.

A brief that lists ten features has not chosen a wedge.

### Step 2.2: `/ux-design`

```
/ux-design discount-bundles
```

One spec per admin screen under `apps/<app>/design/ux/`: states (loading, empty,
error, no-permission), Polaris components, keyboard path, failure-state copy, and
the data each screen needs.

Gate 1 expects at least three specs. If the app has fewer screens, say so rather
than padding.

### Step 2.3: `/ux-review`

```
/ux-review discount-bundles
```

Validates the specs against Polaris, App Bridge constraints, and the accessibility
tier (WCAG 2.1 AA by default). Findings are BLOCKING (stops handoff) or ADVISORY
(fix during the visual pass).

### Step 2.4: Gate 1 — research

```
/gate-check gate-1-research
```

**Evidence required:** `apps/<app>/docs/research.md` with a named wedge; at least
three UX specs that passed `/ux-review`; `gate-1-research` recorded in
`apps/<app>/approvals.json`.

**Verdict:** PASS / CONCERNS / FAIL — advisory.

> An approval recorded before the artefacts exist is a *claim ahead of evidence*.
> `/project-stage-detect` reports it and `/gate-check` will not treat it as a pass.

---

## Stage 3: Architecture

### What happens

You decide the technical shape of the app, one decision per ADR, each tracing to
requirement IDs. Then you derive a flat control manifest that programmers read
instead of the ADRs.

### Pipeline

```
/create-architecture  -->  /architecture-decision (x N)  -->  /architecture-review
        |                            |                                |
        v                            v                                v
  architecture.md            apps/<app>/ADR-NNNN-*.md       dependency order,
  per app                    + requirements.yaml           requirement coverage,
                                                             API conflicts
                                                                     |
                                                                     v
                                                        /create-control-manifest
                                                                     |
                                                                     v
                                                        control-manifest.md
```

### Step 3.1: Requirements first

`docs/architecture/apps/<app>/requirements.yaml` is the spine. Stable IDs,
append-only:

```yaml
- id: REQ-BUNDLE-004
  area: API surface
  requirement: >
    In fixed-price mode the bundle's unit price is the configured bundle price,
    allocated across components proportionally to each component's list price.
  acceptance_criteria: [...]
  priority: must
  adr: ADR-0001
  status: active
```

`/create-architecture` stops without it: *architecture without requirements is
fiction*.

### Step 3.2: `/create-architecture`

```
/create-architecture discount-bundles
```

Writes `docs/architecture/apps/<app>/architecture.md`: app boundaries, stack and
runtime, data model, API matrix, webhook map, extension strategy, jobs, failure
modes. Sections are written one at a time with your approval, and the document
stays under roughly 400 lines — per-story detail belongs in the story.

It reads, in order: existing ADRs (Accepted ones are constraints), the pinned API
snapshot, the control manifest, the concept and UX specs, and
`docs/registry/architecture.yaml` for stances other apps already depend on.

### Step 3.3: `/architecture-decision`

```
/architecture-decision "how bundles appear in the cart"
```

One decision per ADR, filed with the app: `docs/architecture/apps/<app>/ADR-0001-<slug>.md`.

**Required sections:** Title, Status, Date, Last Verified, Decision Makers,
Summary, **Shopify API Surface**, ADR Dependencies, Context, Decision,
Alternatives Considered, Consequences, Risks, Performance Implications, Migration
Plan, Validation Criteria, **App Requirements Addressed**, Related.

- **Shopify API Surface** records the pinned Admin API version, the surface, a
  knowledge-risk rating (LOW / MEDIUM / HIGH), what you consulted, and what must be
  verified on a dev store. HIGH means the ADR is re-verified at each version bump.
- **App Requirements Addressed** lists `REQ-*` IDs from the app's registry. An ADR
  with no requirement needs a justification line.

**Status lifecycle:** `Proposed` → `Accepted` → `Superseded`. Stories depending on
a `Proposed` ADR are blocked, so do not leave decisions dangling.

Cross-app decisions — currently only the Admin API version policy — live at
`docs/architecture/ADR-NNNN-*.md` and are listed under `shared_adrs` in the
registry.

### Step 3.4: `/architecture-review`

```
/architecture-review discount-bundles
```

Modes: `full`, `coverage`, `consistency`, `api`, `rtm`.

- topological sort of ADR dependencies (a cycle is blocking)
- every requirement covered, partially covered, or listed as a gap
- every operation in the architecture's API matrix resolves against
  `docs/shopify-api-reference/<version>/`
- deprecated fields → findings
- registry vs ADR drift (`docs/registry/architecture.yaml` must list every ADR file)
- control-manifest staleness

Writes `apps/<app>/architecture-review-<date>.md`; may append new requirement IDs,
never renumber.

### Step 3.5: `/create-control-manifest`

```
/create-control-manifest discount-bundles
```

Extracts every Must / Never / Limit from Accepted ADRs, `.claude/rules/`,
`technical-preferences.md` and the pinned snapshot, and organises it by layer:

| Layer | Governs |
|-------|---------|
| Admin UI | embedded routes, Polaris, App Bridge |
| App server | loaders/actions, Admin GraphQL, auth, billing, jobs |
| Webhooks | subscriptions, HMAC, idempotency |
| Theme app extensions | app blocks, Liquid, merchant settings |
| Checkout extensions | extension targets, UI extensions, function limits |
| Data | schema, migrations, sessions, job queue |

The header carries `API Version`, `Manifest Version` (date), `Last Updated`,
`ADRs Covered`, `Access Scopes`. **Stories embed the manifest version**;
`/story-readiness` refuses a story whose embedded version is older and
`/story-done` re-checks at close.

### Stage 3 exit

No gate here. The evidence is the ADR set plus a manifest; `gate-2-prototype` reads
both.

---

## Stage 4: Prototype

### What happens

You build a *real* store-facing prototype — an embedded route running on a dev
store, not a mockup — to answer the questions the ADRs could not settle.

### Pipeline

```
/build-prototype  -->  /prototype-review  -->  /gate-check gate-2-prototype
       |                      |                        |
       v                      v                        v
  apps/<app>/prototype/   verdict against          gate recorded,
  throwaway code          the research wedge        stage → scope
```

### Step 4.1: `/build-prototype`

```
/build-prototype discount-bundles
```

The skill asks what the prototype must **prove**, then orders those questions by how
much they could invalidate. Platform risk first (does the cart transform actually
expand?), UX second (is the picker usable at 50 components?).

Prototype code lives in `apps/<app>/prototype/`, excluded from the app build. It
may be ugly; it may not be fake.

### Step 4.2: `/prototype-review`

```
/prototype-review apps/discount-bundles/prototype
```

Reviews against the research wedge and the UX specs — not against the eventual
product. It separates:

- **must prove this** — a platform or feasibility claim
- **fix now** — a spec drift the prototype disproved
- **later** — polish with no bearing on the decision

A prototype finding can correct an Accepted ADR; the route is to amend it through
`/architecture-decision`, not to diverge silently.

### Step 4.3: Gate 2 — prototype

```
/gate-check gate-2-prototype
```

**Evidence required:** a working prototype on a dev store, a review report,
Accepted ADRs, a current control manifest.

**Verdict:** PASS / CONCERNS / FAIL. CONCERNS is normal — a named, understood risk
is passable; an open product question is not.

---

## Stage 5: Scope

### What happens

You freeze what this version will do, decompose it into epics and stories that trace
to requirements, estimate, and plan the first sprint.

### Pipeline

```
/scope-check  -->  /create-epics  -->  /create-stories  -->  /estimate
      |                  |                    |                  |
      v                  v                    v                  v
  in / out of       epics with           stories with        effort per
  scope vs          ADR + REQ refs       criteria from       story
  request.md                             requirements.yaml
                                                       |
                                                       v
                                              /sprint-plan  -->  /story-readiness
                                                       |                    |
                                                       v                    v
                                              sprint file            READY / BLOCKED
                                                       |
                                                       v
                                              /gate-check gate-3-scope
```

### Step 5.1: `/scope-check`

```
/scope-check discount-bundles
```

Classifies every work item as **in scope** (traced to a requirement), **not yet
traced** (a gap), or **out of scope** (killed during research). Untraced work is
named, not scheduled.

### Step 5.2: `/create-epics` and `/create-stories`

```
/create-epics discount-bundles
/create-stories order-tags epic-1-rule-engine
```

Epics list governing ADRs and traced vs untraced requirements. Stories carry:

- **Requirement ID** — from `requirements.yaml`; if a criterion has no ID, append
  one first
- **Governing ADR** — a `Proposed` ADR forces `Status: Blocked`
- **Control Manifest rules** for the story's layer, plus the embedded manifest
  version
- **Acceptance criteria** copied from the requirement, not paraphrased
- **Test plan**, and the QA readiness check

### Step 5.3: `/estimate` and `/sprint-plan`

```
/estimate
/sprint-plan
```

`/estimate` gives relative effort per story with risk. `/sprint-plan` builds the
sprint file with Must Have / Should Have priorities and a capacity check;
`/sprint-status` reports progress later.

### Step 5.4: `/story-readiness`

```
/story-readiness story-003
```

The last cheap checkpoint before code: requirement ID, ADR status, manifest
version, measurability of criteria, dependencies, test plan. Verdict READY or
BLOCKED with reasons.

### Step 5.5: Gate 3 — scope

```
/gate-check gate-3-scope
```

**Evidence required:** epics and stories exist, every governing ADR is Accepted,
stories pass readiness, a sprint is planned, and `gate-3-scope` is recorded.

---

## Stage 6: Build

### What happens

Stories are implemented against the pinned snapshot, test-first, with the control
manifest as the rulebook.

### Pipeline

```
/story-readiness  -->  /dev-story  -->  /code-review  -->  /story-done
      |                    |                 |                |
      v                    v                 v                v
   READY              tests first,      blocking vs      criteria verified,
                      then module       advisory         notes recorded
```

### Step 6.1: `/dev-story`

```
/dev-story story-003
```

Reads the story, the governing ADR (Decision + Implementation Guidelines), the
control manifest for the story's layer, and the relevant page of
`docs/shopify-api-reference/<version>/`.

Rules it enforces:

- Admin GraphQL, never REST
- shop-scoped queries by session shop
- session tokens for admin requests; no cookie session
- webhook handlers verify HMAC on the raw body, then enqueue
- no floating-point money
- no hardcoded API version outside `shopify.app.toml`

Tests are written before the module. A story with no testable path is a story that
should be smaller.

### Step 6.2: `/code-review`

```
/code-review
```

Reviews the diff against the control manifest, the governing ADR and the snapshot.
Findings are **BLOCKING** (citing the rule: forbidden pattern, guardrail, scope) or
**ADVISORY**. `lead-engineer` owns this gate.

### Step 6.3: `/story-done`

```
/story-done story-003
```

Verifies each acceptance criterion, re-checks the embedded manifest version,
records deferred criteria with a named owner (COMPLETE WITH NOTES, never a silent
pass), updates sprint status, and surfaces the next ready story.

### Step 6.4: Mid-build changes

| Situation | Skill |
|-----------|-------|
| Small tweak inside a story | just change it, keep criteria honest |
| Small change that needs a spec | `/quick-design` |
| New behaviour nobody asked for | `/feature-request` → `/scope-check` |
| Existing behaviour must change | `/update-request` |
| Something broke in production | `/bug-report` → `/bug-triage` → `/hotfix` |
| Cross-app inconsistency | `/consistency-check` |

---

## Stage 7: Test

### What happens

Quality is planned, not discovered. This stage turns per-story tests into a suite
that can be trusted before release.

### Pipeline

```
/qa-plan  -->  /test-setup  -->  /test-helpers  -->  /smoke-check
    |              |                  |                 |
    v              v                  v                 v
 test strategy  runners +          factories         real-store
 per surface    fixtures           from REQ IDs      pass
                                                        |
                              /regression-suite + /soak-test + /perf-profile
```

### Step 7.1: `/qa-plan`

```
/qa-plan discount-bundles
```

Test strategy per surface: unit for pure logic, integration for the queue and
webhook path, dev-store smoke for anything that touches a real cart or order.

### Step 7.2: `/test-setup` and `/test-helpers`

Runners, fixtures and factories. Helpers derive from requirement prefixes
(`REQ-TAG-*` → tag factories), so tests speak the registry's language.

### Step 7.3: `/smoke-check`

```
/smoke-check discount-bundles
```

Exercises the app on a **dev store**: install, create the object the app manages,
verify the real platform behaviour, uninstall. This is the only check that catches
a wrong mutation name against a live API.

### Step 7.4: Regression, soak and performance

```
/regression-suite
/soak-test
/perf-profile
```

`/regression-suite` re-runs the suite before release. `/soak-test` runs the queue
for a sustained period to catch leaks and backoff bugs. `/perf-profile` measures the
budgets in `technical-preferences.md` (admin route p75 < 1.5 s, GraphQL cost < 500,
webhook p95 < 500 ms).

### Step 7.5: `/security-audit`

```
/security-audit discount-bundles
```

OAuth and session tokens, scope minimality, webhook verification, token storage,
log hygiene, protected-customer-data handling. Findings are triaged by
exploitability, not by severity label.

---

## Stage 8: Release

### What happens

Submission as a checklist, with every claim proven on a dev store.

### Pipeline

```
/release-checklist  -->  /app-store-checklist  -->  /release  -->  /changelog
        |                         |                     |              |
        v                         v                     v              v
  build, architecture,      listing, scopes,      deploy version,   merchant +
  compliance, scopes        screenshots,          tag, record       patch notes
                            billing               gate-4-release
                                                         |
                                                         v
                                              /launch-checklist  -->  /gate-check gate-4-release
```

### Step 8.1: `/release-checklist`

```
/release-checklist discount-bundles
```

Checks the repo, not your memory: tests pass, functions build, ADRs Accepted,
manifest current, **mandatory compliance webhooks proven** (`shop/redact`,
`customers/data_request`, `customers/redact`), scopes minimal, smoke test on a clean
store for this exact version.

A handler that returns 200 is not evidence that redaction works.

### Step 8.2: `/app-store-checklist`

```
/app-store-checklist discount-bundles
```

Listing title and description matching what the app actually does, scope
justifications, screenshots from the current build, privacy policy matching the
schema, billing configured through Shopify (no external payment links).

### Step 8.3: `/release` and `/launch-checklist`

```
/release discount-bundles 1.0.0
/launch-checklist discount-bundles
```

`/release` deploys the app version (bundling functions and extensions), tags the
commit, writes the changelog entry, and records `gate-4-release`. Submission in the
Partner Dashboard stays with you — deploy, tag and record are reversible;
submission is not.

`/launch-checklist` is the post-deploy pass: install flow on a clean store, webhook
delivery, uninstall/reinstall, support link.

### Step 8.4: `/changelog` and `/patch-notes`

Merchant-facing notes trace each line to a requirement ID, so support can answer
"why did this change?". `/patch-notes` writes the shorter in-app variant.

### Step 8.5: Gate 4 — release

```
/gate-check gate-4-release
```

**Evidence required:** release checklist complete, App Store checklist complete, a
deployed version, and `gate-4-release` recorded with approver and timestamp.

---

## Stage 9: Update

### What happens

The app lives. Shopify ships a new API version every quarter, merchants ask for
changes, and things break.

### Pipeline

```
/update-research  -->  /apply-updates + /propose-updates  -->  /gate-check gate-5-update
        |                          |
        v                          v
 refreshed market/competitor   accepted update set,
 inputs                        applied with changelog
                     |
                     +--> /tech-debt, /hotfix, /retrospective, /milestone-review
```

### Step 9.1: Quarterly API version bump

```
/update-research
/architecture-review <app> api
```

Read `docs/shopify-api-reference/VERSION.md`, add the new snapshot directory (never
edit the old one), bump `shopify.app.toml` and extension manifests in one story, fix
deprecated-field findings, regenerate the control manifest, then smoke test.

### Step 9.2: Merchant-requested changes

```
/feature-request  →  /scope-check  →  (research if needed)  →  build
/update-request   →  the change is a change of intent, not a bug
```

### Step 9.3: Incidents

```
/bug-report  →  /bug-triage  →  /hotfix  →  /retrospective
```

`/hotfix` is the only path that may skip a sprint; it still needs a test that fails
before the fix and passes after.

### Step 9.4: Debt and consistency

```
/tech-debt           record and prioritise debt with a named risk
/consistency-check   registry vs ADR vs manifest drift
/propose-updates     batch upstream/agent-definition changes for review
/apply-updates       apply an approved update set
```

### Step 9.5: Gate 5 — update

```
/gate-check gate-5-update
```

**Evidence required:** an approved update set, the applied changes, an updated
changelog, and `gate-5-update` recorded.

---

## Cross-Cutting Concerns

### Director review modes

Reviews run in one of three modes, resolved from `.claude/docs/director-gates.md`,
then `production/review-mode.txt`, else default `lean`:

| Mode | Behaviour |
|------|-----------|
| `solo` | Directors skipped; you are the reviewer |
| `lean` | Directors skipped, findings summarised by the skill |
| `full` | Directors spawned for the gate in question |

Override per invocation with `--review full|lean|solo`.

### The collaboration protocol

Every agent follows **Question → Options → Decision → Draft → Approval** and asks
before writing files. Full text:
[COLLABORATIVE-DESIGN-PRINCIPLE.md](COLLABORATIVE-DESIGN-PRINCIPLE.md).

### The AskUserQuestion tool

Decision points are presented as a structured picker (2–4 options, short labels,
one-sentence descriptions) *after* the full reasoning is written out in
conversation — the "Explain → Capture" pattern. On harnesses without the tool,
agents fall back to numbered options in text.

### Agent coordination (3 tiers)

```
Tier 1 (Leadership):  product-director, technical-director, producer, lead-engineer
                                        |
Tier 2 (Leads):       research-specialist, app-architect, api-lead, ux-lead,
                      polaris-specialist, qa-lead, release-manager,
                      devops-engineer, prototype-builder, growth-lead,
                      analytics-engineer, performance-analyst
                                        |
Tier 3 (Specialists): graphql, webhooks, billing, auth, App Bridge, Liquid,
                      checkout, security, tools, localization, App Store review,
                      test stores, QA execution, accessibility, merchant comms
```

**Coordination rules:**

- Vertical delegation: directors → leads → specialists. Do not skip tiers for
  complex decisions.
- Horizontal consultation: same-tier agents may consult each other but must not make
  binding decisions outside their domain.
- Conflict resolution: product conflicts → `product-director`; technical conflicts →
  `technical-director`; scope conflicts → `producer`; code-quality conflicts →
  `lead-engineer`.
- No unilateral cross-domain changes.

Full roster: [`.claude/docs/agent-roster.md`](../.claude/docs/agent-roster.md).

### Automated hooks (safety net)

`.claude/hooks/` provides the guardrails:

| Hook | Trigger | What it does |
|------|---------|--------------|
| `session-start.sh` | Session start | Branch, recent commits, pipeline state |
| `detect-gaps.sh` | Session start | Flags missing stage artefacts |
| `approval-gate.sh` | Write / progress | Blocks on an unrecorded required gate |
| `app-store-gate.sh` | Release work | Blocks with open submission blockers |
| `validate-commit.sh` | Before commit | Commit message and content checks |
| `validate-push.sh` | Before push | Warns on pushes to `main`/`develop` |
| `validate-skill-frontmatter.sh` | Skill file written | Skill frontmatter schema |
| `validate-skill-change.sh` | Skill file written | Advises `/skill-test` after skill edits |
| `track-request-changes.sh` | `request.md` edit | Requires a `request-history.md` entry |
| `pre-compact.sh` / `post-compact.sh` | Compaction | Preserve and restore session state |
| `log-agent.sh` / `log-agent-stop.sh` | Agent start/stop | Audit trail per invocation |
| `notify.sh` | Notification | Desktop notification on completion |
| `session-stop.sh` | Session end | Final session logging |

Hooks are advisory where judgement is involved and hard where data loss is at stake
(commit validation, request tracking).

### Context resilience

**Session state:** `production/apps/<app>/session-state/active.md` is a living
checkpoint. Update it after each milestone; read it first after any disruption
(compaction, crash, `/clear`).

**Incremental writing:** write each approved section to disk immediately, so
decisions survive compaction and the conversation can be safely shortened.

**Sprint tracking:** `production/sprint-status.yaml` is the machine-readable story
tracker — written by `/sprint-plan` and `/story-done`, read by `/sprint-status`,
`/help` and `/story-done`. No fragile markdown scanning.

### Brownfield adoption

```
/project-stage-detect   → what exists, what is claimed, what is missing
/adopt                  → format audit, gaps by severity, ordered migration plan
/reverse-document       → docs inferred from existing code
```

`/adopt` distinguishes "file exists" from "file has the required internal
structure", classifies gaps BLOCKING / HIGH / MEDIUM / LOW, and writes
`docs/adoption-plan-<date>.md`. Migration, not replacement: it fills gaps and never
regenerates existing work. Individual skills support retrofit mode too —

```
/architecture-decision retrofit docs/architecture/apps/<app>/ADR-0003-old.md
```

### Gate system

Five gates, recorded in `apps/<app>/approvals.json`:

| Gate | Judged at the end of |
|------|----------------------|
| `gate-1-research` | research + UX specs |
| `gate-2-prototype` | prototype review |
| `gate-3-scope` | epics, stories, sprint |
| `gate-4-release` | release + App Store checklists |
| `gate-5-update` | applied update set |

**Verdicts:** PASS / CONCERNS / FAIL, all advisory — you decide whether to proceed.
An unrecorded gate is not an approved gate: `/project-stage-detect` and `/help` read
`approvals.json`, not your memory.

### Reverse documentation

```
/reverse-document apps/order-tags
```

For code that exists without docs: reads the implementation, infers intent, asks
about the ambiguous decisions, and writes the missing design doc or ADR. It never
invents a rationale — it asks.

---

## Appendix A: Agent Quick-Reference

### "I need X — which agent?"

| I need to... | Agent |
|--------------|-------|
| Decide what to build next | `product-director` |
| Decide how to build it | `technical-director` |
| Plan the pipeline, gates, milestones | `producer` |
| Implement and review code | `lead-engineer` |
| Market and competitor research | `research-specialist` |
| App architecture, data model, boundaries | `app-architect` |
| Admin API surface, versions, deprecations | `api-lead` |
| GraphQL cost, pagination, bulk operations | `graphql-specialist` |
| Webhook subscriptions, HMAC, retries | `webhooks-specialist` |
| OAuth, session tokens, embedded security | `auth-specialist` |
| Billing API, plans, gating | `billing-specialist` |
| Polaris components, admin UX build | `polaris-specialist` |
| Admin UX design and review | `ux-lead` |
| App Bridge, embedded navigation | `app-bridge-specialist` |
| Theme app extension, Liquid, app blocks | `liquid-specialist` |
| Checkout UI extensions, function limits | `checkout-specialist` |
| Accessibility on admin surfaces | `accessibility-specialist` |
| Security review, data handling | `security-specialist` |
| Performance, latency, rate limits | `performance-analyst` |
| Test strategy, quality gates | `qa-lead` |
| Run tests on a dev store | `qa-tester` |
| Dev test store setup and seed data | `test-store-manager` |
| Hosting, CI/CD, environments | `devops-engineer` |
| Durable prototypes | `prototype-builder` |
| Release, versioning, submission | `release-manager` |
| App Store requirements, listing review | `app-store-reviewer` |
| Pricing, packaging, install funnel | `growth-lead` |
| Usage events and merchant metrics | `analytics-engineer` |
| Localization and markets | `localization-lead` |
| CLI scripts, dev-store automation | `tools-engineer` |
| Merchant comms, review responses | `community-manager` |

### Roster by tier

**Tier 1 (4):** `product-director`, `technical-director`, `producer`, `lead-engineer`

**Tier 2 (12):** `research-specialist`, `app-architect`, `api-lead`, `ux-lead`,
`polaris-specialist`, `qa-lead`, `release-manager`, `devops-engineer`,
`prototype-builder`, `growth-lead`, `analytics-engineer`, `performance-analyst`

**Tier 3 specialists (12):** `graphql-specialist`, `webhooks-specialist`,
`billing-specialist`, `auth-specialist`, `app-bridge-specialist`,
`liquid-specialist`, `checkout-specialist`, `security-specialist`,
`tools-engineer`, `localization-lead`, `app-store-reviewer`, `test-store-manager`

**Tier 3 execution (3):** `qa-tester`, `accessibility-specialist`,
`community-manager`

### Model tiers

Agent frontmatter declares `haiku`, `sonnet` or `opus`. Codex maps these through
`.codex/agent-models.toml`; Hermes resolves them from the active profile's
`delegation` section. The mapping changes *execution*, never the instructions.

---

## Appendix B: Skill Quick-Reference

66 skills, each a directory under `.claude/skills/`.

### Onboarding and navigation (7)

`start`, `help`, `project-stage-detect`, `kanban-status`, `onboard`, `adopt`,
`brainstorm`

### Request and scope (7)

`update-request`, `mmmvp-proposals`, `quick-design`, `design-review`, `scope-check`,
`feature-request`, `bug-report`

### Research and UX (5)

`research`, `update-research`, `ux-design`, `ux-review`, `localize`

### Architecture (5)

`create-architecture`, `architecture-decision`, `architecture-review`,
`create-control-manifest`, `consistency-check`

### Prototype (3)

`prototype`, `build-prototype`, `prototype-review`

### Planning (6)

`create-epics`, `create-stories`, `estimate`, `sprint-plan`, `sprint-status`,
`milestone-review`

### Build (5)

`dev-story`, `code-review`, `story-done`, `story-readiness`, `bug-triage`

### Test and quality (11)

`qa-plan`, `test-setup`, `test-helpers`, `test-evidence-review`, `test-flakiness`,
`smoke-check`, `regression-suite`, `soak-test`, `perf-profile`, `security-audit`,
`retrospective`

### Test store and release (9)

`create-test-store`, `deploy-to-test-store`, `release-checklist`,
`app-store-checklist`, `release`, `launch-checklist`, `changelog`, `patch-notes`,
`hotfix`

### Scaffolding and maintenance (8)

`scaffold`, `tech-debt`, `reverse-document`, `apply-updates`, `propose-updates`,
`gate-check`, `skill-improve`, `skill-test`

---

## Appendix C: Common Workflows

### Workflow 1: "I have no app idea"

```
1. /start
2. /brainstorm            pick a concept
3. /update-request        write it into request.md
4. /research
5. /ux-design, /ux-review
6. /gate-check gate-1-research
```

### Workflow 2: "I have an idea and want to start building"

```
1. /update-request
2. /research → /ux-design → /ux-review → gate-1
3. /scaffold
4. /create-architecture + /architecture-decision (per decision)
5. /create-control-manifest → /architecture-review
6. /build-prototype → /prototype-review → gate-2
```

### Workflow 3: "I have a prototype and want to ship it"

```
1. /prototype-review → gate-2
2. /scope-check
3. /create-epics → /create-stories → /estimate
4. /sprint-plan → /story-readiness → gate-3
5. /dev-story → /code-review → /story-done
6. /qa-plan → /smoke-check → /security-audit
7. /release-checklist → /app-store-checklist → /release → gate-4
```

### Workflow 4: "Something broke in production"

```
1. /bug-report "duplicate tags after a replayed webhook"
2. /bug-triage
3. /hotfix            branch, failing test, fix, release note
4. /smoke-check
5. /retrospective
```

`/hotfix` skips the sprint, never the test.

### Workflow 5: "I have an existing Shopify app and want to use this pipeline"

```
1. /project-stage-detect
2. /adopt                 format audit + ordered migration plan
3. /reverse-document      docs from existing code
4. /architecture-review <app>
5. /gate-check at the gate you believe you are at
```

### Workflow 6: "Starting a new sprint"

```
1. /retrospective
2. /sprint-plan
3. /scope-check
4. /story-readiness       per story, before pickup
5. /dev-story → /code-review → /story-done
6. /sprint-status         quick progress snapshot
```

### Workflow 7: "Shipping a version"

```
1. /release-checklist
2. /app-store-checklist
3. /security-audit
4. /release <app> <version>
5. /changelog + /patch-notes
6. /launch-checklist
7. /gate-check gate-4-release
```

### Workflow 8: "Shopify released a new API version"

```
1. /update-research
2. add docs/shopify-api-reference/<new-version>/ (never edit the old one)
3. /architecture-decision "bump admin API to <new-version>"
4. /architecture-review <app> api
5. /create-control-manifest <app> update
6. /smoke-check → /release
7. /gate-check gate-5-update
```

### Workflow 9: "I'm lost"

```
1. /help                      reads the stage, names the next action
2. /project-stage-detect      full audit when /help disagrees with reality
```

---

## Tips for Getting the Most Out of the System

1. **Run `/help` before asking a question.** It usually answers "what next?".
2. **Read the pinned snapshot, not your model's memory.**
   `docs/shopify-api-reference/` exists because training data is older than the API
   version you ship against.
3. **Let readiness block you.** A story that fails `/story-readiness` fails review
   more expensively later.
4. **Record gates explicitly.** `approvals.json` is the only record later skills
   trust.
5. **Keep requirement IDs flowing.** Story → test → commit message → changelog. That
   chain is what makes `/architecture-review rtm` useful.
6. **Prefer deleting scope over adding time.** The research brief's killed-features
   list exists for exactly this conversation.
7. **Verify on a dev store.** A passing unit test against a mock proves the mock.
8. **Fix the rule, not the line.** When a rule flags a hardcoded API version, the
   fix is to read it from config — not to move the literal.
9. **Write ADRs for the "why".** Future-you needs the rejected alternatives more
   than the chosen one.
10. **Compact proactively.** Around 65–70% context usage, compact or `/clear`. The
    pre-compact hook saves progress; do not wait for the limit.
11. **Use the right tier of agent.** Do not ask `product-director` to fix a webhook
    handler; do not ask `qa-tester` to make a scope decision.
12. **Write to disk early.** The file is the memory, not the conversation.
