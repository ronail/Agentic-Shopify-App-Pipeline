---
name: start
description: "Pipeline dashboard — reads docs/registry/apps.json, request.md, and every app status file, prints where each app stands, then routes to the right next skill. Also configures model routing via /start claude|codex|hermes."
argument-hint: "[claude|codex|hermes]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash, AskUserQuestion, request_user_input, clarify
model: sonnet
---

# Pipeline Dashboard

`/start` is the entry point for every session. It answers three questions in
order: **what was asked** (`request.md`), **where every app stands**
(`docs/registry/apps.json` plus each `apps/<app>/status.md`), and **what to run
next**.

It is read-only on app state. The only files it may write are
`production/review-mode.txt` and — in the `hermes` and `codex` branches —
`production/hermes-delegation.yaml` and `production/hermes-profile-mapping.json`.
It never creates an app directory, never edits `docs/registry/apps.json`, and
never starts a build.

**Optional argument**: `/start [claude|codex|hermes]`

- omitted → `claude` mode (default)
- `/start claude` → standard mode, no model-routing setup
- `/start hermes` → Phase 5, Hermes delegation routing
- `/start codex` → Phase 6, Codex model tier setup

## Phase 0 — Parse the argument

Accept `claude`, `codex`, or `hermes` (case-insensitive). Anything else: fall
back to `claude` and say which value was ignored. Store it as `mode`.

## Phase 1 — Read pipeline state

Read in this order. Every read is optional: a missing file becomes a dashboard
line, never an error.

1. `docs/registry/apps.json` — the ONE shared mutable registry. Shape:
   `{"apps": [{"slug","name","purpose","stage","last_approved_gate","created"}]}`.
   Tolerate a bare top-level array, slug-only strings, and missing keys;
   normalise in memory before printing.
2. `request.md` — `Version`, `Status`, `## Goal`, `## Gates`, `## Apps in scope`.
3. `request-history.md` — the last 3 table rows, sorted by timestamp.
4. For each registry slug:
   - `apps/<slug>/status.md` — `Stage`, `Last approved gate`, `Blockers`
   - `apps/<slug>/approvals.json` — approved gate ids and timestamps
   - `apps/<slug>/prototype/` — any entry besides `.gitkeep`?
   - `production/apps/<slug>/session-state/`, `sprints/`, `milestones/` —
     file count and newest mtime
   - whether `apps/<slug>/` exists at all; a registry entry with no directory is
     a **registry drift** line, not a crash
5. `production/review-mode.txt` — report only; set in Phase 4 only if missing.

If hand-parsing is unreliable, use Bash:

```bash
python3 - <<'PY'
import json
d = json.load(open("docs/registry/apps.json"))
apps = d.get("apps", d) if isinstance(d, dict) else d
for a in apps:
    if isinstance(a, str):
        print(a, "?")
    else:
        print(a.get("slug", "?"), a.get("stage", "?"))
PY
```

## Phase 2 — Print the dashboard

One screen, no prose padding:

```text
=== Shopify App Pipeline — Dashboard ===
Master request: v1 (active) | review mode: lean
Goal: <first sentence of request.md ## Goal>
Gates: gate-1-research > gate-2-prototype > gate-3-scope > gate-4-release > gate-5-update
Last request change: v1 — initial request (2026-10-29T00:00:00Z)

APPS (2)
| App | Stage | Last gate | Prototype | Pipeline | Next |
|-----|-------|-----------|-----------|----------|------|
| discount-bundles | research | gate-1-research | empty | 0 files | /research |
| order-tags | research | gate-1-research | empty | 0 files | /research |

BLOCKERS
- none

NEXT
1. discount-bundles — research not settled: /research discount-bundles
2. order-tags — research not settled: /research order-tags
```

Table rules:

- Stage comes from `apps/<slug>/status.md` first, registry second. If they
  disagree, print the status value and add a `DRIFT:` line under the table.
- `Prototype` column: `built` if `apps/<slug>/prototype/` has real files, else
  `empty`.
- `Pipeline` column: `<n> files / <age>` from the newest file under
  `production/apps/<slug>/session-state/`, else `—`.
- Never invent a stage. Unknown value → `unknown` and route to
  `/project-stage-detect <slug>`.
- Do not restate `request.md`; quote at most the goal sentence and the gates.

### Stage → next skill

| Stage | Meaning | Next skill |
|-------|---------|-----------|
| `research` | demand and API feasibility not settled | `/research <app>` → `/mmmvp-proposals <app>` → **user reviews slices** (advance only on pick/override; refine → `/update-request` + re-`/research` → re-run proposals) → `/gate-check gate-1-research <app>` |
| `prototype` | concept approved, prototype not built or not reviewed | `/scaffold <app>` → `/build-prototype <app>` → `/prototype-review <app>` → gate-2-prototype |
| `scope` | prototype approved, production scope not set | `/scope-check <app>`, `/create-epics <app>`, `/create-stories <app>` → gate-3-scope |
| `build` | stories exist, implementation in flight | `/sprint-plan <app>` or `/kanban-status <app>`, then `/dev-story` |
| `qa` | build done, verification outstanding | `/qa-plan <app>`, `/smoke-check <app>`, `/regression-suite <app>` |
| `release` | QA passed, store submission pending | `/app-store-checklist <app>`, `/deploy-to-test-store <app>`, `/release <app>` → gate-4-release |
| `update` | live app, changes flowing | `/update-request <app>` → `/propose-updates` → `/apply-updates` → gate-5-update |

Cross-cutting picks when the table does not fit: `/architecture-decision` for a
blocking technical choice, `/create-architecture` when an app has no
`docs/architecture/apps/<app>/architecture.md`, `/design-review` or `/ux-review`
before handing specs to implementation, `/gate-check` when a gate approval is
due, `/help` for the full command list.

### Empty state — no apps yet

This is a valid, common answer. Print a dashboard, not an error:

```text
=== Shopify App Pipeline — Dashboard ===
Master request: v1 (active) — <goal sentence>
Apps: none registered yet
Review mode: lean (default)

Nothing is in the pipeline. That is the expected starting state.

NEXT
1. /brainstorm open        — find a merchant pain worth an app
2. /research <slug>        — validate demand and API access for a known idea
3. /adopt                  — bring in an app that already exists
4. /help                   — every command, grouped by stage
```

Also state the bootstrap contract once, so the next session is not surprised:

- A new app is registered by appending one entry to `docs/registry/apps.json`
  (append-only — never rewrite or delete another app's entry).
- Its directory is `apps/<slug>/` with `status.md`, `approvals.json`,
  `README.md`, and `prototype/`; its pipeline directories are
  `production/apps/<slug>/{sprints,milestones,session-state}/`.
- Any change to `request.md` (for example the `## Apps in scope` table) needs a
  matching row in `request-history.md`; `.claude/hooks/track-request-changes.sh`
  enforces it.
### Empty state — no `request.md` yet

`request.md` missing (or its `## Goal` empty) is the real starting state — a
fresh repo, or between projects. `/start` is read-only on app state and never
writes `request.md` itself; it captures the idea and hands it to the skill that
owns it. Use `AskUserQuestion`:

> **What's the idea or request for this pipeline?**
> A one-sentence summary is enough. If there is nothing yet, say so and I'll
> route you to `/brainstorm open`.

Then route on the answer (do not print a dashboard until a goal exists):
- Idea supplied → `/update-request "<idea>"` (writes `request.md` v1 plus the
  matching `request-history.md` row; the `track-request-changes.sh` hook
  enforces the history row).
- "Nothing yet / brainstorm" → `/brainstorm open`.

This makes Phase 3's "ask what the pipeline should deliver" shorthand into a
real, single question asked before any dashboard is printed.

## Phase 3 — Route

Pick the next step from the table above, using these overrides:

1. **Request not approved / no `request.md`** → `/help` and ask what the
   pipeline should deliver. Do not route into an app until the master request
   exists.
2. **Registry drift** (entry without directory, or directory without entry) →
   fix the registry shape first: `/onboard` for a directory that is missing an
   entry, `/scaffold` for an entry that is missing a directory.
3. **Blocked app** (`Blockers:` in `status.md` is not `none`) → surface the
   blocker and the owner before any other step.
4. **Gate approved but stage not advanced** → the next stage's first skill, plus
   a reminder to update `apps/<app>/status.md` and the registry `stage`.
5. **New app request** → `/brainstorm` (ideation) or `/research` (a named idea
   already in hand).
6. **Stale session** (session-state older than 7 days) → say so; suggest
   `/project-stage-detect <app>` before resuming.

## Phase 4 — Set review mode

Check `production/review-mode.txt`.

- **Exists** → read it, print `Review mode: <value>`, continue. Never re-ask.
- **Missing** → use `AskUserQuestion`, `request_user_input`, or `clarify`:
  - Prompt: "How much review do you want as apps move through the gates?"
  - `Full` — director and specialist gates at every crafting step.
  - `Lean (recommended)` — directors only at gate transitions.
  - `Solo` — no director gates; fastest path.

Write `full`, `lean`, or `solo` immediately after the choice — the write is the
direct consequence of the selection, so no separate confirmation is needed.
Create `production/` if needed. Review mode semantics live in
`.claude/docs/director-gates.md`; per-run `--review full|lean|solo` overrides it.

## Phase 5 — Hermes model routing (`hermes` only)

Skipped entirely when `mode` is `claude` or `codex`.

Hermes resolves a subagent's model from the `delegation` section of the active
profile's `config.yaml`; `delegation.backend` picks the strategy:

| `delegation.backend` | Per-task parameter | Behaviour |
|----------------------|--------------------|-----------|
| `default` | none | Every child runs on `delegation.model` / `delegation.provider`, else the parent's model. |
| `model_map` | `option` | The agent picks a named model route per task, from the routes you define. |
| `profile_routes` | `profile` | The agent runs each child as one of your Hermes profiles. |

`model_map` and `profile_routes` come from the official `advanced-delegation`
plugin, which must be installed in the profile that delegates (plugins are per
profile; requires Hermes 0.22.5 or newer). Backend settings live under
`delegation.backends.<backend name>`, never beside the core `delegation` keys.
While either plugin mode is active, `delegation.model` / `delegation.provider`
are inactive. A selected backend that is missing or cannot run makes
`delegate_task` fail closed with an error naming the backend and the fix — it
never silently falls back to `default`.

Detect silently before asking:

- `command -v hermes` and `hermes --version`. If absent: "Hermes not detected.
  Model resolution will use the agent definitions' `model` fields directly."
  then continue to Phase 7. Older than 0.22.5 → treat both plugin modes as
  unavailable.
- `hermes profile list` — profiles and the model each runs.
- `HERMES_PROFILE=<profile> hermes config get delegation.backend`
- `HERMES_PROFILE=<profile> hermes plugins list` — is `advanced-delegation`
  installed and enabled?
- `HERMES_PROFILE=<profile> hermes delegation config --show` — current mode and
  routes.
- Tiers in use: `grep -h '^model:' .claude/agents/*.md | sort | uniq -c`. The
  frontmatter `model:` value *is* the shared tier label (`haiku`, `sonnet`,
  `opus`); keep that vocabulary.

If `production/hermes-profile-mapping.json` already exists: read it, say
"Hermes model routing is configured: strategy `[strategy]`, backend
`[backend]`, routes `[summary]`." and skip to Phase 7. A file without
`schemaVersion` is a legacy profile map (`{"agent-name": "profile-name"}`):
report it as the profile strategy and leave it alone.

Otherwise ask, via `AskUserQuestion` / `request_user_input` / `clarify`:

- Prompt: "How should Hermes choose the model for a subagent?"
- `Model routes (recommended)` — `delegation.backend: model_map`; one named
  route per tier, named after the tier in the agent definitions.
- `Profile routes` — `delegation.backend: profile_routes`; each child runs as
  one of your profiles.
- `One model for all subagents` — `delegation.backend: default` with
  `delegation.model`; no plugin required.
- `Skip for now` — configure later.

If a plugin mode was chosen and `advanced-delegation` is not in
`hermes plugins list`, say: "That mode needs the official `advanced-delegation`
plugin in the profile that delegates: `hermes plugins install
advanced-delegation`, then `hermes plugins enable advanced-delegation` if it
lands disabled. Nothing routes on it until the plugin is there — `delegate_task`
fails closed while it is missing." Write the config anyway.

### Delegation limits (ask in every branch that writes config)

Ask once, multi-select:

- `Nested orchestration` — `max_spawn_depth: 2`, so a director's subagent
  (spawned with `role="orchestrator"`) can spawn its own leads and specialists.
  At the default of 1, `role="orchestrator"` is a no-op.
- `Worktree isolation` — `worktree_isolation: true`; each child gets its own git
  worktree, so parallel implementers cannot collide on the same files.
- `Neither` — flat delegation in a shared workspace (default).

Warn before enabling nested orchestration: each level multiplies spend, and a
depth-2 tree at `max_concurrent_children` 10 can reach 100 concurrent children.
Never raise `max_concurrent_children` here unless asked.

### Model routes branch

Ask once per tier found in detection:

- Prompt: "What should the `<tier>` route use? (`<count>` agent roles carry this tier)"
- `Pin a provider and model` — ask for both. Never invent a model id: reuse one
  from `hermes profile list` or ask.
- `Skip this route` — leave it out.
- `Rename it` — must match `^[A-Za-z0-9][A-Za-z0-9_.-]{0,63}$`.

Then ask which tier is the default route, offering the tier with the most agents
first. Explain that a task picking no option falls back to `default`, and that
with no default an unrouted task runs on the main agent's model.

Write `production/hermes-delegation.yaml`:

```yaml
# Paste into ~/.hermes/profiles/<profile>/config.yaml, or run
# `hermes delegation config` and edit the routes there instead.
delegation:
  backend: model_map
  backends:
    model_map:
      options:
        - name: haiku
          description: "Quick reads and formatting: status checks, lookups, short summaries."
          provider: <provider>
          model: <model>
        - name: sonnet
          description: "Default pipeline work: feature specs, implementation, spec review."
          provider: <provider>
          model: <model>
        - name: opus
          description: "Hard synthesis: multi-document analysis, architecture review, gate decisions."
          provider: <provider>
          model: <model>
          reasoning_effort: high
      default: sonnet
  # max_spawn_depth: 2          # only when nested orchestration was selected
  # worktree_isolation: true    # only when worktree isolation was selected
```

Only route names and descriptions reach the model — never the provider, model id
or key. `reasoning_effort` and `service_tier` are optional per route; a
`service_tier` the route does not offer refuses that task rather than running it
anyway.

State the honest limitation: in `model_map` mode the agent picks the route per
task, so the `model:` tier in agent frontmatter is guidance carried by the route
descriptions plus the `default` route — it is not enforced.

### Profile routes branch

- Ask which profiles to list (multi-select from `hermes profile list`), and for
  each a one-line description of what it should serve, suggesting the pipeline
  roles that fit it (directors, leads, specialists, Shopify platform
  specialists).
- Ask for the default profile, or `No default`.

```yaml
delegation:
  backend: profile_routes
  backends:
    profile_routes:
      profiles:
        - name: <profile>
          description: "Producer and director work: gate decisions, review, scheduling."
      # default: <profile>
  # max_spawn_depth: 2
  # worktree_isolation: true
```

Say explicitly: "Listing a profile lets this profile's subagents use that
profile's credentials, credential pool, `SOUL.md` and terminal policy. Only list
profiles whose keys and terminal access you are happy to share."

### Single-model branch

- Ask for the provider and model, or `Inherit the parent's model`.
- Write `production/hermes-delegation.yaml` with `backend: default` and, unless
  inheriting, `model:` / `provider:`. Keep `delegation.backend` explicit only
  when the profile had another mode set.

### Routing record (all branches that write config)

Write `production/hermes-profile-mapping.json`:

```json
{
  "schemaVersion": 2,
  "harness": "hermes",
  "profile": "<active profile>",
  "delegation": {
    "strategy": "model_map",
    "backend": "model_map",
    "parameter": "option",
    "routes": {
      "haiku": {"provider": "<provider>", "model": "<model>"},
      "sonnet": {"provider": "<provider>", "model": "<model>", "default": true},
      "opus": {"provider": "<provider>", "model": "<model>", "reasoning_effort": "high"}
    }
  },
  "roles": {
    "<agent-name>": {"tier": "<tier>"}
  }
}
```

Use `"strategy": "profile_routes"` with `"parameter": "profile"` and
`{"profile": "<name>"}` routes in the profile branch; `"strategy": "default"`
with no routes in the single-model branch. Record every agent from
`.claude/agents/*.md` in `roles` from its frontmatter `model:` value, so a later
frontmatter edit shows up as a diff instead of silently changing intent.

Say: "Wrote `production/hermes-delegation.yaml` and
`production/hermes-profile-mapping.json`. Either paste the YAML into
`~/.hermes/profiles/<profile>/config.yaml`, or run `hermes delegation config` and
edit the routes there. Route changes apply to new sessions; in a running chat
`/delegation model_map --now` saves the mode and rebuilds that chat's tools (one
prompt-cache break), while `/delegation model_map` alone saves it for the next
session."

### Skip branch

Say: "You can configure Hermes model routing anytime with `/start hermes`,
`hermes delegation config`, or by editing the `delegation` section of
`~/.hermes/profiles/<name>/config.yaml`." Continue to Phase 7.

## Phase 6 — Codex model setup (`codex` only)

Skipped when `mode` is `claude` or `hermes`.

1. `command -v codex`. If missing: "Codex CLI not detected. Install it from
   https://developers.openai.com/codex/cli, then run `/start codex` again to
   configure model selection." Continue so the files can still be reviewed.
2. Read `.codex/config.toml`. Missing → "No project-local Codex configuration
   was found. Add `.codex/config.toml` or continue with your existing Codex user
   configuration."
3. Read `.codex/agent-models.toml`. Missing → "No Codex agent model map was
   found. Add `.codex/agent-models.toml` before spawning pipeline agents so their
   model tiers resolve explicitly."
4. Show the shared tier mapping used by `.claude/agents/*.md`:

| Shared tier | Codex model |
|-------------|-------------|
| Haiku | `gpt-6-luna` |
| Sonnet | `gpt-6.1-terra` |
| Opus | `gpt-6.1-sol` |

5. Ask: "Which Codex model tier would you like to use for this session?"
   - `Fast` — `gpt-6-luna` for status checks and simple lookups.
   - `Standard (recommended)` — `gpt-6.1-terra` for implementation and design work.
   - `Deep` — `gpt-6.1-sol` for multi-document synthesis and gate decisions.
   - `Keep current setting` — leave the active Codex model unchanged.
6. Echo the chosen model. Never change the user's global Codex configuration.

### Codex agent spawn rule

When Codex creates a pipeline subagent it must: read `.claude/agents/<agent>.md`;
read the frontmatter `model:` (omitted means `sonnet`); resolve that tier through
`.codex/agent-models.toml`; pass the resolved model explicitly on the child
request. Example: `producer`, `product-director` and `technical-director` declare
`model: opus`, so Codex must spawn them with `gpt-6.1-sol` — the project-wide
Sonnet default must not silently replace that. The mapping never replaces the
agent or skill instructions: read and follow those as part of the same spawn.

## Phase 7 — Confirm and hand off

Use `AskUserQuestion`, `request_user_input`, or `clarify`:

- Prompt: "Start with [recommended first step]?"
- `Yes, start with [first step]`
- `Something else first`

Never auto-run the next skill. On confirmation, answer in one line: "Type
`[skill command]` to begin." Nothing else.

Verdict: **COMPLETE** — dashboard printed, state read honestly, next step chosen
by the user.

## Edge cases

- **Registry unreadable (invalid JSON)**: print the dashboard without the app
  table, name the parse error verbatim, and say the registry must be fixed before
  routing. Do not rewrite it.
- **Registry lists an app with no directory**: show it as `missing dir` and route
  to `/scaffold` only after the user confirms the app is real.
- **Directory exists but is not registered**: show it as `unregistered` and offer
  `/onboard`.
- **Stage disagrees with approvals** (for example `stage: build` but no approved
  gate-3-scope): print both and route to `/gate-check <app>`.
- **Many apps**: group by stage instead of one flat table once there are more
  than 8.
- **User asks a question instead of routing**: answer it, then re-print just the
  `NEXT` block.
- **User wants to start over**: `/start` does not reset anything; point at
  `/help` and `request-history.md`.

## Collaborative protocol

1. **Read before telling** — the dashboard is built from files, never from
   memory of a previous session.
2. **Empty is fine** — a pipeline with no apps is a starting state, not an error.
3. **One recommendation** — offer the single best next step, not a menu of eight.
4. **User decides** — recommend, never auto-run.
5. **No silent writes** — the only writes are the review-mode file and the
   model-routing files.
