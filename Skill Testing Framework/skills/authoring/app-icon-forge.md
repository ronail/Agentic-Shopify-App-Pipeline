# Skill Test Spec: /app-icon-forge

> **Category**: authoring
> **Priority**: medium
> **Spec written**: 2026-11-01

## Skill Summary

Designs a Shopify app icon from discovery through production export. Runs a
concept → SVG → feedback loop, then exports the 1200x1200 listing PNG plus
favicon, app-store, and social sizes via `scripts/export-icon.mjs` (`sharp`).

- **Invocation**: `/app-icon-forge` [app-slug]
- **Owner**: no `agent:` frontmatter — owned operationally by `app-store-reviewer`
- **Write access**: yes (`Read, Glob, Write, Edit, Bash`) — writes SVG and PNGs after approval
- **Terminal state**: `Verdict: complete` when the 1200x1200 PNG exists and reads at 32x32
- **Gates referenced**: `gate-4-release` (indirectly, via the listing)

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (Discovery, Concepts, SVG, Feedback Loop, Export)
- [ ] Verdict keyword present (`complete` / `incomplete`)
- [ ] Write approval gate present — asks "May I write the SVG and PNG exports to `apps/<app>/design/icon/`?"
- [ ] Next-step handoff section present at end

---

## Gate Checks

- **Gate implied by this skill**: none directly; the exported icon feeds `gate-4-release` through the listing
- **Reads**: `apps/<app>/README.md`, `apps/<app>/shopify.app.toml`
- **Never auto-advances**: writes assets only; no gate record or stage change
- **N/A**: this skill never touches a gate

---

## Test Cases

### Case 1: Happy Path — design and export an icon

**Fixture**:
- `apps/<app>/README.md` names the app; `shopify.app.toml` exists
- `sharp` available in the app project

**Expected behavior**:
1. Read the app name; ask only the unanswered discovery questions.
2. Present 3-4 concepts as words, then draw SVG only after a pick.
3. Iterate versions on feedback, then export after explicit approval.

**Assertions**:
- [ ] No SVG produced in the concepts phase
- [ ] `shopify-listing-1200.png` is 1200x1200
- [ ] Export runs only after explicit approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — `sharp` unavailable

**Fixture**:
- `node -e "require('sharp')"` errors and the install fails

**Expected behavior**:
1. Surface the error and stop.
2. Do not write partial exports.

**Assertions**:
- [ ] Error surfaced verbatim
- [ ] No files written without user approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Invocation Variant — argument supplied vs. resolved

**Fixture**:
- Invocation omits the app slug

**Expected behavior**:
1. Resolve the app from `request.md` or `session-state/active.md`, never guess.
2. Ask if ambiguous.

**Assertions**:
- [ ] Target resolved from disk state and stated
- [ ] Ambiguous target → question asked; no writes

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Edge Case — user defers style

**Fixture**:
- User answers "you pick" to the style question

**Expected behavior**:
1. Pick a direction and continue; do not re-ask.
2. Span multiple style families across the concept batch.

**Assertions**:
- [ ] No re-ask of a deferred question
- [ ] Concepts span more than one style family

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Write Approval — export boundary

**Fixture**:
- An approved SVG ready to export

**Expected behavior**:
1. Present the export plan and ask "May I write…".
2. On refusal, write nothing.

**Assertions**:
- [ ] "May I write" precedes every write
- [ ] Declining leaves the tree unchanged

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write" before any file writes
- [ ] Presents the SVG to the user before requesting approval
- [ ] Ends with a recommended next step
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- PNG dimension checks require `sharp`; the export is not exercised without a target app.
