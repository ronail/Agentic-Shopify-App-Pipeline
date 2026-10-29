---
name: soak-test
description: "Design an extended stability soak for one Shopify app on a dev store — sustained webhook throughput, GraphQL rate-limit pressure, and memory growth over time. Produces the run protocol and analysis harness; the run itself is executed by a person or a load script. Run before gate-4-release and after any leak, throttle, or timeout fix."
argument-hint: "[duration: 30m | 1h | 2h | 4h] [focus: memory | webhooks | rate-limits | all] [app: <slug>]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash, AskUserQuestion, request_user_input, clarify
model: sonnet
agent: devops-engineer
---

# Soak Test

A soak test keeps one app running under realistic continuous load for **30
minutes to several hours** and watches for problems that only appear after
sustained operation. It is not a smoke check (broad critical path, ~10 minutes)
and not a regression run (deterministic tests). A soak answers:

- **Memory growth** — heap and RSS climbing across webhook bursts and admin
  route loads, from retained request context, unbounded caches, or session
  objects that never expire.
- **Rate-limit behaviour under pressure** — does the app back off correctly when
  the Admin GraphQL leaky bucket drains, or does it retry-storm and get worse?
- **Webhook throughput decay** — handler p95 drifting above 500 ms as the queue
  backs up, or deliveries piling up unacknowledged.
- **Connection/pool exhaustion** — Postgres pool saturation, socket leaks,
  unclosed tunnels.
- **Scheduled-work drift** — cron/worker jobs that overlap, duplicate, or fall
  behind over hours.
- **Session and token hygiene** — session tokens refreshing without leaking,
  offline tokens not re-requested per call.

**This skill generates the protocol and the analysis harness. The run is done by
a human following the protocol, or by a checked-in load script — never
improvised live.**

**Output:** `production/apps/<app>/sprints/soak-<date>-<duration>.md`
(pre-release soaks attach to a milestone instead:
`production/apps/<app>/milestones/<milestone>/soak-<date>.md`)

**When to run:**
- Before `gate-4-release` for any app that consumes webhooks or runs jobs.
- After fixing a memory leak, a throttle storm, or a queue backlog.
- After a dependency upgrade that touches the HTTP client, DB driver, or queue.
- After the app's first real merchant-like data volume lands on the dev store.

---

## 1. Parse Arguments

**Duration** (default `1h`):
- `30m` — single-surface soak; e.g. webhook handlers only.
- `1h` — standard; catches most retention and pool issues.
- `2h` — first full soak for an app with background jobs or bulk operations.
- `4h` — apps with long-running syncs, large catalogs, or nightly job windows.

**Focus** (default `all`):
- `memory` — heap/RSS trend, object retention, cache bounds.
- `webhooks` — delivery throughput, ack latency, retry and duplicate handling.
- `rate-limits` — GraphQL cost vs bucket capacity, backoff correctness.
- `all` — everything above plus queue and DB pool health.

**App** — required. If omitted, read `docs/registry/apps.json`; if exactly one
entry has a non-terminal `stage`, use it, otherwise ask.

---

## 2. Load Context

Read, in this order:

- `apps/<app>/status.md` — current stage and known blockers.
- `apps/<app>/approvals.json` — which gates are already approved.
- `.claude/docs/technical-preferences.md` — the budgets the soak judges against:
  - Admin route load p75 under 1.5 s
  - Webhook handler p95 under 500 ms
  - GraphQL cost under 50% of bucket capacity per request burst
  - DB, hosting, queue shape (long-lived Node process required)
- `docs/shopify-api-reference/<version>/` — the pinned Admin API version for
  this app, its rate-limit notes and any documented cost tables. The app's
  version is in `apps/<app>/shopify.app.toml`; they must match. If the snapshot
  directory is missing, stop and report the mismatch instead of guessing costs.
- Every GraphQL operation file in `apps/<app>/` — record each operation's
  requested cost so the load profile can quote a real number.
- `apps/<app>/shopify.app.toml` — subscribed webhook topics and API scopes.
- The most recent file in `production/apps/<app>/sprints/` — prior soak or
  regression results, so known issues are not re-filed as new.

Record a small budget table in the protocol header:

| Budget | Target | Source |
|--------|--------|--------|
| Admin route p75 | 1.5 s | technical-preferences |
| Webhook handler p95 | 500 ms | technical-preferences |
| GraphQL burst cost | < 50% of bucket | technical-preferences |
| Bundle (initial route) | 250 KB gz | technical-preferences |

---

## 3. Build the Load Profile

The soak must reproduce the app's real traffic mix, not a synthetic worst case.

**Webhook traffic** — for each topic in `shopify.app.toml`:
- Choose a realistic rate for the store size (a solo merchant store produces
  bursts of `orders/create` at checkout, near-zero overnight).
- Include the lifecycle topics that break apps when missed:
  `app/uninstalled`, `app_subscriptions/update`, `shop/redact`,
  `customers/redact`, `customers/data_request`.
- Generate deliveries with a script that signs the payload with the app's
  webhook secret (HMAC-SHA256 over the raw body) and posts to the tunnel URL.
  Never point load at a production store.
- Record: deliveries/min, ack p50/p95, non-2xx count, duplicate count,
  deliveries that needed manual retry.

**GraphQL pressure** — for each operation:
- Compute requested cost; note which operations approach 500 (the threshold
  above which a bulk operation is required).
- Drive a burst that intentionally drains the bucket, and verify the app
  observes `throttleStatus`/`extensions.cost`, waits for restore, and does not
  hot-loop. Backoff that ignores `currentlyAvailable`/`restoreRate` is a fail.
- Record: throttled responses, retry attempts per operation, time to recover,
  any operation that escalated cost on retry.

**Admin surface** — repeated navigation across the app's primary routes in the
embedded admin, on the dev store, in a warm session:
- Route load p75, interaction latency on the heaviest list/table view,
  repeated mount/unmount of the same route (React leak canary).

**Background work** — trigger the queue drain repeatedly and confirm:
- no duplicate processing of the same job id,
- no unbounded row growth in the job table,
- worker memory stable across drains.

---

## 4. Define Checkpoints

Timed checkpoints keep observations comparable. Use:

- `30m` → T+0, T+10, T+20, T+30
- `1h` → T+0, T+15, T+30, T+45, T+60
- `2h` → T+0, T+20, T+40, T+60, T+80, T+100, T+120
- `4h` → T+0, T+30, T+60, T+90, T+120, T+180, T+240

At T+0 record a baseline **after** one warm-up burst, not on a cold process —
cold-start allocation is not a leak.

---

## 5. Protocol Template

```markdown
# Soak Test Protocol — <app>

> Date: <date> | Duration: <duration> | Focus: <focus>
> Store: <dev store handle> | API version: <version> | Generated by: /soak-test

## Pre-Run Setup

- [ ] App deployed to the dev store via `shopify app deploy`; tunnel is the
      target, not a production URL
- [ ] `shopify app dev` or the deployed test environment is on the commit under
      test — record the commit hash
- [ ] Webhook signing secret exported for the load script; secret never echoed
      to logs or the report
- [ ] Memory sampling armed (`node --inspect`, heap snapshot at T+0 and at the
      final checkpoint)
- [ ] Postgres pool size and queue depth queryable
- [ ] Known issues carried in from: <prior report path>

## Baseline — T+0 (after warm-up burst)

| Metric | Baseline |
|--------|----------|
| Heap used / RSS | |
| Active DB connections | |
| Queue depth | |
| Webhook ack p95 | |
| GraphQL bucket available | |

## Checkpoint T+<N>

**Webhooks**
- Deliveries since last checkpoint: <n> | non-2xx: <n> | duplicates: <n>
- Ack p50 / p95: <ms> / <ms>  (budget 500 ms)

**GraphQL**
- Throttled responses: <n> | retries: <n> | recovery time: <s>
- Cost of heaviest operation: <n> (budget: < 500 without bulk op)

**Resources**
| Metric | Value | Δ vs baseline | Alert |
|--------|-------|---------------|-------|
| Heap used | | | |
| RSS | | | |
| DB connections | | | |
| Queue depth | | | |

**Admin surface**
- Route load p75: <ms> | interaction p75: <ms>
- Errors / blank states observed: <none | describe>

**Free observations** — anything unexpected since the last checkpoint.

## Post-Run Analysis

### Growth trend
| Checkpoint | Heap | Extrapolated 24 h | Verdict |
|------------|------|-------------------|---------|

Leak suspected: Y / N. Basis: <monotonic growth across 3+ checkpoints, retained
objects in heap diff, or flat line>.

### Throughput trend
Ack p95 at first checkpoint vs last. Decay beyond 2x = fail.

### Issues

| ID | Severity | Checkpoint | Description | Owner |
|----|----------|------------|-------------|-------|
| SOAK-001 | S1–S4 | T+<n> | | |

## Verdict: PASS / PASS WITH CONCERNS / FAIL

- PASS — no growth trend, ack p95 inside budget, backoff correct, no leaks.
- PASS WITH CONCERNS — drift under 2x, bounded growth explained by cache, or a
  single recovered throttle storm. Must be ticketed with an owner and a date.
- FAIL — monotonic growth, ack p95 over budget at any checkpoint, retry storm,
  duplicate job processing, or any 5xx sustained over a checkpoint interval.
```

---

## 6. Write, Then Hand Off

Present the protocol summary in conversation. Ask: *"May I write this soak
protocol to `production/apps/<app>/sprints/soak-<date>-<duration>.md`?"* Write
only after approval.

Then report:

1. Run the protocol top to bottom; fill each checkpoint as you go.
2. File every issue found as a row in the report and, if S1/S2, as a ticket in
   the app's sprint record.
3. If the verdict is FAIL, the app is **not** eligible for `gate-4-release` —
   run `/gate-check gate-4-release <app>` again only after the fix and a
   re-soak of the affected focus area.
4. Attach the report path to the release milestone when the verdict is PASS.

---

## Anti-Patterns

- **Soaking production.** This runs against a dev store with signed synthetic
  traffic. If someone asks for a production soak, escalate to `devops-engineer`
  and `security-specialist` — it is not a skill-level decision.
- **Cold-start baseline.** A baseline taken before warm-up always looks like a
  leak.
- **Judging memory by a single checkpoint.** One spike is GC; three rising
  checkpoints is a leak.
- **Load without signatures.** Unsigned webhook traffic only exercises the 401
  path and proves nothing about handler cost.
- **Load above what any served store could produce.** It measures the load
  generator, not the app.
