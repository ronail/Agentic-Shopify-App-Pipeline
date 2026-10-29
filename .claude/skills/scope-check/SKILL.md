---
name: scope-check
description: "Guard against scope creep: compare planned and in-flight work for one app against request.md and its request history, classify every delta as in-scope, adjacent, or creep, and require a recorded change request before creep is built. Run before gate-3-scope and at every sprint boundary."
argument-hint: "[app: <slug>] [--sprint | --gate | --release]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, request_user_input, clarify
model: sonnet
agent: product-director
---

# Scope Check

Scope creep rarely arrives as a big new feature. It arrives as six reasonable
small additions that nobody recorded, and then the milestone slips and the
merchant problem the request described is still unsolved.

**This skill compares what is being built with what was asked for, and names the
gap.** It does not decide product direction; `product-director` does, and the
decision gets written down.

**Output:** conversation report (plus, if approved,
`production/apps/<app>/milestones/scope-check-<date>.md`).

---

## 1. Load the Baseline

The baseline is the **request**, not the current plan. Read:

- `request.md` — the master request: the merchant problem, the requested
  behaviour, explicit non-goals.
- `request-history.md` — every recorded change to the request, in order.
- `apps/<app>/request-history.md` — the app-local history, if present.
- `docs/architecture/apps/<app>/requirements.yaml` — the requirement ids derived
  from the request.
- `apps/<app>/status.md` — stage and blockers.

Then load what is actually being built:

- `production/apps/<app>/sprints/` — sprint plans and story lists.
- `docs/architecture/apps/<app>/` — ADRs, which encode decisions taken beyond
  the request.
- `apps/<app>/` — what the code and routes actually implement.

If `request.md` does not name this app or this behaviour, stop: the work has no
baseline, and that is the finding. Do not reconstruct a baseline from the plan.

---

## 2. Build the Comparison Table

One row per unit of work (story, route, feature, requirement id):

| # | Work item | Source (story/adr/code) | Requested where (request.md § / REQ-id) | Class | Note |

Classification:

- **In-scope** — directly requested, or unambiguously required to deliver what
  was requested (auth, session handling, the migration that stores the setting).
- **Adjacent** — plausibly useful, not requested; for example a settings page
  for a value the request implies, or an export the request did not mention.
  Adjacent work needs a recorded decision to proceed.
- **Creep** — new merchant-facing surface, new scope, new API area, new billing
  tier, or a rewritten approach that changes the request's promise. Creep needs
  a change request in `request.md` + `request-history.md` before it is built.

Bias: if you cannot point at the sentence or requirement id that asks for it,
it is not in-scope. "The user will obviously want it" is not a citation.

---

## 3. Detect the Specific Failure Modes

- **Silent additions** — code/routes that exist with no story and no request
  line. Highest risk: they ship untested and unpriced.
- **Scope inflation by adjective** — "with filters, sorting, bulk actions, and
  CSV export" where the request said "a list of bundles". Each noun is a row.
- **Gold-plating** — abstraction layers, plugin systems, configurable everything
  for a single-tenant problem.
- **Requirement drift** — `requirements.yaml` ids that no longer match the
  request, or ids that were renumbered. Never renumber; append.
- **Platform hunting** — adding a surface (theme extension, checkout extension,
  POS, customer account) that the request did not ask for. Each surface has its
  own review, scope, and App Store implications.
- **Silent cuts** — requested behaviour quietly dropped. A cut is a scope change
  too, and a worse one: the merchant asked for it. Requires a recorded decision
  and, usually, telling the requester.
- **Estimate laundering** — a story whose point value grew while its title
  stayed the same. Compare sprint-to-sprint.

---

## 4. Report

```markdown
# Scope Check — <app>

> Date: <date> | Mode: sprint | gate | release | Commit: <sha>
> Baseline: request.md (last changed <date>, <n> history entries)

## Request summary
<3 lines: the merchant problem, the requested behaviour, the stated non-goals>

## Comparison

| # | Work item | Source | Requested where | Class | Note |
|---|-----------|--------|-----------------|-------|------|
| 1 | Create percentage bundle | story-3 | request.md §2 | in-scope | |
| 2 | CSV export of bundles | route /app/export | — | creep | no request line, no story |
| 3 | Currency formatting | story-5 | request.md §2 "prices in the merchant's currency" | in-scope | implied by requirement |

## Counts
in-scope: <n> | adjacent: <n> | creep: <n> | requested-but-missing: <n>

## Requested but not built
| Request line | Status | Decision recorded? | Owner |

## Decisions needed
| # | Item | Class | Question for product-director | Recommended |
|---|------|-------|-------------------------------|-------------|

## Verdict: IN SCOPE / DRIFT (n items) / OUT OF CONTROL
```

Verdict thresholds:
- **IN SCOPE** — no creep, no unrecorded cuts.
- **DRIFT** — creep or cuts exist but each has a path: a change request to write,
  a decision to record, or code to remove.
- **OUT OF CONTROL** — creep is already shipped to the test store, or requested
  behaviour is missing with no decision recorded. This blocks `gate-3-scope` and
  the release gate until reconciled.

---

## 5. Resolution Paths

For each **creep** item, exactly one outcome:

1. **Cut it** — remove the code before it reaches a merchant. Cheapest, and the
   default for anything already classified creep.
2. **Absorb with a change request** — append the request to `request.md`,
   append the entry to `request-history.md` (the request-tracking hook enforces
   this), then derive a requirement id in `requirements.yaml`. Only then does it
   become in-scope.
3. **Defer** — record it in the app's request history as a future candidate with
   the reason. Not built now, not forgotten.

For each **silent cut**, the outcome is a decision recorded with the requester
informed — not a quiet removal from the story list.

Escalate to `product-director` when: the request itself is ambiguous, two
requirements conflict, or the cut was of something the requester explicitly
asked for.

---

## 6. When to Run

- Before `gate-3-scope` — mandatory; scope is what that gate freezes.
- At each sprint boundary (`--sprint`) — the cheap, frequent check.
- Before `gate-4-release` (`--release`) — verify nothing crept in during build.
- Any time a story appears that nobody remembers planning.

Ask before writing a report file. A scope report that becomes a permanent doc
should live with the milestone it gated, not in a top-level log.
