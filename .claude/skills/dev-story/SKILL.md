---
name: dev-story
description: "Read a story file and implement it. Loads the full context (story, requirement, ADR guidelines, control manifest), routes to the right specialist agent for the module and platform surface, implements the code and test, and confirms each acceptance criterion. The core implementation skill — run after /story-readiness, before /code-review and /story-done."
argument-hint: "[story-path]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash, Task, AskUserQuestion, request_user_input, clarify
model: sonnet
---

# Dev Story

This skill bridges planning and code. It reads a story file in full, assembles
all the context a developer needs, routes to the correct specialist agent, and
drives implementation to completion — including writing the test.

**The loop for every story:**
```
/qa-plan sprint           ← define test requirements before sprint begins
/story-readiness [path]   ← validate before starting
/dev-story [path]         ← implement it  (this skill)
/code-review [files]      ← review it
/story-done [path]        ← verify and close it
```

**After all sprint stories are done:** run `/smoke-check` and `/regression-suite`
to confirm nothing outside the sprint broke before advancing the project stage.

**Output:** Source code + test file in `apps/[app]/` and `tests/`.

---

## Phase 1: Find the Story

**If a path is provided**: read that file directly.

**If no argument**: check `production/session-state/active.md` for the active
story. If found, confirm: "Continuing work on [story title] — is that correct?"
If not found, ask: "Which story are we implementing?" Glob
`production/epics/**/*.md` and list stories with Status: Ready.

---

## Phase 2: Load Full Context

**Before loading any context, verify required files exist.** Extract the ADR path from the story's `ADR Governing Implementation` field, read the story's `App` field, then check:

| File | Path | If missing |
|------|------|------------|
| Requirements file | `docs/architecture/apps/[app]/requirements.yaml` | **STOP** — "Requirements file not found at `docs/architecture/apps/[app]/requirements.yaml`. Run `/create-architecture [app]` to author it." |
| Governing ADR | path from story's ADR field | **STOP** — "ADR file [path] not found. Run `/architecture-decision` to create it, or correct the filename in the story's ADR field." |
| Control manifest | `docs/architecture/apps/[app]/control-manifest.md` | **WARN and continue** — "Control manifest not found — layer rules cannot be checked. Run `/create-control-manifest`." |

If the requirements file or governing ADR is missing, set the story status to **BLOCKED** in the session state and do not spawn any specialist agent.

Read all of the following simultaneously — these are independent reads. Do not start implementation until all context is loaded:

### The story file
Extract and hold:
- **Story title, ID, app, layer, type** (Logic / Integration / UX/Visual / UI / Config/Data)
- **Requirement ID** — the `REQ-[APP]-NNN` identifier
- **Governing ADR** reference
- **Manifest Version** embedded in story header
- **Acceptance Criteria** — every checkbox item, verbatim
- **Implementation Notes** — the ADR guidance section in the story
- **Out of Scope** boundaries
- **Test Evidence** — the required test file path
- **Dependencies** — what must be DONE before this story

### The requirements file
Read `docs/architecture/apps/[app]/requirements.yaml`. Look up the story's requirement ID.
Read the current `acceptance_criteria` and `title` — this is the source of truth
for what the app requires now. Do not rely on any inline text in the story file
(may be stale).

### The governing ADR
Read `docs/architecture/apps/[app]/[adr-file].md`. Extract:
- The full Decision section
- The Implementation Guidelines section (this is what the developer follows)
- The Platform Compatibility section (API versions, deprecations, known risks)
- The ADR Dependencies section

### The control manifest
Read `docs/architecture/apps/[app]/control-manifest.md`. Extract the rules for this story's layer:
- Required patterns
- Forbidden patterns
- Performance and security guardrails

Check: does the story's embedded Manifest Version match the current manifest header date?
If they differ, use `AskUserQuestion`, `request_user_input` or `clarify` before proceeding:
- Prompt: "Story was written against manifest v[story-date]. Current manifest is v[current-date]. New rules may apply. How do you want to proceed?"
- Options:
  - `[A] Update story manifest version and implement with current rules (Recommended)`
  - `[B] Implement with old rules — I accept the risk of non-compliance`
  - `[C] Stop here — I want to review the manifest diff first`

If [A]: edit the story file's `Manifest Version:` field to the current manifest date before spawning the specialist. Then read the manifest carefully for new rules.
If [B]: edit the story file's `Manifest Version:` field to the current manifest date AND add a `Manifest-Note: Proceeded with old manifest rules on [date] — non-compliance risk accepted.` line to the story header. Read the manifest for new rules anyway. Note the decision in the Phase 6 summary under "Deviations". `/story-done` will include the Manifest-Note in its deviations section without re-checking staleness.
If [C]: stop. Do not spawn any agent. Let the user review and re-run `/dev-story`.

### Dependency validation

After extracting the **Dependencies** list from the story file, validate each:

1. Glob `production/epics/**/*.md` to find each dependency story file.
2. Read its `Status:` field.
3. If any dependency has Status other than `Complete` or `Done`:
   - Use `AskUserQuestion`, `request_user_input` or `clarify`:
     - Prompt: "Story '[current story]' depends on '[dependency title]' which is currently [status], not Complete. How do you want to proceed?"
     - Options:
       - `[A] Proceed anyway — I accept the dependency risk`
       - `[B] Stop — I'll complete the dependency first`
       - `[C] The dependency is done but status wasn't updated — mark it Complete and continue`
   - If [B]: set story status to **BLOCKED** in session state and stop. Do not spawn any specialist agent.
   - If [C]: ask "May I update [dependency path] Status to Complete?" before continuing.
   - If [A]: note in Phase 6 summary under "Deviations": "Implemented with incomplete dependency: [dependency title] — [status]."

If a dependency file cannot be found: warn "Dependency story not found: [path]. Verify the path or create the story file."

---

### Stack preferences
Read `.claude/docs/technical-preferences.md`:
- `Stack:` value — determines which specialist agents to use
- Naming conventions (component names, file names, event names)
- Performance budgets (response time, payload size, query cost)
- Forbidden patterns

### Mark Story In Progress

Silently update two things before spawning any agent:

1. **`production/sprints/sprint-status.yaml`** (if it exists): find the entry matching this story's file path and set `status: in_progress`. Update the top-level `updated` field to today's date. If the file does not exist, skip silently.

2. **The story file itself**: edit the `Last Updated:` field in the story header to today's date (format: `YYYY-MM-DD`). If the field does not exist in the story header, add it after the `Status:` line. This enables sprint-status staleness detection for this story.

---

## Phase 3: Route to the Right Specialist

Based on the story's **Layer**, **Type**, and **module**, determine which
specialist to spawn via Task. Every agent named here is on the project roster
(`.claude/docs/agent-roster.md`).

**Config/Data stories — skip agent spawning entirely:**
If the story's Type is `Config/Data`, no specialist agent is needed. Jump directly to Phase 4 (Config/Data note). The implementation is a data or configuration file edit — no routing table evaluation.

### Primary agent routing table

| Story context | Primary agent |
|---|---|
| Foundation layer — any type | `lead-engineer` |
| Any layer — Type: UI, embedded admin surface | `app-bridge-specialist` |
| Any layer — Type: UI, admin components and tables | `polaris-specialist` |
| Any layer — Type: UI, storefront surface | `liquid-specialist` |
| Any layer — Type: UX/Visual (layout, theming, responsive) | `ux-lead` with `app-bridge-specialist` or `liquid-specialist` as the implementer |
| Core or Feature — API queries and mutations | `graphql-specialist` |
| Core or Feature — event delivery, webhook handlers | `webhooks-specialist` |
| Core or Feature — plans, charges, subscription state | `billing-specialist` |
| Core or Feature — installation, OAuth, session tokens, scopes | `auth-specialist` |
| Core or Feature — checkout extensions and functions | `checkout-specialist` |
| Core or Feature — CI, deployment, environment config | `devops-engineer` |
| Core or Feature — event instrumentation, reporting | `analytics-engineer` |
| Config/Data — no code | No agent needed (see Phase 4 Config note) |

### Platform specialist — always spawn as secondary for risky stories

Read the `Platform Specialists` section of `.claude/docs/technical-preferences.md`
to get the configured primary specialist. Spawn them alongside the primary agent
when the story involves platform APIs, deprecations, or the ADR has HIGH platform risk.

| Surface | Specialist agents available |
|---------|-----------------------------|
| Admin GraphQL API | `graphql-specialist`, `api-lead` |
| Embedded admin UI (App Bridge) | `app-bridge-specialist`, `polaris-specialist` |
| Storefront / theme | `liquid-specialist`, `performance-analyst` |
| Webhooks and background jobs | `webhooks-specialist`, `devops-engineer` |
| Checkout and payments | `checkout-specialist`, `billing-specialist` |
| Merchant-facing accessibility | `accessibility-specialist` |

**When platform risk is HIGH** (from the ADR): always spawn the platform
specialist, even for stories that do not touch the platform API directly. High
risk means the ADR records assumptions about API versions or deprecations that
need expert verification.

---

## Phase 4: Implement

Spawn the chosen specialist agent(s) via Task with the full context package:

Brief the agent with file paths and targeted reading instructions — do not serialize document content into the Task prompt. The agent reads what it needs directly:

1. **Story file**: `[story-path]` — read in full
2. **Requirement**: look up `[REQ-APP-NNN]` in `docs/architecture/apps/[app]/requirements.yaml` — use the `acceptance_criteria` field as source of truth
3. **ADR**: `docs/architecture/apps/[app]/[adr-file].md` — read the **Decision** and **Implementation Guidelines** sections only
4. **Control manifest**: `docs/architecture/apps/[app]/control-manifest.md` — read rules for the **[layer]** layer only
5. **Stack preferences**: `.claude/docs/technical-preferences.md` — read naming conventions and performance budgets
6. **Test file path**: `[path from story's Test Evidence section]` — this file must be created as part of implementation
7. **Test requirement** (Logic and Integration stories only): The test file MUST be created at `[path from the story's Test Evidence section]`. Write the test alongside the implementation — do not defer it. The story cannot be closed via `/story-done` without this file present. Each acceptance criterion must have at least one test function covering it. Test file naming: `[module]_[feature]_test.[ext]`. Function naming: `test_[scenario]_[expected_outcome]`. No time-dependent assertions, no live network calls in unit tests.
8. **Explicit instruction**: implement this story following the ADR guidelines, respect the manifest rules, stay within the story's Out of Scope boundaries. Write clean, doc-commented public interfaces.

The agent should:
- Create or modify files under `apps/[app]/` following the ADR guidelines
- Respect all Required and Forbidden patterns from the control manifest
- Stay within the story's Out of Scope boundaries (do not touch unrelated files)
- Write clean, doc-commented public interfaces

### Config/Data stories (no agent needed)

For Type: Config/Data stories, no specialist agent is required. The implementation
is editing a data or configuration file. Read the story's acceptance criteria and
make the specified changes directly. Note which values were changed and what they
changed from/to.

### UX/Visual stories

Spawn `ux-lead` alongside the surface implementer. Note that UX/Visual
acceptance criteria cannot be auto-verified — the "does this read correctly and
look right?" check happens in `/story-done` via manual confirmation with evidence.

---

## Phase 5: Test Evidence Requirements

The test requirement was included in the Phase 4 agent brief (item 7). This phase summarizes what evidence each story type requires — used when collecting the Phase 6 summary.

| Story Type | Required Evidence | Notes |
|---|---|---|
| **Logic** | Automated unit test at path from story's Test Evidence section | BLOCKING — included in Phase 4 agent brief |
| **Integration** | Integration test OR documented manual verification | BLOCKING — included in Phase 4 agent brief |
| **UX/Visual** | Evidence doc at `production/qa/evidence/[slug]-evidence.md` | ADVISORY — note in Phase 6 summary |
| **UI** | Manual walkthrough doc or interaction test | ADVISORY — note in Phase 6 summary |
| **Config/Data** | None — smoke check serves as evidence | N/A |

For UX/Visual and UI stories, include in the Phase 6 summary: "Manual evidence required at `production/qa/evidence/[slug]-evidence.md` before this story can be fully closed."

---

## Phase 6: Collect and Summarise

After the specialist agent(s) complete, collect:

- Files created or modified (with paths)
- Test file created (path and number of test functions written)
- Any deviations from the story's Out of Scope boundary (flag these)
- Any questions or blockers the agent surfaced
- Any platform-specific risks the specialist flagged

Present a concise implementation summary:

```
## Implementation Complete: [Story Title]

**Files changed**:
- `apps/[app]/[path]` — created / modified ([brief description])
- `tests/[path]` — test file ([N] test functions)

**Acceptance criteria covered**:
- [x] [criterion] — implemented in [file:function]
- [x] [criterion] — covered by test [test_name]
- [ ] [criterion] — DEFERRED: requires manual verification (UX/Visual)

**Deviations from scope**: [None] or [list files touched outside story boundary]
**Platform risks flagged**: [None] or [specialist finding]
**Blockers**: [None] or [describe]

**Before running `/story-done`:** run your test suite locally and confirm the tests you wrote pass. `/story-done` will re-run them automatically, but a failing test discovered there means returning to implementation context.

Ready for: `/code-review [file1] [file2]` then `/story-done [story-path]`
```

---

## Phase 7: Update Session State

Silently append to `production/session-state/active.md`:

```
## Session Extract — /dev-story [date]
- Story: [story-path] — [story title]
- Files changed: [comma-separated list]
- Test written: [path, or "None — UX/Visual/Config story"]
- Blockers: [None, or description]
- Next: /code-review [files] then /story-done [story-path]
```

Create `active.md` if it does not exist. Confirm: "Session state updated."

---

## Error Recovery Protocol

If any spawned agent (via Task) returns BLOCKED, errors, or cannot complete:

1. **Surface immediately**: Report "[AgentName]: BLOCKED — [reason]" to the user before continuing to dependent phases
2. **Assess dependencies**: Check whether the blocked agent's output is required by subsequent phases. If yes, do not proceed past that dependency point without user input.
3. **Offer options** via AskUserQuestion, request_user_input or clarify with choices:
   - Skip this agent and note the gap in the final report
   - Retry with narrower scope
   - Stop here and resolve the blocker first
4. **Always produce a partial report** — output whatever was completed. Never discard work because one agent blocked.

Common blockers:
- Input file missing (story not found, requirements absent) → redirect to the skill that creates it
- ADR status is Proposed → do not implement; run `/architecture-decision` first
- Scope too large → split into two stories via `/create-stories`
- Conflicting instructions between ADR and story → surface the conflict, do not guess
- Manifest version mismatch → show diff to user, ask whether to proceed with old rules or update story first

## Collaborative Protocol

- **File writes are delegated** — all source code, test files, and evidence docs are written by sub-agents spawned via Task. Each sub-agent enforces the "May I write to [path]?" protocol individually. This orchestrator does not write files directly.
- **Load before implementing** — do not start coding until all context is loaded
  (story, requirement, ADR, manifest, stack prefs). Incomplete context produces code
  that drifts from specification.
- **The ADR is the law** — implementation must follow the ADR's Implementation
  Guidelines. If the guidelines conflict with what seems "better," flag it in the
  summary rather than silently deviating.
- **Stay in scope** — the Out of Scope section is a contract. If implementing
  the story requires touching an out-of-scope file, stop and surface it:
  "Implementing [criterion] requires modifying [file], which is out of scope.
  Shall I proceed or create a separate story?"
- **Test is not optional for Logic/Integration** — do not mark implementation
  complete without the test file existing
- **UX/Visual criteria are deferred, not skipped** — mark them as DEFERRED
  in the summary; they will be manually verified in `/story-done`
- **Ask before large structural decisions** — if the story requires an
  architectural pattern not covered by the ADR, surface it before implementing:
  "The ADR doesn't specify how to handle [case]. My plan is [X]. Proceed?"

---

## Recommended Next Steps

- Run `/code-review [file1] [file2]` to review the implementation before closing the story
- Run `/story-done [story-path]` to verify acceptance criteria and mark the story complete
- After all sprint stories are done: run `/smoke-check` and `/regression-suite` before advancing the project stage
