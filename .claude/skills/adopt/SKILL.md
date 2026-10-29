---
name: adopt
description: "Brownfield onboarding — audits existing project artifacts for template format compliance (not just existence), classifies gaps by impact, and produces a numbered migration plan. Run this when joining an in-progress project or upgrading from an older template version. Distinct from /project-stage-detect (which checks what exists) — this checks whether what exists will actually work with the template's skills."
argument-hint: "[focus: full | requirements | adrs | stories | infra]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion, request_user_input, clarify
model: sonnet
agent: technical-director
---

# Adopt — Brownfield Template Adoption

This skill audits an existing project's artifacts for **format compliance** with
the template's skill pipeline, then produces a prioritised migration plan.

**This is not `/project-stage-detect`.**
`/project-stage-detect` answers: *what exists?*
`/adopt` answers: *will what exists actually work with the template's skills?*

A project can have requirements files, ADRs, and stories — and every
format-sensitive skill will still fail silently or produce wrong results if
those artifacts are in the wrong internal format.

**Output:** `docs/adoption-plan-[date].md` — a persistent, checkable migration plan.

**Argument modes:**

**Audit mode:** `$ARGUMENTS[0]` (blank = `full`)

- **No argument / `full`**: Complete audit — all artifact types
- **`requirements`**: Per-app requirements format compliance only
- **`adrs`**: ADR format compliance only
- **`stories`**: Story format compliance only
- **`infra`**: Infrastructure artifact gaps only (registry, manifest, sprint status, stage)

---

## Phase 1: Detect Project State

Emit one line before reading: `"Scanning project artifacts..."` — this confirms the
skill is running during the silent read phase.

Then read silently before presenting anything else.

### Existence check
- `production/stage.txt` — if present, read it (authoritative phase)
- `docs/registry/apps.json` — app registry exists? How many apps?
- For each app in `apps/<app>/`: does `status.md` exist? `approvals.json`?
- Count requirement files: `docs/architecture/apps/*/requirements.yaml`
- Count ADR files: `docs/architecture/apps/*/ADR-*.md`
- Count epic files: `production/epics/*/EPIC.md`
- Count story files: `production/epics/**/*.md` (excluding `EPIC.md` and `index.md`)
- Count sprint plans: `production/sprints/sprint-*.md`
- Glob `docs/adoption-plan-*.md` — note the filename of the most recent prior plan if any exist

### Infer phase (if no stage.txt)
Use the same heuristic as `/project-stage-detect`:
- Stories with `Status: Complete` exist and a sprint plan exists → Production
- Stories exist under `production/epics/` → Pre-Production
- ADRs exist → Technical Setup
- `requirements.yaml` exists for at least one app → Requirements
- `apps/<app>/` exists but no requirements → Scaffolded
- Nothing → Fresh (not a brownfield project — suggest `/start`)

If the project appears fresh (no artifacts at all), use `AskUserQuestion`, `request_user_input` or `clarify`:
- "This looks like a fresh project — no existing artifacts found. `/adopt` is for
  projects with work to migrate. What would you like to do?"
  - "Run `/start` — begin guided first-time onboarding"
  - "My artifacts are in a non-standard location — help me find them"
  - "Cancel"

Then stop — do not proceed with the audit regardless of which option the user picks
(each option leads to a different skill or manual investigation).

Report: "Detected phase: [phase]. Found: [N] apps, [M] ADRs, [P] stories."

---

## Phase 2: Format Audit

For each artifact type in scope (based on argument mode), check not just that
the file exists but that it contains the internal structure the template requires.

### 2a: Requirements Format Audit

For each `docs/architecture/apps/<app>/requirements.yaml`, check the required keys
on every entry:

| Required Key | Impact if missing |
|---|---|
| `id` | **BLOCKING** — no stable `REQ-<APP>-NNN` handle for stories to trace |
| `title` | HIGH — stories cannot name what they implement |
| `status` | **BLOCKING** — `/story-readiness` status checks silently pass everything |
| `acceptance_criteria` | HIGH — `/create-stories` cannot derive testable stories |
| `priority` | MEDIUM — sprint ordering degrades |
| `source` | MEDIUM — no link back to `request.md` |

Also check:
- **ID format** — every `id` matches `REQ-[A-Z]{2,5}-[0-9]{3}` and uses the app's
  own prefix. Flag mismatched prefixes.
- **Append-only rule** — no ID is reused for a different requirement, and no
  previously issued ID is missing from the file. Note deleted IDs as HIGH: they
  break traceability for any story that references them.
- **Status vocabulary** — values come only from `Draft`, `In Review`, `Approved`,
  `Needs Revision`, `Deprecated`. Flag anything else.
- **Placeholder text** — entries whose bodies are still `[To be defined]` or
  equivalent.

### 2b: ADR Format Audit

For each ADR file found, check for these critical sections:

| Section | Impact if missing |
|---|---|
| `## Status` | **BLOCKING** — `/story-readiness` ADR status check silently passes everything |
| `## Dependencies` | HIGH — dependency ordering in `/architecture-review` breaks |
| `## Platform Compatibility` | HIGH — API version and deprecation risk is unknown |
| `## Requirements Addressed` | MEDIUM — traceability matrix loses coverage |
| `## Consequences` | MEDIUM — stories lose implementation guidance |
| `## Performance Implications` | LOW — not pipeline-critical |

For each ADR, record: which sections present, which missing, current Status value
if the Status section exists.

### 2c: App Index Audit

If an app index exists (`docs/architecture/apps/index.md`, or the app table inside
`docs/architecture/architecture.md`):

1. **Parenthetical status values** — Grep for any Status cell containing
   parentheses: `"Needs Revision ("`, `"In Progress ("`, etc.
   These break exact-string matching in `/gate-check`, `/create-stories`,
   and `/architecture-review`. **BLOCKING.**

2. **Valid status values** — check that Status column values are only from:
   `Not Started`, `In Progress`, `In Review`, `Designed`, `Approved`, `Needs Revision`.
   Flag any unrecognised values.

3. **Column structure** — check that the table has at minimum: App, Layer,
   Priority, Status columns. Missing columns degrade skill functionality.

### 2d: Story Format Audit

For each story file found:

- **`Manifest Version:` field** — present in story header? (LOW — auto-passes if absent)
- **Requirement reference** — does the story contain a `REQ-[A-Z]{2,5}-[0-9]{3}`
  pattern? (MEDIUM — no staleness tracking)
- **ADR reference** — does the story reference at least one ADR, or an explicit
  `ADR: N/A — [reason]`? (MEDIUM — no architectural guidance recorded)
- **`Type:` field** — present and one of the canonical story types? (MEDIUM — test
  evidence requirements cannot be resolved)
- **Status field** — present and readable?
- **Acceptance criteria** — does the story have a checkbox list (`- [ ]`)?

### 2e: Infrastructure Audit

| Artifact | Path | Impact if missing |
|---|---|---|
| App registry | `docs/registry/apps.json` | HIGH — `/start` and `/help` cannot list apps |
| Requirements registry | `docs/architecture/apps/<app>/requirements.yaml` | HIGH — no stable requirement IDs |
| Control manifest | `docs/architecture/apps/<app>/control-manifest.md` | HIGH — no per-app rules for stories |
| Manifest version stamp | In manifest header: `Manifest Version:` | MEDIUM — staleness checks blind |
| Sprint status | `production/sprints/sprint-status.yaml` | MEDIUM — `/sprint-status` falls back to markdown |
| Stage file | `production/stage.txt` | MEDIUM — phase auto-detect unreliable |
| App status | `apps/<app>/status.md` | MEDIUM — per-app stage is invisible |
| Gate approvals | `apps/<app>/approvals.json` | MEDIUM — gate history is lost |

### 2f: Technical Preferences Audit

Read `.claude/docs/technical-preferences.md`. Check each field for `[TO BE CONFIGURED]`:
- Stack, Language, Platform API version, Hosting → HIGH if unconfigured (ADR skills fail)
- Naming conventions → MEDIUM
- Performance budgets → MEDIUM
- Forbidden Patterns, Allowed Libraries → LOW (starts empty by design)

---

## Phase 3: Classify and Prioritise Gaps

Organise every gap found across all audits into four severity tiers:

**BLOCKING** — Will cause template skills to silently produce wrong results *right now*.
Examples: ADR missing Status field, requirements entries missing `id` or `status`,
parenthetical status values in the app index, stack not configured when ADRs exist.

**HIGH** — Will cause stories to be generated with missing safety checks, or
infrastructure bootstrapping will fail.
Examples: ADRs missing Platform Compatibility, requirements missing acceptance
criteria (stories cannot be derived from them), `apps.json` missing.

**MEDIUM** — Degrades quality and pipeline tracking but does not break functionality.
Examples: requirements missing `source`, stories missing requirement IDs,
`sprint-status.yaml` missing, `apps/<app>/status.md` missing.

**LOW** — Retroactive improvements that are nice-to-have but not urgent.
Examples: stories missing Manifest Version stamps, requirements missing edge cases.

Count totals per tier. If zero BLOCKING and zero HIGH gaps: report that the project
is template-compatible and only advisory improvements remain.

---

## Phase 4: Build the Migration Plan

Compose a numbered, ordered action plan. Ordering rules:
1. BLOCKING gaps first (must fix before any pipeline skill runs reliably)
2. HIGH gaps next, infrastructure before requirement/ADR content (bootstrapping needs correct formats)
3. MEDIUM gaps ordered: requirements before ADRs before stories (stories depend on both)
4. LOW gaps last

For each gap, produce a plan entry with:
- A clear problem statement (one sentence, no jargon)
- The exact command to fix it, if a skill handles it
- Manual steps if it requires direct editing
- A time estimate (rough: 5 min / 30 min / 1 session)
- A checkbox `- [ ]` for tracking

**Special case — parenthetical status values in the app index:**
This is always the first item if present. Show the exact values that need changing
and the exact replacement text. Offer to fix this immediately before writing the plan.

**Special case — ADRs missing Status field:**
For each affected ADR, the fix is:
`/architecture-decision retrofit docs/architecture/apps/[app]/ADR-[NNNN]-[slug].md`
List each ADR as a separate checkable item.

**Special case — requirements missing sections:**
For each affected app, list which keys are missing and the fix:
`/create-architecture [app]` for structural gaps, or a direct edit of
`docs/architecture/apps/[app]/requirements.yaml` for per-entry gaps.

**Infrastructure bootstrap ordering** — always present in this sequence:
1. Fix ADR formats first (the registry depends on reading ADR Status fields)
2. Run `/architecture-review` → validates and indexes requirement coverage
3. Run `/create-control-manifest` → creates the manifest with a version stamp
4. Run `/sprint-plan update` → creates `production/sprints/sprint-status.yaml`
5. Run `/gate-check [phase]` → writes `production/stage.txt` authoritatively

**Existing stories** — note explicitly:
> "Existing stories continue to work with all template skills — all new format
> checks auto-pass when the fields are absent. They won't benefit from requirement
> staleness tracking or manifest version checks until they're regenerated. This
> is intentional: do not regenerate stories that are already in progress."

---

## Phase 5: Present Summary and Ask to Write

Present a compact summary before writing:

```
## Adoption Audit Summary
Phase detected: [phase]
Stack: [configured / NOT CONFIGURED]
Apps audited: [N]
Requirement files audited: [N] ([X] fully compliant, [Y] with gaps)
ADRs audited: [N] ([X] fully compliant, [Y] with gaps)
Stories audited: [N]

Gap counts:
  BLOCKING: [N] — template skills will malfunction without these fixes
  HIGH:     [N] — unsafe to run /create-stories or /story-readiness
  MEDIUM:   [N] — quality degradation
  LOW:      [N] — optional improvements

Estimated remediation: [X blocking items × ~Y min each = roughly Z hours]
```

Before asking to write, show a **Gap Preview**:
- List every BLOCKING gap as a one-line bullet describing the actual problem
  (e.g. `ADR-0002.md: missing ## Status section`,
  `discount-bundles/requirements.yaml: 3 entries missing acceptance_criteria`).
  No counts — show the actual items.
- Show HIGH / MEDIUM / LOW as counts only (e.g. `HIGH: 4, MEDIUM: 2, LOW: 1`).

This gives the user enough context to judge scope before committing to writing the file.

If a prior adoption plan was detected in Phase 1, add a note:
> "A previous plan exists at `docs/adoption-plan-[prior-date].md`. The new plan will
> reflect current project state — it does not diff against the prior run."

Use `AskUserQuestion`, `request_user_input` or `clarify`:
- "Ready to write the migration plan?"
  - "Yes — write `docs/adoption-plan-[date].md`"
  - "Show me the full plan preview first (don't write yet)"
  - "Cancel — I'll handle migration manually"

If the user picks "Show me the full plan preview", output the complete plan as a
fenced markdown block. Then ask again with the same three options.

---

## Phase 6: Write the Adoption Plan

If approved, write `docs/adoption-plan-[date].md` with this structure:

```markdown
# Adoption Plan

> **Generated**: [date]
> **Project phase**: [phase]
> **Stack**: [name + version, or "Not configured"]
> **Template version**: v1.0+

Work through these steps in order. Check off each item as you complete it.
Re-run `/adopt` anytime to check remaining gaps.

---

## Step 1: Fix Blocking Gaps

[One sub-section per blocking gap with problem, fix command, time estimate, checkbox]

---

## Step 2: Fix High-Priority Gaps

[One sub-section per high gap]

---

## Step 3: Bootstrap Infrastructure

### 3a. Register existing requirements
Run `/architecture-review` — even if ADRs already exist, this run validates the
`requirements.yaml` files and rebuilds coverage for your existing artifacts.
**Time**: 1 session (review can be long for large codebases)
- [ ] `docs/architecture/apps/[app]/requirements.yaml` validated

### 3b. Create control manifest
Run `/create-control-manifest`
**Time**: 30 min
- [ ] `docs/architecture/apps/[app]/control-manifest.md` created

### 3c. Create sprint tracking file
Run `/sprint-plan update`
**Time**: 5 min (if a sprint plan already exists as markdown)
- [ ] `production/sprints/sprint-status.yaml` created

### 3d. Set authoritative project stage
Run `/gate-check [current-phase]`
**Time**: 5 min
- [ ] `production/stage.txt` written

---

## Step 4: Medium-Priority Gaps

[One sub-section per medium gap]

---

## Step 5: Optional Improvements

[One sub-section per low gap]

---

## What to Expect from Existing Stories

Existing stories continue to work with all template skills. New format checks
(requirement ID validation, manifest version staleness) auto-pass when the fields
are absent — so nothing breaks. They won't benefit from staleness tracking until
regenerated. Do not regenerate stories that are in progress or done.

---

## Re-run

Run `/adopt` again after completing Step 3 to verify all blocking and high gaps
are resolved. The new run will reflect the current state of the project.
```

---

## Phase 6b: Set Review Mode

After writing the adoption plan (or if the user cancels writing), check whether
`production/review-mode.txt` exists.

**If it exists**: Read it and note the current mode — "Review mode is already set to `[current]`." — skip the prompt.

**If it does not exist**: Use `AskUserQuestion`, `request_user_input` or `clarify`:

- **Prompt**: "One more setup step: how much review would you like as you work through the workflow?"
- **Options**:
  - `Full` — Director specialists review at each key workflow step. Best for teams, learning the workflow, or when you want thorough feedback on every decision.
  - `Lean (recommended)` — Directors only at phase gate transitions (/gate-check). Skips per-skill reviews. Balanced for solo devs and small teams.
  - `Solo` — No director reviews at all. Maximum speed. Best for prototypes or if reviews feel like overhead.

Write the choice to `production/review-mode.txt` immediately after selection — no separate "May I write?" needed:
- `Full` → write `full`
- `Lean (recommended)` → write `lean`
- `Solo` → write `solo`

Create the `production/` directory if it does not exist.

---

## Phase 7: Offer First Action

After writing the plan, don't stop there. Pick the single highest-priority gap
and offer to handle it immediately using `AskUserQuestion`, `request_user_input` or `clarify`. Choose the first
branch that applies:

**If there are parenthetical status values in the app index:**
Use `AskUserQuestion`, `request_user_input` or `clarify`:
- "The most urgent fix is the app index — [N] rows have parenthetical status
  values (e.g. `Needs Revision (see notes)`) that break /gate-check,
  /create-stories, and /architecture-review right now. I can fix these in-place."
  - "Fix it now — edit the app index"
  - "I'll fix it myself"
  - "Done — leave me with the plan"

**If ADRs are missing `## Status` (and no parenthetical issue):**
Use `AskUserQuestion`, `request_user_input` or `clarify`:
- "The most urgent fix is adding `## Status` to [N] ADR(s): [list filenames].
  Without it, /story-readiness silently passes all ADR checks. Start with
  [first affected filename]?"
  - "Yes — retrofit [first affected filename] now"
  - "Retrofit all [N] ADRs one by one"
  - "I'll handle ADRs myself"

**If requirements are missing acceptance criteria (and no blocking issues above):**
Use `AskUserQuestion`, `request_user_input` or `clarify`:
- "The most urgent gap is missing acceptance criteria in [N] requirement file(s):
  [list filenames]. Without them, /create-stories can't generate stories.
  Start with [highest-priority app]?"
  - "Yes — add acceptance criteria to [app] now"
  - "Do all [N] apps one by one"
  - "I'll handle requirements myself"

**If no BLOCKING or HIGH gaps exist:**
Use `AskUserQuestion`, `request_user_input` or `clarify`:
- "No blocking gaps — this project is template-compatible. What next?"
  - "Walk me through the medium-priority improvements"
  - "Run /project-stage-detect for a broader health check"
  - "Done — I'll work through the plan at my own pace"

> **Adoption plan saved to `docs/adoption-plan-[date].md`.** Re-run `/adopt` at any time to re-check remaining gaps as you complete them.

---

## Collaborative Protocol

1. **Read silently** — complete the full audit before presenting anything
2. **Show the summary first** — let the user see scope before asking to write
3. **Ask before writing** — always confirm before creating the adoption plan file
4. **Offer, don't force** — the plan is advisory; the user decides what to fix and when
5. **One action at a time** — after handing off the plan, offer one specific next step,
   not a list of six things to do simultaneously
6. **Never regenerate existing artifacts** — only fill gaps in what exists;
   do not rewrite requirements, ADRs, or stories that already have content
