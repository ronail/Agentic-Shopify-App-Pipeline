# Skill Test Spec: /ux-design

> **Category**: authoring  
> **Priority**: medium  
> **Spec written**: 2026-10-29

## Skill Summary

Section-by-section UX spec authoring for one Shopify admin screen or flow — Polaris components, App Bridge context, every state, WCAG 2.1 AA. Writes apps/<app>/design/ux/<screen>.md and hands off to /ux-review.

- **Invocation**: `/ux-design` [screen name | 'flows' | 'patterns' | 'accessibility'] [--app slug]
- **Owner**: `ux-lead`
- **Write access**: yes (`Read, Glob, Grep, Write, Edit, AskUserQuestion, request_user_input, clarify, Task`) — every write needs explicit approval
- **Terminal state**: verdict token `COMPLETE`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 6 `##` sections: “Phase 0 — Parse and confirm scope”, “Phase 1 — Context read”, “Phase 2 — The nine sections, one at a time”, “Phase 3 — Write the file”, “Phase 4 — Specialist pass (optional)”…)
- [ ] At least one verdict keyword present (`COMPLETE` is the terminal state)
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

### Case 1: Happy Path — App — from --app, or ask with the list from docs/registry/apps.json.…

**Fixture** (assumed project state):
- `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md`
- `apps/<app>/design/ux/<screen-slug>.md`
- `apps/<app>/design/ux/flows.md`
- `docs/registry/apps.json` resolves the app slug

**Input:** `/ux-design` [screen name | 'flows' | 'patterns' | 'accessibility'] [--app slug]

**Expected behavior**:
1. **App** — from `--app`, or ask with the list from `docs/registry/apps.json`. Reject an app that is not registered.
2. **Mode** — as above. Unknown argument → ask which of the four.
3. **Screen slug** — kebab case, unique under `apps/<app>/design/ux/`.
4. Check that `docs/architecture/apps/<app>/requirements.yaml` exists. Without requirements, warn: the spec will drift from acceptance criteria. Offer to run with the concept only, but say the risk out loud.

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output in the skill’s own structure
- [ ] Terminal state is the skill's own token (`COMPLETE`), not free prose
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Reject an app that is not registered.

**Fixture**:
- Precondition violated: Reject an app that is not registered.
- No write has been approved

**Expected behavior**:
1. The violated precondition is detected before any finding is produced.
2. The documented blocked/failure state is reported, naming the missing artifact or record.
3. The skill stops and writes nothing.

**Assertions**:
- [ ] Verdict is `COMPLETE` (or the documented failure token), never a softened "ready with notes"
- [ ] The message names the specific path or record that failed, not a generic error
- [ ] Skill stops early and does not produce output that pretends the work succeeded
- [ ] No files written without user approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Mode Variant — `--app` changes the depth of the run

**Fixture**:
- Standard project state for `/ux-design`
- Invocation adds `--app`

**Expected behavior**:
1. `--app` is parsed before any work and the resulting mode is stated in the output header.
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
- A run that reaches the terminal state `COMPLETE`
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

- [ ] Uses the skill's documented approval gate before writes: “Follow `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md`: propose, confirm, then write.”
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (4 numbered steps, 0 rules, 0 declared inputs, 6 `##` sections).
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
