---
name: regression-suite
description: "Run the full Vitest regression suite across one app and shared code, with coverage gates on billing and webhook verification. Selects tests by changed surface, triages flakes instead of retrying blindly, and produces a PASS/FAIL report suitable as release evidence."
argument-hint: "[app: <slug> | all] [--changed | --full] [--coverage]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, AskUserQuestion, request_user_input, clarify
model: sonnet
agent: qa-lead
---

# Regression Suite

The deterministic half of quality: everything that can be executed without a
human. Smoke check proves the deployed app still works; regression proves the
committed code still behaves.

**Output:** `production/apps/<app>/sprints/regression-<date>.md`
(`all` mode writes one report at `production/session-state/regression-<date>.md`
and per-app sections inside it.)

**Rules of the suite:**
- Tests live **beside the source they cover**, inside `apps/<app>/` —
  `discount.ts` and `discount.test.ts` in the same folder. There is no top-level
  `tests/` directory; if one appears, it is a regression in project structure,
  not a test target.
- Framework is Vitest. Shared code in `src/` is covered by tests beside it too.
- Coverage floor: **80% lines on shared modules, 100% on billing and on webhook
  signature verification**. Those two are not negotiable — a miss there is a
  security or revenue bug, not a coverage number.

---

## 1. Parse Arguments

- `--changed` (default) — run tests related to files changed since the last
  approved gate or since `origin/main`, then widen if the diff touches shared
  code, auth, billing, or webhook routes.
- `--full` — the whole suite for every in-scope app. Required as release
  evidence for `gate-4-release`.
- `--coverage` — collect coverage and enforce the floors above.
- `app: <slug> | all` — scope. `all` is a repo-wide sweep, allowed only in
  `--full` mode to keep it meaningful.

---

## 2. Build the Target Set

1. Read `docs/registry/apps.json` for the app list; read each
   `apps/<app>/status.md` for stage. An app still in `research` with no code has
   nothing to regress — record it as `N/A — no implementation` rather than
   failing.
2. Determine the changed set:
   - `git diff --name-only <base>...HEAD`
   - `git status --porcelain` for uncommitted work, if the run is pre-commit.
3. Map changed files to tests:
   - A changed `*.ts`/`*.tsx` → its sibling `*.test.ts(x)`.
   - A changed GraphQL document → the module that shapes its variables and the
     tests for that module.
   - A changed webhook route → the handler test **and** the signature
     verification test.
   - A changed migration or query layer → the integration tests that touch the
     repository module.
   - Anything under `src/` → every app that imports it. Shared-code changes are
     cross-app by definition; say so in the report.
4. Widen to `--full` automatically if the diff touches: `package.json`,
   lockfile, `tsconfig*`, Vitest config, auth/session modules, billing modules,
   webhook signature verification, or a pinned API version in
   `shopify.app.toml`.

---

## 3. Execute

Run per app from the app's package root so path aliases resolve:

```bash
# unit + integration for one app
npm test -- --run

# focused run on the derived target set
npx vitest run <space-separated test files>

# coverage with thresholds
npx vitest run --coverage
```

Capture, per app:
- test files run, tests passed/failed/skipped
- duration and the slowest three tests
- coverage: lines, branches, and specifically the billing and webhook-signature
  modules
- full failure output for every failing test — assertion diff, not just the name

If a test suite cannot start (config error, missing env), that is a **FAIL with
reason `suite failed to start`**, not a skip. Report the first error verbatim.

---

## 4. Triage Failures — Do Not Retry to Green

For each failure, classify before touching anything:

| Class | Signal | Action |
|-------|--------|--------|
| Real regression | Assertion diff matches a recent change in the mapped source file | Report as S1/S2; route to the owning specialist |
| Flake | Passes on isolated re-run, or fails only under parallel load, or depends on wall clock/random/network | Quarantine: file with reproduction, do not delete; note in report |
| Environment | Missing env var, wrong API version fixture, unreachable tunnel | Fix the harness, then re-run once |
| Test bug | Test asserts something the spec never promised | Fix the test in the same change as the code intent |

Rules:
- One isolated re-run is allowed to classify; a third attempt is not evidence.
- Never widen a timeout to make a failure disappear. A test that needs 30 s is
  an integration test — label it, do not paper over it.
- Never mark a failing test `.skip` to get a PASS verdict. Quarantine must be
  visible in the report with an owner.
- Shared-code failures count against every app that imports the module; list
  them under each affected app.

---

## 5. Report

```markdown
# Regression Suite — <app | all>

> Date: <date> | Commit: <sha> | Mode: changed | full
> Base for diff: <ref> | Coverage: on | off | Generated by: /regression-suite

## Scope decision
Changed files: <n>. Widened to full? Y/N — reason: <shared code | config |
auth/billing/webhook | pinned API version>.

## Results per app

### <app>
| Metric | Value |
|--------|-------|
| Test files | |
| Passed / Failed / Skipped | |
| Duration | |
| Coverage (lines) | |
| Billing module coverage | (must be 100%) |
| Webhook signature coverage | (must be 100%) |

**Failures**
| Test | Class (regression/flake/env/test bug) | Evidence | Owner |
|------|--------------------------------------|----------|-------|

## Cross-app impact
Files under `src/` changed: <list> → apps affected: <list>.

## Quarantined
| Test | Since | Reason | Owner | Ticket |
|------|-------|--------|-------|--------|

## Verdict: PASS / PASS WITH QUARANTINE / FAIL
```

Verdict rules:
- **PASS** — zero failures, coverage floors met.
- **PASS WITH QUARANTINE** — only flakes or environment failures, each listed
  with an owner and a ticket; no real regression; coverage floors met.
- **FAIL** — any real regression, any billing/webhook-signature test failing,
  coverage below floor, or a suite that could not start.

---

## 6. Write and Hand Off

Ask: *"May I write this regression report to
`production/apps/<app>/sprints/regression-<date>.md`?"*

Then:
1. Route failures by file type — `*.tsx` Polaris → `polaris-specialist`,
   GraphQL → `graphql-specialist`, webhook → `webhooks-specialist`, billing →
   `billing-specialist`, auth/session → `auth-specialist`, migrations/infra →
   `devops-engineer`, general → `lead-engineer`.
2. A FAIL blocks `gate-4-release`. A PASS WITH QUARANTINE does not, provided
   every quarantine has an owner and the quarantined tests are not billing or
   signature verification.
3. If `--full` PASSed on this commit, cite this report path as the regression
   evidence in `/gate-check gate-4-release <app>`.

---

## Anti-Patterns

- Treating a green run on stale tests as confidence — check the tests cover the
  changed surface.
- Adding tests only for the happy path of a GraphQL mutation; assert the
  variable shaping and the error path too.
- Mocking the webhook signature check. Verify the real HMAC against a real
  payload; the test is worthless otherwise.
- Running the suite without `--run` and believing the watch-mode summary.
