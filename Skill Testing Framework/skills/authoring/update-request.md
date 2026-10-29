# Skill Test Spec: /update-request

> **Category**: authoring  
> **Priority**: medium  
> **Spec written**: 2026-10-29

## Skill Summary

Amends request.md without losing prior intent: bumps the version, writes the change, and appends a dated entry to request-history.md so superseded asks stay readable. Use when scope, success criteria, or the app list changes after the request was written.

- **Invocation**: `/update-request` [what changed, e.g. 'add order-tags app' or 'drop multi-currency']
- **Owner**: no `agent:` frontmatter — runs in the calling context
- **Write access**: yes (`Read, Glob, Grep, Write, Edit, Bash`) — every write needs explicit approval
- **Terminal state**: artifact produced (no verdict token by design)
- **Gates referenced**: `gate-3-scope`, `gate-5-update`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 7 `##` sections: “Purpose”, “When to use”, “Inputs”, “Steps”, “Outputs”…)
- [ ] N/A — artifact-producing skill: no verdict keyword by design; success is the artifact existing with its required sections
- [ ] **GAP** — `allowed-tools` grants Write/Edit but the body documents no "May I write"-style approval gate
- [ ] Next-step handoff section present at end — **GAP**: no explicit next-step section

---

## Director Gate Checks

This skill works against the approval record and names `gate-3-scope`, `gate-5-update`.

- It must read `apps/<app>/approvals.json` and `apps/<app>/status.md` before claiming any gate state.
- It never records a gate or advances an app's `stage`; it produces evidence the gate reads.

- **Full mode**: no director fan-out driven by this skill; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — State the change in one sentence, in past tense and outcome form:…

**Fixture** (assumed project state):
- request.md — Current text, current `Version:` line
- request-history.md — Append target; create with a header only if absent
- docs/registry/apps.json — Whether an app slug in the change exists
- present but optional: apps/<app>/approvals.json, production/apps/<app>/mmmvp-proposals.md

**Input:** `/update-request` [what changed, e.g. 'add order-tags app' or 'drop multi-currency']

**Expected behavior**:
1. **State the change in one sentence**, in past tense and outcome form: "Added the `order-tags` app to scope" or "Removed multi-currency from success criteria". If you cannot write that sentence, the change is not defined yet — ask.
2. **Find the exact target lines** with Grep before editing. Name the section (`Goal`, `Success criteria`, `Non-goals`, `Apps in scope`, `Gates`) and quote the current text. Never rewrite a whole file to change one bullet.
3. **Check the blast radius.** If the change touches an app that already has a non-pending gate in `apps/<app>/approvals.json`, flag it: an approved gate was approved against a different request. That needs `product-director`'s explicit re-approval, not a quiet…
4. **Draft the diff.** Show the before and after for each touched line, plus the new `Version:` value. Version format is `v<major>` for a scope change and `v<major>.<minor>` for a clarification that changes no scope.
5. **Ask for approval** on the full changeset — both files, one approval.

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output (`request.md`)
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Renaming a slug means moving apps/<slug>/ too; refuse the…

**Fixture**:
- Precondition violated: Renaming a slug means moving `apps/<slug>/` too; refuse the rename if the app has approved gates and escalate instead.
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
- Invocation omits the argument (`/update-request`)

**Expected behavior**:
1. The target is resolved from registry/state files, never guessed from the app name.
2. If the target is ambiguous, the skill asks instead of picking.

**Assertions**:
- [ ] No argument → target resolved from disk state and stated in the output
- [ ] Ambiguous target → question asked; no writes, no silent default

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Edge Case — Append, never delete, in request-history.md. History is…

**Fixture**:
- Boundary condition from the skill's own rules: **Append, never delete, in `request-history.md`.** History is evidence.

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
1. Gate-relevant evidence is reported for `gate-3-scope`, `gate-5-update`; the skill writes no gate record.
2. Handoff names the owning gate: `/update-request` → evidence → `gate-check`.
3. A failing criterion is reported as a blocking failure with an owner, not as advice.

**Assertions**:
- [ ] In full mode: no gate recorded, and no stage advanced, without an explicit approval in the transcript
- [ ] In lean mode: identical behaviour — no silent auto-advance
- [ ] In solo mode: no director gates spawn
- [ ] A CONCERNS or FAIL verdict is never auto-advanced past

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] **GAP**: writes are granted but no approval gate is documented — route to `/skill-improve`
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (8 numbered steps, 4 rules, 5 declared inputs, 7 `##` sections).
- The body states no verdict keyword; terminal state must be read from the Output section. Verify the static assertion above before running the cases — it is a real finding, not a formatting artefact.
- **Write-approval gap**: `allowed-tools` includes Write/Edit while the body has no "May I write"-style gate. Cases assume approval is required; if the skill is meant to write unattended, revise the assertion rather than loosening the test.
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
