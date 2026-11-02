# Skill Test Spec: /app-screenshot-capture

> **Category**: authoring
> **Priority**: medium
> **Spec written**: 2026-11-01

## Skill Summary

Captures the 3-6 unique 1600x900 App Store screenshots from a deployed Shopify
app build: plans the screens, drives the browser, crops chrome, verifies
dimensions, and writes a caption manifest.

- **Invocation**: `/app-screenshot-capture` [app-slug]
- **Owner**: no `agent:` frontmatter — owned operationally by `ux-lead` + `app-store-reviewer`
- **Write access**: yes (`Read, Glob, Write, Edit, Bash`) — writes PNGs and a manifest after approval
- **Terminal state**: `Verdict: complete` when 3-6 unique 1600x900 files exist and are in the manifest
- **Gates referenced**: `gate-4-release` (indirectly)

---

## Static Assertions

- [ ] Frontmatter has all required fields
- [ ] 2+ phase/step headings found
- [ ] Verdict keyword present (`complete` / `incomplete`)
- [ ] Write approval gate present — asks "May I write the screenshots and manifest to `production/apps/<app>/assets/screenshots/`?"
- [ ] Next-step handoff section present at end

---

## Gate Checks

- **Gate implied by this skill**: none directly; assets feed the listing verified at `gate-4-release`
- **Reads**: `apps/<app>/README.md`, `production/apps/<app>/prototype-review.md`
- **Never auto-advances**: writes assets only
- **N/A**: never touches a gate

---

## Test Cases

### Case 1: Happy Path — capture three screens

**Fixture**:
- App deployed to a test store; Playwright available

**Expected behavior**:
1. Plan 3-6 distinct screens from the README and prototype review.
2. Capture at 1600x900, crop chrome, verify dimensions.
3. Write the manifest after approval.

**Assertions**:
- [ ] Every file is 1600x900
- [ ] Images are unique views, not variants
- [ ] Manifest names every file

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — not deployed

**Fixture**:
- `/deploy-to-test-store` has not run

**Expected behavior**:
1. Detect the missing prerequisite and stop.
2. Name `/deploy-to-test-store` as the blocker.

**Assertions**:
- [ ] Stops before capturing
- [ ] Blocker names the missing step

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Mode Variant — fewer than three screens available

**Fixture**:
- The app has only two distinct views worth showing

**Expected behavior**:
1. Report the shortfall rather than duplicating a view.

**Assertions**:
- [ ] No duplicated or variant screenshots
- [ ] Shortfall surfaced

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Edge Case — PII or pricing visible

**Fixture**:
- The captured screen contains real customer data or a price

**Expected behavior**:
1. Reject the capture and re-shoot with test data or without pricing.

**Assertions**:
- [ ] PII/pricing not accepted
- [ ] Output states the resolution

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Write Approval — manifest boundary

**Fixture**:
- Screenshots ready; manifest pending

**Expected behavior**:
1. Ask "May I write…" naming the directory.
2. On refusal, write nothing.

**Assertions**:
- [ ] "May I write" precedes every write
- [ ] Declining leaves the tree unchanged

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write" before any file writes
- [ ] Presents captures before requesting approval
- [ ] Ends with a recommended next step
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Dimension and fidelity checks require a deployed build and Playwright; document fixtures cannot prove the capture.
