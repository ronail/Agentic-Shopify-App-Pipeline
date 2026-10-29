# Skill Test Spec: /app-store-checklist

> **Category**: readiness  
> **Priority**: high  
> **Spec written**: 2026-10-29

## Skill Summary

Runs the App Store submission readiness gate for a Shopify app: listing assets, pricing, permissions and scopes, install and uninstall behaviour, billing, support surface, and policy compliance. Produces a pass/fail checklist with evidence per line.

- **Invocation**: `/app-store-checklist` [app-slug]
- **Owner**: no `agent:` frontmatter — runs in the calling context
- **Write access**: yes (`Read, Glob, Grep, Write, Edit, Bash`) — every write needs explicit approval
- **Terminal state**: verdict token `PASS / FAIL`
- **Gates referenced**: `gate-2-prototype`, `gate-3-scope`, `gate-4-release`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 7 `##` sections: “Purpose”, “When to use”, “Inputs”, “Steps”, “Outputs”…)
- [ ] At least one verdict keyword present (`PASS` is the terminal state)
- [ ] Write approval gate present — the skill requires “Confirm the scope is the least privileged that works.” before writing
- [ ] Next-step handoff section present at end — **GAP**: no explicit next-step section

---

## Director Gate Checks

This skill works against the approval record and names `gate-2-prototype`, `gate-3-scope`, `gate-4-release`.

- It must read `apps/<app>/approvals.json` and `apps/<app>/status.md` before claiming any gate state.
- It never records a gate or advances an app's `stage`; it produces evidence the gate reads.

- **Full mode**: no director fan-out driven by this skill; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — Confirm prerequisites. gate-2-prototype and gate-3-scope must be…

**Fixture** (assumed project state):
- apps/<app>/README.md — Purpose, the promise the listing must match
- apps/<app>/approvals.json — Which gates are already approved
- apps/<app>/` (app source) — Scopes, billing calls, install and uninstall handling
- docs/shopify-api-reference/ — Current requirements for scopes and billing
- `docs/registry/apps.json` resolves the app slug
- present but optional: production/apps/<app>/prototype-review.md

**Input:** `/app-store-checklist` [app-slug]

**Expected behavior**:
1. **Confirm prerequisites.** `gate-2-prototype` and `gate-3-scope` must be approved in `apps/<app>/approvals.json`. If not, stop — the checklist is meaningless for an unscoped app.
2. **Scopes** — list every scope the app requests and the code path that needs it. Any scope without a call site is a fail: excess scopes are the most common rejection reason and the easiest to fix. Confirm the scope is the least privileged that works.
3. **Billing** — confirm the plan tiers, that the charge is created through the platform billing surface (not an external payment processor), that the trial is declared, and that a declined charge is handled with a merchant-readable state rather than a dead…
4. **Install path** — a fresh install must reach a working state with no manual step: no "contact us to activate", no empty dashboard. Confirm onboarding copy exists and that scopes are requested at the moment they are needed, with a reason a merchant…
5. **Uninstall path** — confirm the app responds to the uninstall signal, marks the record inactive, and stops charging. A merchant who uninstalls and is still billed is a policy violation, not a bug.

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output (`production/apps/<app>/app-store-checklist.md`)
- [ ] Terminal state is the skill's own token (`PASS`), not free prose
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Confirm prerequisites. gate-2-prototype and gate-3-scope…

**Fixture**:
- Precondition violated: **Confirm prerequisites.** `gate-2-prototype` and `gate-3-scope` must be approved in `apps/<app>/approvals.json`. If not, stop — the checklist is meaningless for an unscoped app.
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
- Invocation omits the argument (`/app-store-checklist`)

**Expected behavior**:
1. The target is resolved from registry/state files, never guessed from the app name.
2. If the target is ambiguous, the skill asks instead of picking.

**Assertions**:
- [ ] No argument → target resolved from disk state and stated in the output
- [ ] Ambiguous target → question asked; no writes, no silent default

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Edge Case — Re-check after fixes. Change the line's result, keep the…

**Fixture**:
- Boundary condition from the skill's own rules: **Re-check after fixes.** Change the line's result, keep the old failure in the history section.

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
1. Gate-relevant evidence is reported for `gate-2-prototype`, `gate-3-scope`, `gate-4-release`; the skill writes no gate record.
2. Handoff names the owning gate: `/app-store-checklist` → evidence → `gate-check`.
3. A failing criterion is reported as a blocking failure with an owner, not as advice.

**Assertions**:
- [ ] In full mode: no gate recorded, and no stage advanced, without an explicit approval in the transcript
- [ ] In lean mode: identical behaviour — no silent auto-advance
- [ ] In solo mode: no director gates spawn
- [ ] A CONCERNS or FAIL verdict is never auto-advanced past

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses the skill's documented approval gate before writes: “Confirm the scope is the least privileged that works.”
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (10 numbered steps, 4 rules, 5 declared inputs, 7 `##` sections).
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
