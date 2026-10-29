---
name: perf-profile
description: "Profile a Shopify app against the project performance budgets: admin route LCP and interaction latency at p75 under 1.5 s, initial bundle under 250 KB gzipped, GraphQL cost inside bucket capacity, webhook handler p95 under 500 ms. Produces a ranked findings report with measured numbers, not opinions."
argument-hint: "[app: <slug>] [surface: admin | graphql | webhooks | bundle | all]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, AskUserQuestion, request_user_input, clarify
model: sonnet
agent: performance-analyst
---

# Performance Profile

Measure before optimising. Every claim in the output is a number with a
method attached.

**The budgets** (from `.claude/docs/technical-preferences.md` — read it, do not
trust this list if it differs):

| Surface | Budget |
|---------|--------|
| Admin route load, p75, warm session | under 1.5 s |
| Initial admin bundle | under 250 KB gzipped |
| GraphQL | under 50% of leaky-bucket capacity per burst; no query above 500 requested cost without a bulk operation |
| Webhook handler p95 | under 500 ms |
| Install (OAuth round trip) | under 5 s on a dev store |

**Output:** `production/apps/<app>/milestones/perf-<date>.md`
(sprint-scoped profile → `production/apps/<app>/sprints/perf-<date>.md`)

---

## 1. Scope

`surface` argument (default `all`):

- `admin` — route load, LCP, interaction latency, React render cost, Polaris
  DataTable/IndexTable behaviour with realistic row counts.
- `graphql` — per-operation cost, N+1 patterns, missing pagination, batch vs
  loop, bulk operation thresholds.
- `webhooks` — handler p95, synchronous work that should be queued, DB round
  trips per delivery.
- `bundle` — initial route payload, duplicate dependencies, Polaris imports,
  source maps and dev-only code shipped to production.

Read first: `apps/<app>/status.md`, `apps/<app>/shopify.app.toml` (pinned API
version), the app's route tree, and every GraphQL operation file. Skim the last
perf report in `production/apps/<app>/` so a re-profile compares against a
baseline instead of starting over.

---

## 2. Measure — Admin Surface

Target the deployed test environment through the Shopify CLI tunnel (or the
deployed dev environment), in a **warm session inside the embedded admin** —
cold-load numbers inside an iframe are noise.

For each primary route (`/app`, plus each top-level nav item):

1. Load the route 10 times in a warm session; record p50/p75/p95 for:
   - navigation start → LCP
   - navigation start → route interactive (first input with visible response)
   - App Bridge context ready → first data render
2. Interaction latency on the heaviest control (table sort, filter, pagination,
   bulk action) — 10 interactions, p75.
3. Record React commit cost for the primary table mount using the React
   Profiler or the browser performance panel; note components committing more
   than once per data arrival.
4. Note the row count used. A 20-row table proves nothing about a 5,000-variant
   store — profile at the size the served merchants actually have, and state it.

Report the load conditions: session warm/cold, row count, network profile,
whether the app ran from the tunnel or a deployed environment.

---

## 3. Measure — GraphQL Cost

1. For each operation, compute requested cost. Shopify's cost model: object
   fields cost 1, connections cost `first`/`last` plus requested nested cost,
   mutations cost 10 by default. Read the pinned schema and rate-limit notes in
   `docs/shopify-api-reference/<version>/` — do not compute from memory.
2. Flag operations above 500 requested cost (must become a bulk operation) and
   any operation above 25% of a single burst's budget.
3. Look for the classic patterns:
   - a query inside a loop (one call per product/variant/order),
   - `first: 250` used where the UI renders 20 rows,
   - fetching all fields of a heavy object to render one column,
   - no `pageInfo`/cursor handling, so a list silently truncates,
   - retry logic that re-issues the same expensive query on throttle.
4. Measure the burst behaviour: issue the operation repeatedly in a script and
   record throttled responses, `throttleStatus.currentlyAvailable` at each step,
   and the app's recovery time. Correct behaviour waits on the reported restore
   rate; incorrect behaviour hot-loops.

---

## 4. Measure — Webhook Handlers

1. Time the handler from request receipt to response write for each subscribed
   topic, with a signed payload. **p95 under 500 ms** is the budget, and the ack
   must precede slow work.
2. Classify handler work: verification + enqueue is the target shape. Any of
   these inside the handler is a finding:
   - a synchronous Admin API call before the ack,
   - a DB transaction with more than one round trip,
   - a job table write that also walks related rows,
   - a network call to a third party.
3. Count DB queries per delivery by logging the query layer; more than two
   before ack is a finding.
4. Verify the handler does not degrade with payload size (large order with many
   line items, bulk product update).

---

## 5. Measure — Bundle

1. Build production output (`npm run build` in the app) and read the route
   manifest. Record the initial route's transferred size **gzipped**, not raw.
2. Break down by dependency. Common oversized entries:
   - the full Polaris import instead of per-component imports,
   - a moment/lodash-class utility pulled in for one call,
   - duplicate copies of a transitive dependency at different versions,
   - server-only code (or a `@shopify/shopify-api`-class package) reaching the
     client bundle,
   - source maps or dev branches shipped in a production build.
3. Confirm budgets per route, and that the app has no bundle larger than 250 KB
   gzipped on the entry route. Non-entry chunks are reported but not gated.

---

## 6. Report

```markdown
# Performance Profile — <app>

> Date: <date> | Commit: <sha> | Environment: <tunnel | deployed test>
> Row count / data scale: <n> | Session: warm | Generated by: /perf-profile

## Budget scorecard

| Surface | Budget | Measured | Verdict |
|---------|--------|----------|---------|
| Admin route p75 (heaviest route) | 1.5 s | | PASS/FAIL |
| Interaction p75 (heaviest control) | — | | note |
| Initial bundle (gzip) | 250 KB | | PASS/FAIL |
| Heaviest GraphQL operation cost | 500 (bulk above) | | PASS/FAIL |
| Webhook handler p95 | 500 ms | | PASS/FAIL |
| Install round trip | 5 s | | PASS/FAIL |

## Per-route detail
| Route | LCP p75 | Interactive p75 | Notes |

## GraphQL operations
| Operation | Requested cost | Called in loop? | Finding |

## Webhook handlers
| Topic | p95 | Work before ack | Finding |

## Bundle
| Chunk | Gzip | Contents of note |

## Findings (ranked by user-visible impact)

| ID | Surface | Finding | Measured | Target | Fix | Effort |
|----|---------|---------|----------|--------|-----|--------|
| PERF-001 | admin | | | | | S/M/L |

## Baseline comparison
| Metric | Last profile (<date>) | Now | Δ |

## Verdict: WITHIN BUDGET / OVER BUDGET (ranked list)
```

Ranking rule: a violation on the merchant's primary path outranks a larger
violation on a rarely visited settings page. State the ordering rationale.

---

## 7. Write and Route

Ask: *"May I write this profile to
`production/apps/<app>/milestones/perf-<date>.md`?"*

Then route each finding:
- GraphQL cost/pagination/N+1 → `graphql-specialist`
- Render cost, Polaris table behaviour → `polaris-specialist`
- Bundle composition, build config → `lead-engineer` (with `devops-engineer`
  for build pipeline changes)
- Handler shape, queueing, DB round trips → `webhooks-specialist` /
  `devops-engineer`
- Anything that changes a budget → `technical-director`, and record the new
  budget in the ADR that governs it.

A perf FAIL is not automatically a release blocker — but a violation on the
primary merchant path is, and only `technical-director` can waive it. Record
the waiver in the report if granted.

---

## Method Rules

- **Warm session, embedded, realistic data.** Otherwise the numbers describe a
  scenario no merchant has.
- **p75, not best-of.** One fast run is not a measurement.
- **Profile the deployed build**, not a dev server with HMR overhead.
- **Never quote a number you did not capture this run.** Carrying a stale figure
  forward silently is how regressions ship.
- **No optimisation in this skill.** This produces findings; changes go through
  a story and `code-review`.
