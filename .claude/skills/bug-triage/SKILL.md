---
name: bug-triage
description: "Use at sprint start or when the open bug count needs re-prioritising. Reads the open bug backlog, re-evaluates priority against severity by merchant impact, assigns fixes to sprints, surfaces systemic trends, and writes a triage report."
argument-hint: "[sprint | full | trend]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit
model: sonnet
---

# Bug Triage

This skill processes the open bug backlog into a prioritised, sprint-assigned
action list. It distinguishes between **severity** (how bad is the impact?) and
**priority** (how urgently must we fix it?), detects systemic trends, and
ensures no critical bug is lost between sprints.

**Output:** `production/qa/bug-triage-[date].md`

**When to run:**
- Sprint start — assign open bugs to the new sprint or backlog
- After a QA pass files new bugs — `/qa-plan` execution by `qa-lead` / `qa-tester`,
  or a `/code-review` that turned up defects
- When the bug count crosses 10+ open items

---

## 1. Parse Arguments

**Modes:**
- `/bug-triage sprint` — triage against the current sprint; assign fixable bugs
  to the sprint backlog; defer the rest
- `/bug-triage full` — full triage of all bugs regardless of sprint scope
- `/bug-triage trend` — trend analysis only (no assignment); read-only report
- No argument — run sprint mode if a current sprint exists, else full mode

---

## 2. Load Bug Backlog

### Step 2a — Discover bug files

Glob for bug reports in priority order:
1. `production/qa/bugs/*.md` — individual bug report files (preferred format)
2. `docs/qa/bugs/*.md` — where `qa-lead` and `qa-tester` file their reports
3. `production/qa/bugs.md` — single consolidated bug log (fallback)
4. Any `production/apps/<app>/qa/qa-plan-*.md` "Bugs Found" table (last resort)

If no bug files found:
> "No bug files found in `production/qa/bugs/`. If bugs are tracked in a
> different location, adjust the glob pattern. If no bugs exist yet, there is
> nothing to triage."

Stop and report. Do not proceed if no bugs exist.

### Step 2b — Load sprint context

Read the most recently modified sprint record — `production/sprints/` or
`production/apps/<app>/sprints/`, whichever holds the current plan — to understand:
- Current sprint number / name
- Stories in scope (for assignment target)
- Sprint capacity constraints (if noted)

If no sprint file exists: note "No sprint plan found — assigning to backlog only."

### Step 2c — Load severity reference

Read `.claude/docs/coding-standards.md` for severity/priority definitions if they
exist, and the app's control manifest for the guardrails that often decide severity
(API cost, latency, data limits). If neither defines severity, use Step 3.

---

## 3. Classify Each Bug

For each bug, extract or infer:

### Severity (impact of the bug)

Merchant impact decides severity. Ask "what can the merchant no longer do?" —
not "how wrong does the code look?".

| Severity | Definition |
|----------|-----------|
| **S1 — Critical** | Merchant is blocked or their data is wrong or lost: app will not load, checkout or order flow fails, unauthorised access, silent data corruption. No workaround. |
| **S2 — High** | A core flow is broken but a workaround exists: syncs fail on some stores, webhooks drop, a billing gate misfires, an admin page errors on a common state. |
| **S3 — Medium** | Degraded but usable: slow lists on large catalogs, misleading copy, a validation gap the merchant can step around, a single surface rendering incorrectly. |
| **S4 — Low** | Cosmetic or internal only: spacing, wording, log noise, a tooltip. No merchant-visible effect on the task. |

### Priority (urgency of the fix)

| Priority | Definition |
|----------|-----------|
| **P1 — Fix this sprint** | Blocks QA, blocks release, or is regression from last sprint |
| **P2 — Fix soon** | Should be resolved before the next major milestone |
| **P3 — Backlog** | Would be good to fix, but no active blocking impact |
| **P4 — Won't fix / Deferred** | Accepted risk or out of scope for current product scope |

### Assignment

For each P1/P2 bug in `sprint` mode:
- Identify which story or epic the fix belongs to
- Check whether the current sprint has remaining capacity
- If capacity exists: assign to sprint (`Sprint: [current]`)
- If capacity is full: flag as `Priority overflow — consider pulling from sprint`

For `full` mode: assign all P1 to current sprint, P2 to next sprint estimate,
P3+ to backlog.

### Deviation check

Flag bugs that suggest **systematic problems**:
- 3+ bugs from the same layer or module in the same sprint → "Potential design or
  implementation quality issue in [layer/module]"
- 2+ S1/S2 bugs in the same story → "Story may need to be reopened and
  re-reviewed before shipping"
- Bug filed against a story marked Complete → "Regression in completed story —
  story should be re-opened in sprint tracking"

---

## 4. Trend Analysis

After classifying all bugs, generate trend metrics:

### Volume trends
- Total open bugs: [N]
- Opened this sprint: [N]
- Closed this sprint: [N]
- Net change: [+N / -N]

### Component hot spots
- Which layer or module has the most open bugs?
- Which one has the highest S1/S2 ratio?

### Age analysis
- How many bugs are older than 2 sprints?
- Are any S1/S2 bugs un-assigned (sprint = none)?

### Regression indicator
- Any bugs filed against previously-completed stories?
- Count: [N] regression bugs (story reopened implied)

---

## 5. Generate Triage Report

```markdown
# Bug Triage Report

> **Date**: [date]
> **Mode**: [sprint | full | trend]
> **Generated by**: /bug-triage
> **Open bugs processed**: [N]
> **Sprint in scope**: [sprint name, or "N/A"]

---

## Triage Summary

| Priority | Count | Notes |
|----------|-------|-------|
| P1 — Fix this sprint | [N] | [N] assigned to sprint, [N] overflow |
| P2 — Fix soon | [N] | Scheduled for next sprint |
| P3 — Backlog | [N] | Deferred |
| P4 — Won't fix | [N] | Accepted risk |

**Critical (S1/S2) unfixed count**: [N]

---

## P1 Bugs — Fix This Sprint

| ID | Layer / Module | Severity | Summary | Assigned to | Story |
|----|----------------|----------|---------|-------------|-------|
| BUG-NNN | [layer/module] | S[1-4] | [one-line description] | [sprint] | [story path] |

---

## P2 Bugs — Fix Soon

| ID | Layer / Module | Severity | Summary | Target Sprint |
|----|----------------|----------|---------|---------------|
| BUG-NNN | [layer/module] | S[1-4] | [one-line description] | Sprint [N+1] |

---

## P3/P4 Bugs — Backlog / Won't Fix

| ID | Layer / Module | Severity | Summary | Disposition |
|----|----------------|----------|---------|-------------|
| BUG-NNN | [layer/module] | S4 | [one-line description] | Backlog |

---

## Systemic Issues Flagged

[List any patterns from Step 3 deviation check, or "None identified."]

---

## Trend Analysis

**Volume**: [N] open / [+N] net change this sprint
**Hot spot**: [layer/module with most bugs]
**Regressions**: [N] bugs against completed stories
**Aged bugs (>2 sprints old)**: [N]

[If N aged S1/S2 bugs > 0:]
> ⚠️ [N] high-severity bugs have been open for more than 2 sprints without
> assignment. These represent accepted risk that should be explicitly reviewed.

---

## Recommended Actions

1. [Most urgent action — usually "fix P1 bugs before QA hand-off"]
2. [Second action — usually "investigate [hot spot layer/module] quality"]
3. [Third action — optional improvement]
```

---

## 6. Write and Gate

Present the report in conversation, then ask:

"May I write this triage report to `production/qa/bug-triage-[date].md`?"

Write only after approval.

After writing:
- If any S1 bugs are unassigned: "S1 bugs must be assigned before the sprint
  can be considered healthy. Run `/sprint-status` to see current capacity."
- If regression bugs exist: "Regressions found — consider re-opening the
  affected stories in sprint tracking and running `/smoke-check` to re-gate."
- If no P1 bugs exist: "No P1 bugs — build is in good shape for QA hand-off." Verdict: **COMPLETE** — triage report written.

If user declined write: Verdict: **BLOCKED** — user declined write.

---

## Collaborative Protocol

- **Never close or mark bugs Won't Fix without user approval** — surface them
  as P4 candidates and ask: "Are these acceptable as Won't Fix?"
- **Never auto-assign to a sprint at capacity** — flag overflow and let the
  sprint owner decide what to pull
- **Severity is objective; priority is a team decision** — present severity
  classifications as recommendations, not mandates
- **Trend data is informational** — do not block work on trend findings alone;
  surface them as observations
