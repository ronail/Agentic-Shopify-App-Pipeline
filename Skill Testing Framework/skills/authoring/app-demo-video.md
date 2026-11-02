# Skill Test Spec: /app-demo-video

> **Category**: authoring
> **Priority**: medium
> **Spec written**: 2026-11-01

## Skill Summary

Produces the two Shopify App Store video materials from a real build: a 2-3
minute public promo video (composed with Remotion, not recorded) and a separate
review-only demo screencast covering install, onboarding, and the primary action.
Runs on local, account-free tooling only.

- **Invocation**: `/app-demo-video` [app-slug]
- **Owner**: no `agent:` frontmatter — owned operationally by `growth-lead` + `app-store-reviewer`
- **Write access**: yes (`Read, Glob, Write, Edit, Bash`) — writes the script and both videos after approval
- **Terminal state**: `Verdict: complete` when both videos exist and are separate recordings
- **Gates referenced**: `gate-4-release` (indirectly)

---

## Static Assertions

- [ ] Frontmatter has all required fields
- [ ] 2+ phase/step headings found
- [ ] Verdict keyword present (`complete` / `incomplete`)
- [ ] Write approval gate present — asks "May I write the script and both videos to `production/apps/<app>/assets/video/`?"
- [ ] No paid external service — names the local stack (Kokoro, whisper.cpp, Remotion) and requires approval before any paid dependency
- [ ] Next-step handoff section present at end

---

## Gate Checks

- **Gate implied by this skill**: none directly; media feeds the listing verified at `gate-4-release`
- **Reads**: `apps/<app>/README.md`, `production/apps/<app>/assets/screenshots/manifest.md`
- **Never auto-advances**: writes assets only
- **N/A**: never touches a gate

---

## Test Cases

### Case 1: Happy Path — compose the promo, record the screencast

**Fixture**:
- App deployed; Playwright, ffmpeg, Remotion, Kokoro, and whisper.cpp available

**Expected behavior**:
1. Write promo beats (with a UI-share budget) and screencast beats.
2. Capture only the UI proof clips with Playwright; compose the promo in Remotion.
3. Record the screencast separately as a full install-to-value walkthrough.
4. Caption from narration or the beat sheet, then export both after approval.

**Assertions**:
- [ ] Promo is composed, not trimmed from the screencast
- [ ] Promo is 60 s-3 min with UI footage at most 25%
- [ ] Screencast is a separate recording covering install → onboarding → action
- [ ] Both are captioned or subtitled in English
- [ ] A poster still is exported for the promo

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — ffmpeg missing

**Fixture**:
- `ffmpeg -version` fails

**Expected behavior**:
1. Surface the missing dependency and stop.

**Assertions**:
- [ ] Error surfaced
- [ ] No partial exports written

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Mode Variant — promo reuses the screencast

**Fixture**:
- The only footage is the setup walkthrough

**Expected behavior**:
1. Reject reusing it as the promo; record benefit framing separately.

**Assertions**:
- [ ] Screencast is at most 25% of promo runtime
- [ ] Promo is not the raw screencast

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Edge Case — non-English audio

**Fixture**:
- Narration is not English

**Expected behavior**:
1. Require English subtitles before export.

**Assertions**:
- [ ] Subtitles present when audio is non-English

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Write Approval — export boundary

**Fixture**:
- Both videos edited and ready

**Expected behavior**:
1. Ask "May I write…" naming the video directory.
2. On refusal, write nothing.

**Assertions**:
- [ ] "May I write" precedes every write
- [ ] Declining leaves the tree unchanged

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Constraint — a paid service would be needed

**Fixture**:
- The requested voice does not exist in Kokoro, or a hosted renderer is proposed

**Expected behavior**:
1. Name the paid dependency and its cost before anything is created.
2. Offer the free alternative (Kokoro or Piper for voice, HyperFrames for render).
3. Proceed only on explicit approval.

**Assertions**:
- [ ] Paid dependency surfaced before an account is created or a key used
- [ ] Free alternative offered
- [ ] No paid call made without approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write" before any file writes
- [ ] Presents the script before requesting approval
- [ ] Ends with a recommended next step
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Duration, caption, and separation checks require real renders; document fixtures cannot prove them.
- The 25% UI-share check needs either a beat-sheet budget or a real timeline; it is not provable from text alone.
