# Skill Test Spec: /create-test-store

> **Category**: pipeline  
> **Priority**: high  
> **Spec written**: 2026-10-29

## Skill Summary

Provisions a development and test store for a Shopify app: development store, test products and orders, the app install with scopes, and the credentials record the deploy path reads. Use before the first deploy, or when an app needs a clean store to test against.

- **Invocation**: `/create-test-store` [app-slug]
- **Owner**: no `agent:` frontmatter — runs in the calling context
- **Write access**: yes (`Read, Glob, Grep, Write, Edit, Bash`) — every write needs explicit approval
- **Terminal state**: artifact produced (no verdict token by design)
- **Gates referenced**: `gate-3-scope`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 7 `##` sections: “Purpose”, “When to use”, “Inputs”, “Steps”, “Outputs”…)
- [ ] N/A — artifact-producing skill: no verdict keyword by design; success is the artifact existing with its required sections
- [ ] Write approval gate present — the skill requires “Verify the install by making one read call through the app's own client and confirming the scopes actually granted…” before writing
- [ ] Next-step handoff section present at end — **GAP**: no explicit next-step section

---

## Director Gate Checks

This skill works against the approval record and names `gate-3-scope`.

- It must read `apps/<app>/approvals.json` and `apps/<app>/status.md` before claiming any gate state.
- It never records a gate or advances an app's `stage`; it produces evidence the gate reads.

- **Full mode**: no director fan-out driven by this skill; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — Confirm the app is scoped. gate-3-scope approved in…

**Fixture** (assumed project state):
- apps/<app>/README.md — The app and its surface
- apps/<app>/approvals.json — Confirms the app is scoped
- docs/shopify-api-reference/ — Scope names and API version to pin
- production/apps/<app>/session-state/ — Where the store record goes
- `docs/registry/apps.json` resolves the app slug
- present but optional: apps/<app>/shopify.app.toml

**Input:** `/create-test-store` [app-slug]

**Expected behavior**:
1. **Confirm the app is scoped.** `gate-3-scope` approved in `apps/<app>/approvals.json`. If not, stop and say which gate is missing.
2. **Create the development store** in the partner dashboard, named for the app and the environment: `<app>-dev`. Use a development store, not a trial store — trial stores expire and cannot install unpublished apps.
3. **Seed the fixtures.** Create the data the app's flow needs: at least 10 products across two collections, one product with variants, one with no inventory, and two orders in different states. Fixtures must include an empty collection and a zero-result search…
4. **Install the app** on the store with exactly the scopes in the approved scope list. Do not grant extra scopes "for convenience"; the store should reproduce what a merchant grants.
5. **Record the credentials by reference**, not by value, in `production/apps/<app>/session-state/test-store.md`: - store domain - environment variable or credential-store path holding the admin token - the pinned API version - install date and the app version…

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output (`production/apps/<app>/session-state/test-store.md`)
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Confirm the app is scoped. gate-3-scope approved in…

**Fixture**:
- Precondition violated: **Confirm the app is scoped.** `gate-3-scope` approved in `apps/<app>/approvals.json`. If not, stop and say which gate is missing.
- No write has been approved

**Expected behavior**:
1. The violated precondition is detected before any finding is produced.
2. The documented blocked/failure state is reported, naming the missing artifact or record.
3. The skill stops and writes nothing.

**Assertions**:
- [ ] Skill reports the block explicitly instead of producing a partial recommendation
- [ ] The message names the specific path or record that failed, not a generic error
- [ ] Skill stops early and does not produce output that pretends the work succeeded
- [ ] No files written without user approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Invocation Variant — argument supplied vs. resolved from disk

**Fixture**:
- Standard project state for this skill
- Invocation omits the argument (`/create-test-store`)

**Expected behavior**:
1. The target is resolved from registry/state files, never guessed from the app name.
2. If the target is ambiguous, the skill asks instead of picking.

**Assertions**:
- [ ] No argument → target resolved from disk state and stated in the output
- [ ] Ambiguous target → question asked; no writes, no silent default

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
- A run that reaches the terminal state
- Review mode: full / lean / solo

**Expected behavior**:
1. Gate-relevant evidence is reported for `gate-3-scope`; the skill writes no gate record.
2. Handoff names the owning gate: `/create-test-store` → evidence → `gate-check`.
3. A failing criterion is reported as a blocking failure with an owner, not as advice.

**Assertions**:
- [ ] In full mode: no gate recorded, and no stage advanced, without an explicit approval in the transcript
- [ ] In lean mode: identical behaviour — no silent auto-advance
- [ ] In solo mode: no director gates spawn
- [ ] A CONCERNS or FAIL verdict is never auto-advanced past

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses the skill's documented approval gate before writes: “Verify the install by making one read call through the app's own client and confirming the scopes actually granted match the…”
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (7 numbered steps, 4 rules, 5 declared inputs, 7 `##` sections).
- The body states no verdict keyword; terminal state must be read from the Output section. Verify the static assertion above before running the cases — it is a real finding, not a formatting artefact.
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
