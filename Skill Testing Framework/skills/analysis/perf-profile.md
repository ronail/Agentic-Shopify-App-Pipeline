# Skill Test Spec: /perf-profile

> **Category**: analysis  
> **Priority**: high  
> **Spec written**: 2026-10-29

## Skill Summary

Profile a Shopify app against the project performance budgets: admin route LCP and interaction latency at p75 under 1.5 s, initial bundle under 250 KB gzipped, GraphQL cost inside bucket capacity, webhook handler p95 under 500 ms. Produces a ranked findings report with measured numbers, not opinions.

- **Invocation**: `/perf-profile` [app: <slug>] [surface: admin | graphql | webhooks | bundle | all]
- **Owner**: `performance-analyst`
- **Write access**: yes (`Read, Glob, Grep, Bash, Write, AskUserQuestion, request_user_input, clarify`) — every write needs explicit approval
- **Terminal state**: verdict token `PASS / FAIL`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 8 `##` sections: “1. Scope”, “2. Measure — Admin Surface”, “3. Measure — GraphQL Cost”, “4. Measure — Webhook Handlers”, “5. Measure — Bundle”…)
- [ ] At least one verdict keyword present (`PASS` is the terminal state)
- [ ] Write approval gate present — the skill requires “Ask: "May I write this profile to `production/apps/<app>/milestones/perf-<date>.md`?"” before writing
- [ ] Next-step handoff section present at end — **GAP**: no explicit next-step section

---

## Director Gate Checks

N/A — this skill produces evidence or artifacts that feed a gate but never records one. It must not write gate approvals or change an app's `stage`.

- **Full mode**: review depth routed through `performance-analyst`; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — Load the route 10 times in a warm session; record p50/p75/p95 for: -…

**Fixture** (assumed project state):
- `.claude/docs/technical-preferences.md`
- `production/apps/<app>/milestones/perf-<date>.md`
- `production/apps/<app>/sprints/perf-<date>.md`
- `docs/registry/apps.json` resolves the app slug

**Input:** `/perf-profile` [app: <slug>] [surface: admin | graphql | webhooks | bundle | all]

**Expected behavior**:
1. Load the route 10 times in a warm session; record p50/p75/p95 for: - navigation start → LCP - navigation start → route interactive (first input with visible response) - App Bridge context ready → first data render
2. Interaction latency on the heaviest control (table sort, filter, pagination, bulk action) — 10 interactions, p75.
3. Record React commit cost for the primary table mount using the React Profiler or the browser performance panel; note components committing more than once per data arrival.
4. Note the row count used. A 20-row table proves nothing about a 5,000-variant store — profile at the size the served merchants actually have, and state it.

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output in the skill’s own structure
- [ ] Terminal state is the skill's own token (`PASS`), not free prose
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Warm session, embedded, realistic data. Otherwise the…

**Fixture**:
- The skill's unconditional rule is violated: **Warm session, embedded, realistic data.** Otherwise the numbers describe a scenario no merchant has.
- No write has been approved

**Expected behavior**:
1. The violated precondition is detected before any finding is produced.
2. The documented blocked/failure state is reported, naming the missing artifact or record.
3. The skill stops and writes nothing.

**Assertions**:
- [ ] Verdict is `PASS` (or the documented failure token), never a softened "ready with notes"
- [ ] The message names the specific path or record that failed, not a generic error
- [ ] Skill stops early and does not produce output that pretends the work succeeded
- [ ] No files written without user approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Invocation Variant — argument supplied vs. resolved from disk

**Fixture**:
- Standard project state for this skill
- Invocation omits the argument (`/perf-profile`)

**Expected behavior**:
1. The target is resolved from registry/state files, never guessed from the app name.
2. If the target is ambiguous, the skill asks instead of picking.

**Assertions**:
- [ ] No argument → target resolved from disk state and stated in the output
- [ ] Ambiguous target → question asked; no writes, no silent default

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Edge Case — Never quote a number you did not capture this run.…

**Fixture**:
- Boundary condition from the skill's own rules: **Never quote a number you did not capture this run.** Carrying a stale figure forward silently is how regressions ship.

**Expected behavior**:
1. The skill applies its documented rule instead of overwriting or repeating work.
2. The conflict is surfaced to the user with what was found and what the skill did.

**Assertions**:
- [ ] Prior state is either preserved or explicitly superseded with a reason — never silently rewritten
- [ ] Edge case handled without crash or silent failure
- [ ] Output states the resolution so a later reader can reproduce it

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Director Gate — approval boundary

**Fixture**:
- A run that reaches the terminal state `PASS`
- Review mode: full / lean / solo

**Expected behavior**:
1. No director gate is spawned and no gate approval is written.
2. The handoff names the next skill/agent explicitly (owning agent: `performance-analyst`).
3. In solo mode the skill still refuses to mark work approved on its own authority.

**Assertions**:
- [ ] In full mode: no gate recorded, and no stage advanced, without an explicit approval in the transcript
- [ ] In lean mode: identical behaviour — no silent auto-advance
- [ ] In solo mode: no director gates spawn and no gate entry is written
- [ ] A CONCERNS or FAIL verdict is never auto-advanced past

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses the skill's documented approval gate before writes: “Ask: "May I write this profile to `production/apps/<app>/milestones/perf-<date>.md`?"”
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (4 numbered steps, 5 rules, 0 declared inputs, 8 `##` sections).
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
