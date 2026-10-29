---
name: tech-debt
description: "Maintain one app's tech-debt register in docs/architecture/apps/<app>/tech-debt.md: capture entries with evidence, price the interest per sprint, rank by merchant risk, and stop the list from becoming a graveyard. Use at sprint review, before release, and when a shortcut is taken."
argument-hint: "[app: <slug>] [scan | add | rank | paydown] [--sprint]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, AskUserQuestion, request_user_input, clarify
model: sonnet
agent: technical-director
---

# Tech Debt

Debt is a deliberate trade: you take on interest now to ship value sooner. It
becomes a problem in exactly two ways — when nobody wrote it down, and when the
interest is never paid.

**Register:** `docs/architecture/apps/<app>/tech-debt.md` (one per app, lives
with the architecture docs because the entries constrain architecture).

**Modes:**
- `scan` — find debt in the code and record what is not already listed.
- `add` — record one entry with evidence (the common case during a sprint).
- `rank` — re-rank the register and pick the paydown set for the next sprint.
- `paydown` — plan a paydown sprint against a ranked subset.

---

## 1. Entry Shape

Every entry, without exception:

```markdown
### TD-<app>-<NNN> — <short imperative title>

- **Area**: admin-ui | app-server | graphql | webhooks | billing | auth | data | build | docs
- **Introduced**: <date or commit sha> — <what change took the shortcut>
- **Evidence**: `path/to/file.ts:120` — <what is wrong, factually>
- **Interest**: <what it costs every sprint: slower changes, a bug class, an
  on-call page, a blocked feature>
- **Merchant risk**: high | medium | low — <who notices, and when>
- **Payoff**: <what becomes possible or cheaper once paid>
- **Effort**: S (< half day) | M (1–3 days) | L (> 3 days)
- **Owner**: <agent or role>
- **Status**: open | scheduled(<sprint>) | paid(<date, commit>) | accepted-risk(<approver>, <review date>)
```

Rules:
- No entry without evidence. "The code is messy" is not debt; "my-app
  repository builds SQL by string concatenation at
  `apps/my-app/src/db/orders.ts:88`" is.
- No entry without interest. If it costs nothing per sprint and risks nothing,
  it is a preference, not debt.
- `accepted-risk` requires an approver and a review date. Accepted risk expires;
  then it is open again.
- Ids are stable and never reused. `TD-<app>-<NNN>` is monotonic; a deleted
  entry keeps its number.

---

## 2. Scan — Where Debt Actually Hides

Look for these, in this order of consequence:

**Correctness/security class (highest)**
- Webhook handlers that parse before verifying, or verify per-route with a
  subtly different implementation.
- Session token decoded, not verified; missing `aud`/`exp`/`dest` checks.
- Admin API calls from the browser, or a client-trusted entitlement flag.
- Queries missing the shop scoping predicate.
- String-built SQL; unvalidated payloads reaching the query layer.
- Access tokens stored or logged in plaintext.

**Reliability class**
- Synchronous external calls before a webhook ack.
- Retry loops without backoff on throttle; fixed sleeps.
- Unbounded tables (jobs, events, delivery logs) with no prune.
- Fire-and-forget promises with no error path.
- Migrations that cannot roll back.

**Velocity class**
- Duplicated GraphQL documents with slightly different field sets.
- Business logic in route handlers instead of a module with tests.
- Hand-rolled formatting instead of `Intl`; hardcoded currency or timezone.
- A shared module under `src/` that every app imports and only one app needs.
- Tests that assert implementation details, so every refactor breaks them.

**Hygiene class (lowest)**
- Dead routes, unused scopes, commented-out blocks.
- Hardcoded API version outside `shopify.app.toml`.
- Docs that describe a flow the code no longer has.

For each finding, check the register first. Duplicate entries are worse than
missing ones — the register loses credibility fast.

---

## 3. Rank — Price the Interest

Rank by a simple, defensible function:

```
priority = merchant_risk × frequency × reach ÷ effort
```

- **merchant_risk** — high 3, medium 2, low 1. Anything in the
  correctness/security class is high by default.
- **frequency** — how often the affected path runs: every request 3, every
  checkout/webhook 2, rarely 1.
- **reach** — one app 1, every app via `src/` 3, every merchant 3.
- **effort** — S 1, M 2, L 3.

Do not invent decimals. The point is a defensible order, not a fake metric. Show
the inputs so someone can disagree with the ranking rather than the list.

Tie-break, in order: security exposure, blast radius on the merchant's primary
path, effort (smaller first), age (older first).

---

## 4. Report / Update

```markdown
# Tech Debt — <app>

> Last updated: <date> | Open: <n> | Accepted risk: <n> | Paid: <n>

## Summary
| Area | Open | Highest priority | Interest per sprint |

## Ranked register

| Rank | Id | Title | Area | Merchant risk | Effort | Interest | Status |

## Detail
<entries in Id order, full shape>

## Paydown plan (next sprint)
| Id | Why now | Effort | Owner | Verification |

## Paid this period
| Id | Paid in commit | Verification | Register updated |
```

Verification of a paid item is a test, a check, or a cited diff — not "cleaned
up". An item marked paid without verification goes back to open.

---

## 5. Paydown Discipline

- **Cap the debt budget.** No more than ~20% of a sprint unless
  `product-director` approves more. Debt work that silently eats a sprint is how
  roadmaps die.
- **Pay the interest, not the principal, when time is short.** Example: add the
  missing shop-scope predicate even if the query layer stays ugly.
- **Never mix a paydown with a feature.** A paydown story that also adds a
  feature cannot be reviewed or reverted cleanly.
- **Security-class debt is not optional.** A Critical/High correctness or
  security entry is paid before the next release gate, or explicitly waived by
  `technical-director` with a compensating control recorded in the register.
- **Retire accepted risks on schedule.** An accepted risk past its review date
  is an open item — say so at sprint review.

---

## 6. Write Rules

- Append and update entries; never delete one. Paid entries keep their row and
  move status.
- Create `docs/architecture/apps/<app>/tech-debt.md` on first use with the
  header and an empty register.
- Ask before the first write and before any bulk edit: *"May I update the tech
  debt register at `docs/architecture/apps/<app>/tech-debt.md`?"* Individual
  `add` operations during a sprint can be batched into one approval at sprint
  review.
- Do not create a repo-level debt file. Debt is per app; a shared list becomes a
  place to avoid deciding.

---

## Boundary

- Debt entries are findings, not commits. Fixes go through a story, `code-review`,
  and tests beside the source.
- Architecture-level debt (a decision that needs revisiting) belongs in
  `/architecture-decision`, with the register entry linking to the ADR.
- Cross-app debt in `src/` gets one entry per affected app, each linking to the
  shared fix — do not let one app's register imply another app owns it.
