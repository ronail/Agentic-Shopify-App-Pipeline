---
name: start
description: "First-time onboarding — asks where you are, then guides you to the right workflow. No assumptions."
argument-hint: "[claude|codex|hermes]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion, request_user_input, Bash, clarify
model: sonnet
---

# Guided Onboarding

This skill writes one file: `production/review-mode.txt` (review mode config set in Phase 3b).

This skill is the entry point for new users. It does NOT assume you have a game idea, an engine preference, or any prior experience. It asks first, then routes you to the right workflow.

**Optional argument**: `/start [claude|codex|hermes]`

- Omitting the argument defaults to `claude` mode
- `/start codex` — reviews the project-local Codex model setup (Phase 3e)
- `/start hermes` — configures Hermes model routing for subagents (Phase 3d)
- `/start claude` (explicit) — standard Claude Code mode without Hermes routing

---

## Phase 1: Detect Project State

Before asking anything, silently gather context so you can tailor your guidance. Do NOT show these results unprompted — they inform your recommendations, not the conversation opener.

Check:
- **Engine configured?** Read `.claude/docs/technical-preferences.md`. If the Engine field contains `[TO BE CONFIGURED]`, the engine is not set.
- **Game concept exists?** Check for `design/gdd/game-concept.md`.
- **Source code exists?** Glob for source files in `src/` (`*.gd`, `*.cs`, `*.cpp`, `*.h`, `*.rs`, `*.py`, `*.js`, `*.ts`).
- **Prototypes exist?** Check for subdirectories in `prototypes/`.
- **Design docs exist?** Count markdown files in `design/gdd/`.
- **Production artifacts?** Check for files in `production/sprints/` or `production/milestones/`.

Store these findings internally to validate the user's self-assessment and tailor recommendations.

---

## Phase 2: Ask Where the User Is

This is the first thing the user sees. Use `AskUserQuestion`, `request_user_input` or `clarify` with these exact options so the user can click rather than type:

- **Prompt**: "Welcome to Agent Harness Game Studios! Before I suggest anything, I'd like to understand where you're starting from. Where are you at with your game idea right now?"
- **Options**:
  - `A) No idea yet` — I don't have a game concept at all. I want to explore and figure out what to make.
  - `B) Vague idea` — I have a rough theme, feeling, or genre in mind (e.g., "something with space" or "a cozy farming game") but nothing concrete.
  - `C) Clear concept` — I know the core idea — genre, basic mechanics, maybe a pitch sentence — but haven't formalized it into documents yet.
  - `D) Existing work` — I already have design docs, prototypes, code, or significant planning done. I want to organize or continue the work.

Wait for the user's selection. Do not proceed until they respond.

---

## Phase 3: Route Based on Answer

#### If A: No idea yet

The user needs creative exploration before anything else.

1. Acknowledge that starting from zero is completely fine
2. Briefly explain what `/brainstorm` does (guided ideation using professional frameworks — MDA, player psychology, verb-first design). Mention that it has two modes: `/brainstorm open` for fully open exploration, or `/brainstorm [hint]` if they have even a vague theme (e.g., "space", "cozy", "horror").
3. Recommend running `/brainstorm open` as the next step, but invite them to use a hint if something comes to mind
4. Show the recommended path:
   **Concept phase:**
   - `/brainstorm open` — discover your game concept
   - `/setup-engine` — configure the engine (brainstorm will recommend one)
   - `/prototype` — throwaway concept build: validate the core idea is fun before designing (1–3 days)
   - `/art-bible` — define visual identity (uses the Visual Identity Anchor brainstorm produces)
   - `/map-systems` — decompose the concept into systems
   - `/design-system` — author a GDD for each MVP system
   - `/review-all-gdds` — cross-system consistency check
   - `/gate-check` — validate readiness before architecture work
   **Architecture phase:**
   - `/create-architecture` — produce the master architecture blueprint and Required ADR list
   - `/architecture-decision (×N)` — record key technical decisions, following the Required ADR list
   - `/create-control-manifest` — compile decisions into an actionable rules sheet
   - `/architecture-review` — validate architecture coverage
   **Pre-Production phase:**
   - `/ux-design` — author UX specs for key screens (main menu, HUD, core interactions)
   - `/vertical-slice` — production-quality end-to-end build to validate the full game loop
   - `/playtest-report (×1+)` — document each vertical slice playtest session
   - `/create-epics` — map systems to epics
   - `/create-stories` — break epics into implementable stories
   - `/sprint-plan` — plan the first sprint
   **Production phase:** → pick up stories with `/dev-story`

#### If B: Vague idea

1. Ask them to share their vague idea — even a few words is enough
2. Validate the idea as a starting point (don't judge or redirect)
3. Recommend running `/brainstorm [their hint]` to develop it
4. Show the recommended path:
   **Concept phase:**
   - `/brainstorm [hint]` — develop the idea into a full concept
   - `/setup-engine` — configure the engine
   - `/prototype` — throwaway concept build: validate the core idea is fun before designing (1–3 days)
   - `/art-bible` — define visual identity (uses the Visual Identity Anchor brainstorm produces)
   - `/map-systems` — decompose the concept into systems
   - `/design-system` — author a GDD for each MVP system
   - `/review-all-gdds` — cross-system consistency check
   - `/gate-check` — validate readiness before architecture work
   **Architecture phase:**
   - `/create-architecture` — produce the master architecture blueprint and Required ADR list
   - `/architecture-decision (×N)` — record key technical decisions, following the Required ADR list
   - `/create-control-manifest` — compile decisions into an actionable rules sheet
   - `/architecture-review` — validate architecture coverage
   **Pre-Production phase:**
   - `/ux-design` — author UX specs for key screens (main menu, HUD, core interactions)
   - `/vertical-slice` — production-quality end-to-end build to validate the full game loop
   - `/playtest-report (×1+)` — document each vertical slice playtest session
   - `/create-epics` — map systems to epics
   - `/create-stories` — break epics into implementable stories
   - `/sprint-plan` — plan the first sprint
   **Production phase:** → pick up stories with `/dev-story`

#### If C: Clear concept

1. Ask them to describe their concept in one sentence — genre and core mechanic. Use plain text, not AskUserQuestion (it's an open response).
2. Acknowledge the concept, then use `AskUserQuestion`, `request_user_input` or `clarify` to offer two paths:
   - **Prompt**: "How would you like to proceed?"
   - **Options**:
     - `Formalize it first` — Run `/brainstorm [concept]` to structure it into a proper game concept document
     - `Jump straight in` — Go to `/setup-engine` now and write the GDD manually afterward
3. Show the recommended path:
   **Concept phase:**
   - `/brainstorm` or `/setup-engine` — (their pick from step 2)
   - `/prototype` — throwaway concept build: validate the core idea is fun before designing (1–3 days)
   - `/art-bible` — define visual identity (after brainstorm if run, or after concept doc exists)
   - `/design-review` — validate the concept doc
   - `/map-systems` — decompose the concept into individual systems
   - `/design-system` — author a GDD for each MVP system
   - `/review-all-gdds` — cross-system consistency check
   - `/gate-check` — validate readiness before architecture work
   **Architecture phase:**
   - `/create-architecture` — produce the master architecture blueprint and Required ADR list
   - `/architecture-decision (×N)` — record key technical decisions, following the Required ADR list
   - `/create-control-manifest` — compile decisions into an actionable rules sheet
   - `/architecture-review` — validate architecture coverage
   **Pre-Production phase:**
   - `/ux-design` — author UX specs for key screens (main menu, HUD, core interactions)
   - `/vertical-slice` — production-quality end-to-end build to validate the full game loop
   - `/playtest-report (×1+)` — document each vertical slice playtest session
   - `/create-epics` — map systems to epics
   - `/create-stories` — break epics into implementable stories
   - `/sprint-plan` — plan the first sprint
   **Production phase:** → pick up stories with `/dev-story`

#### If D: Existing work

1. Share what you found in Phase 1:
   - "I can see you have [X source files / Y design docs / Z prototypes]..."
   - "Your engine is [configured as X / not yet configured]..."

2. **Sub-case D1 — Early stage** (engine not configured or only a game concept exists):
   - Recommend `/setup-engine` first if engine not configured
   - Then `/project-stage-detect` for a gap inventory

   **Sub-case D2 — GDDs, ADRs, or stories already exist:**
   - Explain: "Having files isn't the same as the template's skills being able to use them. GDDs might be missing required sections. `/adopt` checks this specifically."
   - Recommend:
     1. `/project-stage-detect` — understand what phase and what's missing entirely
     2. `/adopt` — audit whether existing artifacts are in the right internal format

3. Show the recommended path for D2:
   - `/project-stage-detect` — phase detection + existence gaps
   - `/adopt` — format compliance audit + migration plan
   - `/setup-engine` — if engine not configured
   - `/design-system retrofit [path]` — fill missing GDD sections
   - `/architecture-decision retrofit [path]` — add missing ADR sections
   - `/architecture-review` — bootstrap the TR requirement registry
   - `/gate-check` — validate readiness for next phase

---

## Phase 3c: Write Initial Stage File

After confirming the starting path (and before asking about review mode), write the initial stage to `production/stage.txt`. Create the `production/` directory if it does not exist.

Stage mapping:
- **Path A, B, or C (starting from scratch)**: write `Concept`
- **Path D, existing project, engine not configured or only a game concept exists**: write `Concept`
- **Path D, existing project with GDDs but no architecture documents**: write `Systems Design`
- **Path D, existing project with full architecture (ADRs, architecture doc)**: write `Technical Setup`

Do this silently — no "May I write?" needed for this single-line file.

Say: "I've set `production/stage.txt` to `[stage]` — this anchors your status line and stage detection."

---

## Phase 3d: Configure Hermes Model Routing for Agent Roles

**Only applicable when the `hermes` argument is provided.** This phase is
skipped if the argument is omitted or if `claude` is explicitly provided.

Hermes resolves a subagent's model from the `delegation` section of the active
profile's `config.yaml`, and `delegation.backend` picks the strategy:

| `delegation.backend` | Per-task parameter | Behaviour |
|----------------------|--------------------|-----------|
| `default` | none | Every child runs on `delegation.model` / `delegation.provider`, else the parent's model. |
| `model_map` | `option` | The agent picks a named model route per task, from the routes you define. |
| `profile_routes` | `profile` | The agent runs each child as one of your Hermes profiles. |

`model_map` and `profile_routes` come from the official `advanced-delegation`
plugin, which must be installed in the profile that delegates (plugins are per
profile; it needs Hermes 0.22.5 or newer). Backend settings live under
`delegation.backends.<backend name>`, never beside the core `delegation` keys.
While either plugin mode is active, `delegation.model` / `delegation.provider`
are inactive. A selected backend that is missing or cannot run makes
`delegate_task` fail closed with an error naming the backend and the fix — it
never silently falls back to `default`.

Detect this silently before asking anything:

- `command -v hermes` and `hermes --version`. If Hermes is absent, say: "Hermes
  not detected. Model resolution will use the agent definitions' `model` fields
  directly." and continue to Phase 3b. If it is older than 0.22.5, say so and
  treat both plugin modes as unavailable.
- `hermes profile list` — profiles and the model each one runs.
- `HERMES_PROFILE=<profile> hermes config get delegation.backend` — the active
  backend (`default` when unset).
- `HERMES_PROFILE=<profile> hermes plugins list` — whether
  `advanced-delegation` is installed in that profile, and whether it is enabled.
- `HERMES_PROFILE=<profile> hermes delegation config --show` — the current mode
  and its routes, when the plugin is installed.
- Tiers in use: `grep -h '^model:' .claude/agents/*.md | sort | uniq -c`. The
  frontmatter `model:` value *is* the shared tier label (`haiku`, `sonnet`,
  `opus`) — keep that vocabulary rather than inventing a second one.

**If the argument is omitted or `claude` is provided** (Claude mode): Proceed
directly to Phase 3b without detection. Model resolution uses the agent
definitions' `model` fields directly. If `codex` is provided, skip this phase
and continue to Phase 3e.

Check if `production/hermes-profile-mapping.json` already exists.

**If it exists**: Read it and say: "Hermes model routing is configured: strategy
`[strategy]`, backend `[backend]`, routes `[route summary]`." — then proceed to
Phase 3b. Do not ask again. A file with no `schemaVersion` key is a legacy
profile mapping (`{"agent-name": "profile-name"}`): report it as the profile
strategy and leave it unchanged.

**If it does not exist** and the `hermes` argument was provided, use
`AskUserQuestion`, `request_user_input` or `clarify`:

- **Prompt**: "How should Hermes choose the model for a subagent?"
- **Options**:
  - `Model routes (recommended)` — `delegation.backend: model_map`: the agent
    picks a named model route per task, named after the tier in each agent
    definition.
  - `Profile routes` — `delegation.backend: profile_routes`: the agent runs each
    subagent as one of your Hermes profiles.
  - `One model for all subagents` — `delegation.backend: default` with
    `delegation.model`; no plugin required.
  - `Skip for now` — I'll configure this later.

Create the `production/` directory if it does not exist.

If a plugin mode was chosen and `advanced-delegation` is missing from
`hermes plugins list`, say: "That mode needs the official `advanced-delegation`
plugin, installed in the profile that delegates: `hermes plugins install
advanced-delegation`, then `hermes plugins enable advanced-delegation` if it
lands disabled. Nothing routes on it until the plugin is there — `delegate_task`
fails closed while it is missing." Continue anyway; the config is written and
takes effect once the plugin is installed.

### Studio delegation limits (ask in every branch that writes config)

Ask once, before writing the file — multi-select:

- **Prompt**: "Two delegation limits matter for a studio hierarchy. Which should
  I set?"
- **Options**:
  - `Nested orchestration` — `max_spawn_depth: 2`, so a director's subagent
    (spawned with `role="orchestrator"`) can spawn its own leads and
    specialists. At the default of 1, `role="orchestrator"` is a no-op.
  - `Worktree isolation` — `worktree_isolation: true`: each child gets its own
    git worktree, so parallel implementers cannot collide on the same files.
  - `Neither` — Keep flat delegation in a shared workspace (the default).

Warn before enabling nested orchestration: each level multiplies spend, and a
depth-2 tree at `max_concurrent_children` 10 can reach 100 concurrent children.
Never raise `max_concurrent_children` from this workflow without being asked.

### If "Model routes":

Ask once per tier found in the detection step:

- **Prompt**: "What should the `<tier>` route use? (`<count>` agent roles carry
  this tier)"
- **Options**:
  - `Pin a provider and model` — ask for the provider and the model id. Never
    invent a model id: reuse one from `hermes profile list` or ask.
  - `Skip this route` — leave it out of the table.
  - `Rename it` — the route name is what the agent picks on. It must match
    `^[A-Za-z0-9][A-Za-z0-9_.-]{0,63}$`.

Then ask which tier should be the default route, offering the tier with the most
agents first. Explain that a task which picks no option falls back to `default`,
and that with no default set an unrouted task runs on the main agent's model.

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
          description: "Default studio work: implementation, design documents, code review."
          provider: <provider>
          model: <model>
        - name: opus
          description: "Hard synthesis: multi-document analysis, architecture review, phase gates."
          provider: <provider>
          model: <model>
          reasoning_effort: high
      default: sonnet
  # max_spawn_depth: 2          # only when nested orchestration was selected
  # worktree_isolation: true    # only when worktree isolation was selected
```

Write route descriptions the agent can choose on: only the names and
descriptions reach the model, never the provider, model id or key.
`reasoning_effort` and `service_tier` are optional per route; a `service_tier`
the route does not offer refuses that task rather than running it anyway.

Then state the honest limitation: in `model_map` mode the agent chooses the
route per task, so the `model:` tier in agent frontmatter is guidance carried by
the route descriptions plus the `default` route — it is not enforced.

### If "Profile routes":

- Ask which profiles to list — multi-select from `hermes profile list` — and for
  each one a single line about what it should serve, suggesting the studio roles
  that fit it (directors, leads, specialists, engine specialists).
- Ask for the default profile, or `No default`.

Write `production/hermes-delegation.yaml`:

```yaml
delegation:
  backend: profile_routes
  backends:
    profile_routes:
      profiles:
        - name: <profile>
          description: "Producer and director work: phase gates, review, scheduling."
      # default: <profile>
  # max_spawn_depth: 2          # only when nested orchestration was selected
  # worktree_isolation: true    # only when worktree isolation was selected
```

Say explicitly: "Listing a profile lets this profile's subagents use that
profile's credentials, credential pool, `SOUL.md` and terminal policy. Only list
profiles whose keys and terminal access you are happy to share."

### If "One model for all subagents":

- Ask for the provider and model, or `Inherit the parent's model`.
- Write `production/hermes-delegation.yaml` with `backend: default` and, unless
  inheriting, `model:` / `provider:`. Keep `delegation.backend` explicit only
  when the profile had another mode set; otherwise omit it and leave the
  strategy note in the JSON.

### Write the routing record

In every branch that writes config, write
`production/hermes-profile-mapping.json`:

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
`{"profile": "<name>"}` routes in the profile branch, and `"strategy": "default"`
with no routes in the single-model branch. Record every agent from
`.claude/agents/*.md` in `roles` from its frontmatter `model:` value instead of
leaving the mapping implicit, so a later frontmatter edit surfaces as a diff
rather than silently changing intent.

Say: "Wrote `production/hermes-delegation.yaml` and
`production/hermes-profile-mapping.json`. Either paste the YAML into
`~/.hermes/profiles/<profile>/config.yaml`, or run `hermes delegation config` and
edit the routes there. Route changes apply to new sessions; in a running chat
`/delegation model_map --now` saves the mode and rebuilds that chat's tools (one
prompt-cache break), while `/delegation model_map` alone saves it for the next
session."

### If "Skip for now":

- Say: "You can configure Hermes model routing anytime by running
  `/start hermes` again, by running `hermes delegation config`, or by editing
  the `delegation` section of `~/.hermes/profiles/<name>/config.yaml`."
- Proceed to Phase 3b.

---

## Phase 3e: Configure Codex Model Setup

**Only applicable when the `codex` argument is provided.** This phase is
skipped if the argument is omitted or if `claude` or `hermes` is explicitly
provided.

Use `Bash` to check whether the Codex CLI is installed (`command -v codex`). If
it is not installed, say: "Codex CLI not detected. Install it from
https://developers.openai.com/codex/cli, then run `/start codex` again to
configure model selection." Continue to the configuration check so the user
can still review the project files.

Read `.codex/config.toml` and confirm that the project-local Codex
configuration exists. If it is missing, say:
"No project-local Codex configuration was found. Add `.codex/config.toml` or
continue with your existing Codex user configuration."

Read `.codex/agent-models.toml` as well. This file is required for spawning
studio agents because `.codex/config.toml` contains only the project-wide
fallback model. If it is missing, say:
"No Codex agent model map was found. Add `.codex/agent-models.toml` before
spawning studio agents so their model tiers resolve explicitly."

If the file exists, explain the shared model-tier mapping and the corresponding
Codex model:

| Shared tier | Codex model |
|-------------|-------------|
| Haiku | `gpt-6-luna` |
| Sonnet | `gpt-6.1-terra` |
| Opus | `gpt-6.1-sol` |

The standard tier is the project default. Use `AskUserQuestion`, `request_user_input` or `clarify` to
ask:

- **Prompt**: "Which Codex model tier would you like to use for this session?"
- **Options**:
  - `Fast` — Use `gpt-6-luna` for quick status checks and simple lookups.
  - `Standard (recommended)` — Use `gpt-6.1-terra` for implementation and design work.
  - `Deep` — Use `gpt-6.1-sol` for multi-document synthesis and phase gates.
  - `Keep current setting` — Leave the active Codex model unchanged.

After the user selects a tier, show its corresponding model from the table
above. If they choose `Keep current setting`, say: "Your current Codex model
setting will remain active." Do not change the user's global Codex
configuration from this skill.

### Codex agent spawn rule

When Codex creates a game-studio subagent, it must:

1. Read the target definition in `.claude/agents/<agent-name>.md`.
2. Read its YAML frontmatter `model` field. Treat an omitted field as `sonnet`.
3. Resolve that tier through `.codex/agent-models.toml`.
4. Pass the resolved model explicitly on the subagent or child-task request.

For example, `producer`, `creative-director`, and `technical-director` use
`model: opus`, so Codex must spawn them with `gpt-6.1-sol`; the project-wide
Sonnet default must not silently replace that selection. The model mapping does
not replace the original agent or skill instructions: read and follow those
references as part of the same spawn.

---

## Phase 3b: Set Review Mode

Check if `production/review-mode.txt` already exists.

**If it exists**: Read it and show the current mode — "Review mode is set to `[current]`." — then proceed to Phase 4. Do not ask again.

**If it does not exist**: Use `AskUserQuestion`, `request_user_input` or `clarify`:

- **Prompt**: "One setup choice: how much design review would you want as you work through the workflow?"
- **Options**:
  - `Full` — Director specialists review at each key workflow step. Best for teams, learning the workflow, or when you want thorough feedback on every decision.
  - `Lean (recommended)` — Directors only at phase gate transitions (/gate-check). Skips per-skill reviews. Balanced approach for solo devs and small teams.
  - `Solo` — No director reviews at all. Maximum speed. Best for game jams, prototypes, or if the reviews feel like overhead.

Write the choice to `production/review-mode.txt` immediately after the user
selects — no separate "May I write?" needed, as the write is a direct
consequence of the selection:
- `Full` → write `full`
- `Lean (recommended)` → write `lean`
- `Solo` → write `solo`

Create the `production/` directory if it does not exist.

---

## Phase 4: Confirm Before Proceeding

After presenting the recommended path, use `AskUserQuestion`, `request_user_input` or `clarify` to ask the user which step they'd like to take first. Never auto-run the next skill.

- **Prompt**: "Would you like to start with [recommended first step]?"
- **Options**:
  - `Yes, let's start with [recommended first step]`
  - `I'd like to do something else first`

---

## Phase 5: Hand Off

When the user confirms their next step, respond with a single short line: "Type `[skill command]` to begin." Nothing else. Do not re-explain the skill or add encouragement. The `/start` skill's job is done.

Verdict: **COMPLETE** — user oriented and handed off to next step.

---

## Edge Cases

- **User picks D but project is empty**: Gently redirect — "It looks like the project is a fresh template with no artifacts yet. Would Path A or B be a better fit?"
- **User picks A but project has code**: Mention what you found — "I noticed there's already code in `src/`. Did you mean to pick D (existing work)?"
- **User is returning (engine configured, concept exists)**: Skip onboarding entirely — "It looks like you're already set up! Your engine is [X] and you have a game concept at `design/gdd/game-concept.md`. Review mode: `[read from production/review-mode.txt, or 'lean (default)' if missing]`. Want to pick up where you left off? Try `/sprint-plan` or just tell me what you'd like to work on."
- **User doesn't fit any option**: Let them describe their situation in their own words and adapt.

---

## Collaborative Protocol

1. **Ask first** — never assume the user's state or intent
2. **Present options** — give clear paths, not mandates
3. **User decides** — they pick the direction
4. **No auto-execution** — recommend the next skill, don't run it without asking
5. **Adapt** — if the user's situation doesn't fit a template, listen and adjust