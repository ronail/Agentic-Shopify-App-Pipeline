# Skill Test Spec: /onboard

> **Category**: utility  
> **Priority**: medium  
> **Spec written**: 2026-10-29

## Skill Summary

Onboard a developer, a merchant reviewer, or a dev store to this Shopify app pipeline. Three modes with verified checklists: dev environment (clone, CLI, tunnel, tests), merchant/reviewer walkthrough (what to click, what to expect), and test-store setup routing to create-test-store.

- **Invocation**: `/onboard` [dev | merchant | store] [app: <slug>] [--rebuild]
- **Owner**: `producer`
- **Write access**: yes (`Read, Glob, Grep, Bash, Write, AskUserQuestion, request_user_input, clarify`) — every write needs explicit approval
- **Terminal state**: verdict token `BLOCKED`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 6 `##` sections: “0. Establish Who Is Arriving”, “Mode: dev”, “Mode: merchant”, “Mode: store”, “Write Rules”…)
- [ ] At least one verdict keyword present (`BLOCKED` is the terminal state)
- [ ] Write approval gate present — the skill requires “Ask before writing any file: "May I write this walkthrough to `production/apps/<app>/milestones/demo-<date>.md`?"…” before writing
- [ ] Next-step handoff section present at end — **GAP**: no explicit next-step section

---

## Director Gate Checks

N/A — this skill produces evidence or artifacts that feed a gate but never records one. It must not write gate approvals or change an app's `stage`.

- **Full mode**: review depth routed through `producer`; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — Toolchain - [ ] Node 20 LTS: node -v - [ ] npm present; run installs…

**Fixture** (assumed project state):
- `apps/<app>/ONBOARDING.md`
- `production/apps/<app>/milestones/demo-<date>.md`
- `apps/<app>/README.md`
- `docs/registry/apps.json` resolves the app slug

**Input:** `/onboard` [dev | merchant | store] [app: <slug>] [--rebuild]

**Expected behavior**:
1. **Toolchain** - [ ] Node 20 LTS: `node -v` - [ ] npm present; run installs with the repo's lockfile, not a fresh resolve - [ ] Shopify CLI installed and version reporting: `shopify version` - [ ] Git identity configured; on a feature branch, not `main` for…
2. **Repository** - [ ] Clone and `npm install` at the repo root; then per-app install if the app is its own package - [ ] `npm test -- --run` executes (a failing suite is expected for some apps — record the state rather than "fixing" it on day one) - [ ]…
3. **Shopify CLI auth** - [ ] `shopify auth login` completes (browser flow) — never paste a token into chat or a file - [ ] The partner account has access to the app's dev store - [ ] `shopify app config link` points at the right app and store; verify by…
4. **Local run** - [ ] `shopify app dev` starts, opens a tunnel, and installs/updates the app on the dev store - [ ] The embedded admin route loads inside the Shopify admin iframe - [ ] A webhook from the store reaches the tunnel (check the CLI webhook log)
5. **Local configuration** - [ ] `.env.local` created from the documented template; every required key present — list key **names** only, never values - [ ] `.env.local` is git-ignored (`git check-ignore -v .env.local` returns a rule) - [ ] Database reachable…

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output in the skill’s own structure
- [ ] Terminal state is the skill's own token (`BLOCKED`), not free prose
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Test charges only; if a real charge could occur, stop and…

**Fixture**:
- Precondition violated: Test charges only; if a real charge could occur, stop and escalate to `billing-specialist` before the walkthrough.
- No write has been approved

**Expected behavior**:
1. The violated precondition is detected before any finding is produced.
2. The documented blocked/failure state is reported, naming the missing artifact or record.
3. The skill stops and writes nothing.

**Assertions**:
- [ ] Verdict is `BLOCKED` (or the documented failure token), never a softened "ready with notes"
- [ ] The message names the specific path or record that failed, not a generic error
- [ ] Skill stops early and does not produce output that pretends the work succeeded
- [ ] No files written without user approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Mode Variant — `--rebuild` changes the depth of the run

**Fixture**:
- Standard project state for `/onboard`
- Invocation adds `--rebuild`

**Expected behavior**:
1. `--rebuild` is parsed before any work and the resulting mode is stated in the output header.
2. Check depth widens or narrows consistently with the flag — never silently ignored.
3. Output differs from Case 1 only in the documented way.

**Assertions**:
- [ ] Flag honoured: the run's depth matches what the flag documents
- [ ] Invalid flag values are rejected instead of silently defaulting
- [ ] Mode recorded in the output header so the run is reproducible

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Edge Case — partially complete state

**Fixture**:
- Boundary condition from the skill's own rules: an artifact exists but is incomplete or left over from an earlier run

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
- A run that reaches the terminal state `BLOCKED`
- Review mode: full / lean / solo

**Expected behavior**:
1. No director gate is spawned and no gate approval is written.
2. The handoff names the next skill/agent explicitly (owning agent: `producer`).
3. In solo mode the skill still refuses to mark work approved on its own authority.

**Assertions**:
- [ ] In full mode: no gate recorded, and no stage advanced, without an explicit approval in the transcript
- [ ] In lean mode: identical behaviour — no silent auto-advance
- [ ] In solo mode: no director gates spawn and no gate entry is written
- [ ] A CONCERNS or FAIL verdict is never auto-advanced past

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses the skill's documented approval gate before writes: “Ask before writing any file: "May I write this walkthrough to `production/apps/<app>/milestones/demo-<date>.md`?" Never write…”
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (6 numbered steps, 4 rules, 0 declared inputs, 6 `##` sections).
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
