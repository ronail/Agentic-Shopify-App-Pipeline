---
name: create-epics
description: "Translate approved app requirements + architecture into epics — one epic per architectural module. Defines scope, governing ADRs, platform risk, and untraced requirements. Does NOT break into stories — run /create-stories [epic-slug] after each epic is created."
argument-hint: "[module-name | layer: foundation|core|feature|presentation | all] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Task, AskUserQuestion, request_user_input, clarify
model: sonnet
agent: technical-director
---

# Create Epics

An epic is a named, bounded body of work that maps to one architectural module.
It defines **what** needs to be built and **who owns it architecturally**. It
does not prescribe implementation steps — that is the job of stories.

**Run this skill per app.** Epics live under `production/epics/<epic>/` and are
scoped to a single app; never mix two apps in one epic.

**Run this skill once per layer** as you approach that layer in development.
Do not create Feature layer epics until Core is nearly complete — the design
will have changed.

**Output:** `production/epics/[epic-slug]/EPIC.md` + `production/epics/index.md`

**Next step after each epic:** `/create-stories [epic-slug]`

**When to run:** After `/create-control-manifest` and `/architecture-review` pass.

---

## 1. Parse Arguments

Resolve the review mode (once, store for all gate spawns this run):
1. If `--review [full|lean|solo]` was passed → use that
2. Else read `production/review-mode.txt` → use that value
3. Else → default to `lean`

See `.claude/docs/director-gates.md` for the full check pattern.

**Modes:**
- `/create-epics all` — process all modules in layer order
- `/create-epics layer: foundation` — Foundation layer only
- `/create-epics layer: core` — Core layer only
- `/create-epics layer: feature` — Feature layer only
- `/create-epics layer: presentation` — Presentation layer only
- `/create-epics [module-name]` — one specific architectural module
- No argument — list the apps in `docs/registry/apps.json`, ask which app and
  which module, then continue

---

## 2. Load Inputs

### Step 2a — Summary scan (fast)

Grep every in-scope `requirements.yaml` for requirement titles and priorities
before reading anything fully:

```
Grep pattern="^  - id:|title:|priority:" glob="docs/architecture/apps/*/requirements.yaml" output_mode="content"
```

For `layer:` or `[module-name]` modes: filter to only in-scope modules based on
the architecture module table. Skip full-reading anything out of scope.

### Step 2b — Full document load (in-scope modules only)

Using the Step 2a results, identify which modules are in scope. Read full
documents **only for in-scope modules** — do not read requirement files or ADRs
for out-of-scope modules or apps.

Read for in-scope modules:

- `docs/architecture/apps/[app]/requirements.yaml` — authoritative requirement list,
  IDs `REQ-[APP]-NNN`, statuses and priorities
- In-scope ADRs only (`Approved` or `Accepted` status, filtered by Step 2a results)
- `docs/architecture/architecture.md` — module ownership and API boundaries
- Accepted ADRs **whose domains cover in-scope modules only** — read the
  "Requirements Addressed", "Decision", and "Platform Compatibility" sections;
  skip ADRs for unrelated domains
- `docs/architecture/apps/[app]/control-manifest.md` — manifest version date from header
- `apps/[app]/status.md` — current stage, blockers, last approved gate
- `docs/architecture/apps/[app]/ADR-*.md` — for tracing requirements to ADR coverage

Report: "Loaded [N] requirements, [M] ADRs, app: [name], stack: [name + version]."

---

## 3. Processing Order

Process in dependency-safe layer order:
1. **Foundation** (no dependencies)
2. **Core** (depends on Foundation)
3. **Feature** (depends on Core)
4. **Presentation** (depends on Feature + Core)

Within each layer, use the order from the architecture module table (or the
priority column in `requirements.yaml`).

---

## 4. Define Each Epic

For each module, map it to a slice of behaviour from the app's architecture.

Check ADR coverage against the requirement list:
- **Traced requirements**: `REQ-` IDs that have an accepted ADR covering them
- **Untraced requirements**: `REQ-` IDs with no ADR — warn before proceeding

Present to user before writing anything:

```
## Epic: [Module Name]

**App**: apps/[app]/
**Layer**: [Foundation / Core / Feature / Presentation]
**Architecture Module**: [module name from architecture.md]
**Requirements**: docs/architecture/apps/[app]/requirements.yaml
**Governing ADRs**: [ADR-NNNN, ADR-MMMM]
**Platform Risk**: [LOW / MEDIUM / HIGH — highest risk among governing ADRs]
**Requirements Covered by ADRs**: [N / total]
**Untraced Requirements**: [list REQ-IDs with no ADR, or "None"]
```

If there are untraced requirements:
> "⚠️ [N] requirements in [module] have no ADR. The epic can be created, but
> stories for these requirements will be marked Blocked until ADRs exist.
> Run `/architecture-decision` first, or proceed with placeholders."

Use `AskUserQuestion`, `request_user_input` or `clarify`:
- Prompt: "Shall I create Epic: [name]?"
- Options:
  - `[A] Yes, create it`
  - `[B] Skip this epic`
  - `[C] Pause — I need to write ADRs first`

---

## 4b. Producer Epic Structure Gate

**Review mode check** — apply before spawning PR-EPIC:
- `solo` → skip. Note: "PR-EPIC skipped — Solo mode." Proceed to Step 5 (write epic files).
- `lean` → skip (not a PHASE-GATE). Note: "PR-EPIC skipped — Lean mode." Proceed to Step 5 (write epic files).
- `full` → spawn as normal.

After all epics for the current layer are defined (Step 4 completed for all in-scope modules), and before writing any files, spawn `producer` via Task using gate **PR-EPIC** (`.claude/docs/director-gates.md`).

Pass: the full epic structure summary (all epics, their scope summaries, governing ADR counts), the layer being processed, milestone timeline and team capacity.

Present the producer's assessment.

If OVERSCOPED: offer to revise epic boundaries (split overscoped or merge underscoped epics). Revise and re-run the gate before writing.

If CONCERNS, use `AskUserQuestion`, `request_user_input` or `clarify`:
- Prompt: "Producer raised concerns about the epic structure. How do you want to proceed?"
- Options:
  - `[A] Proceed as planned — I accept the producer's concerns`
  - `[B] Revise epic boundaries — split or merge as recommended`
  - `[C] Stop — I want to reconsider the scope`

If [A]: proceed to Step 5.
If [B]: revise epic definitions from Step 4 and re-run the producer gate.
If [C]: stop. Verdict: **BLOCKED** — user wants to reconsider epic scope.

Do not write epic files until the producer gate resolves.

---

## 5. Write Epic Files

After approval, ask: "May I write the epic file to `production/epics/[epic-slug]/EPIC.md`?"

After user confirms, write:

### `production/epics/[epic-slug]/EPIC.md`

```markdown
# Epic: [Module Name]

> **App**: apps/[app]/
> **Layer**: [Foundation / Core / Feature / Presentation]
> **Requirements**: docs/architecture/apps/[app]/requirements.yaml
> **Architecture Module**: [module name]
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories [epic-slug]`

## Overview

[1 paragraph describing what this epic implements, derived from the requirement
entries and the architecture module's stated responsibilities]

## Governing ADRs

| ADR | Decision Summary | Platform Risk |
|-----|------------------|---------------|
| ADR-NNNN: [title] | [1-line summary] | LOW/MEDIUM/HIGH |

## Requirements

| Requirement ID | Requirement | ADR Coverage |
|----------------|-------------|--------------|
| REQ-[APP]-001 | [requirement text from requirements.yaml] | ADR-NNNN ✅ |
| REQ-[APP]-002 | [requirement text] | ❌ No ADR |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- Every acceptance criterion in `docs/architecture/apps/[app]/requirements.yaml`
  that this epic covers is verified
- All Logic and Integration stories have passing test files in `tests/`
- All UX/Visual and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories [epic-slug]` to break this epic into implementable stories.
```

### Update `production/epics/index.md`

Create or update the master index:

```markdown
# Epics Index

Last Updated: [date]
Stack: [name + version]

| Epic | App | Layer | Requirements | Stories | Status |
|------|-----|-------|--------------|---------|--------|
| [name] | [app] | Foundation | [REQ count] | Not yet created | Ready |
```

---

## 6. Gate-Check Reminder

After writing all epics for the requested scope:

- **Foundation + Core complete**: These are required for the Pre-Production →
  Production gate. Run `/gate-check production` to check readiness.
- **Reminder**: Epics define scope. Stories define implementation steps. Run
  `/create-stories [epic-slug]` for each epic before developers can pick up work.

---

## Collaborative Protocol

1. **One epic at a time** — present each epic definition before asking to create it
2. **Warn on gaps** — flag untraced requirements before proceeding
3. **Ask before writing** — per-epic approval before writing any file
4. **No invention** — all content comes from requirements files, ADRs, and architecture docs
5. **Never create stories** — this skill stops at the epic level

After all requested epics are processed:

- **Verdict: COMPLETE** — [N] epic(s) written. Run `/create-stories [epic-slug]` per epic.
- **Verdict: BLOCKED** — user declined all epics, or no eligible modules found.
