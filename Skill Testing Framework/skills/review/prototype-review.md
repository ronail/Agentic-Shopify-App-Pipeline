# Skill Test Spec: /prototype-review

> **Category**: review  
> **Priority**: high  
> **Spec written**: 2026-10-29

## Skill Summary

Reviews a built prototype against the original request before any production build: flow fidelity, merchant language, empty and error states, and whether the demo actually proves the value. Produces a pass/fail set of findings and the gate-2-prototype recommendation.

- **Invocation**: `/prototype-review` [app-slug]
- **Owner**: no `agent:` frontmatter — runs in the calling context
- **Write access**: yes (`Read, Glob, Grep, Write, Edit, Bash`) — every write needs explicit approval
- **Terminal state**: verdict token `pass / pass-with-fixes / send-back`
- **Gates referenced**: `gate-2-prototype`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 7 `##` sections: “Purpose”, “When to use”, “Inputs”, “Steps”, “Outputs”…)
- [ ] At least one verdict keyword present (`pass` is the terminal state)
- [ ] Write approval gate present — the skill requires “Ask before writing. Then write `production/apps/<app>/prototype-review.md` and, on `pass` or `pass-with-fixes`,…” before writing
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

This skill works against the approval record and names `gate-2-prototype`.

- It must read `apps/<app>/approvals.json` and `apps/<app>/status.md` before claiming any gate state.
- It never records a gate or advances an app's `stage`; it produces evidence the gate reads.

- **Full mode**: no director fan-out driven by this skill; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — Open the prototype and walk the flow exactly as the README.md script…

**Fixture** (assumed project state):
- apps/<app>/prototype/ — Every screen plus its `README.md` flow script
- request.md — What was actually asked for
- production/research/<app>/recommendation.md — The problem and the differentiation hook
- apps/<app>/approvals.json — Where the gate record is written
- `docs/registry/apps.json` resolves the app slug
- present but optional: production/apps/<app>/mmmvp-proposals.md

**Input:** `/prototype-review` [app-slug]

**Expected behavior**:
1. **Open the prototype and walk the flow** exactly as the `README.md` script words it. Note every point where you had to guess what to click next — that is a finding, not a nitpick.
2. **Check fidelity to the request.** For each request line that names app behaviour, find the screen that demonstrates it. Missing demonstration is a `blocker` finding. Behaviour the prototype adds that the request does not ask for is a `scope-creep` finding.
3. **Check the merchant's language.** Read the copy aloud. Flag internal terms (table names, API nouns, pipeline words) that would appear on a merchant screen. Flag any label a merchant could not explain to a colleague.
4. **Check the states.** Empty, loading, error, permission-denied, and the zero-results case. Each missing state is a finding with the screen named.
5. **Check the value proof.** Does the prototype show, on one screen, what the merchant gets that they do not get today? If the reviewer has to infer it, the prototype fails its only job.

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output (`production/apps/<app>/prototype-review.md`)
- [ ] Terminal state is the skill's own token (`pass`), not free prose
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Review the request, not your taste. A design you dislike…

**Fixture**:
- The skill's unconditional rule is violated: **Review the request, not your taste.** A design you dislike that satisfies the request is a `note`, not a blocker.
- No write has been approved

**Expected behavior**:
1. The violated precondition is detected before any finding is produced.
2. The documented blocked/failure state is reported, naming the missing artifact or record.
3. The skill stops and writes nothing.

**Assertions**:
- [ ] Verdict is `pass` (or the documented failure token), never a softened "ready with notes"
- [ ] The message names the specific path or record that failed, not a generic error
- [ ] Skill stops early and does not produce output that pretends the work succeeded
- [ ] No files written without user approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Invocation Variant — argument supplied vs. resolved from disk

**Fixture**:
- Standard project state for this skill
- Invocation omits the argument (`/prototype-review`)

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
- A run that reaches the terminal state `pass`
- Review mode: full / lean / solo

**Expected behavior**:
1. Gate-relevant evidence is reported for `gate-2-prototype`; the skill writes no gate record.
2. Handoff names the owning gate: `/prototype-review` → evidence → `gate-check`.
3. A failing criterion is reported as a blocking failure with an owner, not as advice.

**Assertions**:
- [ ] In full mode: no gate recorded, and no stage advanced, without an explicit approval in the transcript
- [ ] In lean mode: identical behaviour — no silent auto-advance
- [ ] In solo mode: no director gates spawn
- [ ] A CONCERNS or FAIL verdict is never auto-advanced past

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses the skill's documented approval gate before writes: “Ask before writing. Then write `production/apps/<app>/prototype-review.md` and, on `pass` or `pass-with-fixes`, propose — never…”
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (8 numbered steps, 4 rules, 5 declared inputs, 7 `##` sections).
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
