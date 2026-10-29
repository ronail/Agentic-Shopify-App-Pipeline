# Skill Test Spec: /ux-review

> **Category**: authoring  
> **Priority**: medium  
> **Spec written**: 2026-10-29

## Skill Summary

Validates a Shopify admin UX spec against Polaris component reality, App Bridge context rules, state coverage, and WCAG 2.1 AA. Returns APPROVED / NEEDS REVISION / MAJOR REVISION NEEDED with file and line references.

- **Invocation**: `/ux-review` [file path | app slug | 'all'] [--depth full|lean|solo]
- **Owner**: `ux-lead`
- **Write access**: read-only
- **Terminal state**: verdict token `APPROVED`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 10 `##` sections: “Phase 0 — Parse”, “Phase 1 — Read with context”, “Phase 2 — Polaris reality check”, “Phase 3 — App Bridge and embedded context”, “Phase 4 — State coverage”…)
- [ ] At least one verdict keyword present (`APPROVED` is the terminal state)
- [ ] Read-only claim holds: the body states it writes nothing, and no file mutation appears despite the tool grant
- [ ] Next-step handoff section present at end — **GAP**: no explicit next-step section
- [ ] Read-only claim holds: no file-mutation path exists in the body

---

## Director Gate Checks

N/A — this skill produces evidence or artifacts that feed a gate but never records one. It must not write gate approvals or change an app's `stage`.

- **Full mode**: review depth routed through `ux-lead`; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — Component names — every named component exists in Polaris. Invented…

**Fixture** (assumed project state):
- `apps/<app>/design/ux/`
- `docs/registry/apps.json`
- `production/review-mode.txt`

**Input:** `/ux-review` [file path | app slug | 'all'] [--depth full|lean|solo]

**Expected behavior**:
1. **Component names** — every named component exists in Polaris. Invented components are **BLOCKER**. Map the intent to the closest real component.
2. **Layout primitives** — `Page`, `Layout`, `Card`, `BlockStack`, `InlineStack`, `Box` used before custom containers.
3. **Table choice** — `IndexTable` for admin tables with bulk actions, `ResourceList` for record browsing, `DataTable` for static figures. Using the wrong one is **MAJOR**.
4. **Form controls** — `FormLayout` with labels and inline help; tooltips alone are **MAJOR**.
5. **Feedback** — App Bridge `toast` for success, `Banner` for errors and warnings, `Modal` for destructive confirmation. `window.alert` or `window.confirm` anywhere is **BLOCKER**.

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output in the skill’s own structure
- [ ] Terminal state is the skill's own token (`APPROVED`), not free prose
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — If the target file does not exist, list the closest…

**Fixture**:
- Precondition violated: If the target file does not exist, list the closest matches and stop.
- No write has been approved

**Expected behavior**:
1. The violated precondition is detected before any finding is produced.
2. The documented blocked/failure state is reported, naming the missing artifact or record.
3. The skill stops and writes nothing.

**Assertions**:
- [ ] Verdict is `APPROVED` (or the documented failure token), never a softened "ready with notes"
- [ ] The message names the specific path or record that failed, not a generic error
- [ ] Skill stops early and does not produce output that pretends the work succeeded
- [ ] No files written without user approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Mode Variant — `--depth` changes the depth of the run

**Fixture**:
- Standard project state for `/ux-review`
- Invocation adds `--depth`

**Expected behavior**:
1. `--depth` is parsed before any work and the resulting mode is stated in the output header.
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
- A run that reaches the terminal state `APPROVED`
- Review mode: full / lean / solo

**Expected behavior**:
1. No director gate is spawned and no gate approval is written.
2. The handoff names the next skill/agent explicitly (owning agent: `ux-lead`).
3. In solo mode the skill still refuses to mark work approved on its own authority.

**Assertions**:
- [ ] In full mode: no gate recorded, and no stage advanced, without an explicit approval in the transcript
- [ ] In lean mode: identical behaviour — no silent auto-advance
- [ ] In solo mode: no director gates spawn and no gate entry is written
- [ ] A CONCERNS or FAIL verdict is never auto-advanced past

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Read-only: no write gate required, and the skill mutates nothing
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (8 numbered steps, 0 rules, 0 declared inputs, 10 `##` sections).
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
