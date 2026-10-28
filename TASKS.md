# Agentic Shopify App Pipeline – Task List

## Goal

Automatic pipeline driven by **one single master request** (updatable + fully tracked).

From that one request the system can generate and run **multiple Shopify apps** in parallel through the full lifecycle.

**Flow:**

1. Master request recorded (can be updated later, all changes tracked)
2. Research (Original idea **or** Competitor killer) against current master request
3. Ranked MMMVP proposals → User selects which become apps
4. For each selected app:
   - Build prototype → User reviews / refines
   - Production goals defined
   - Full SDLC (Epics + Stories) in concurrent Kanban
   - Create Shopify Test Store → User tests
   - User approves → Actual release
5. Ongoing loop: re-research against current master request → propose updates → update app(s) + test store(s) → user approves

---

## Acceptance Criteria

### Master Request
- [ ] Exactly one master request
- [ ] Can be updated at any time
- [ ] Every update is tracked with history
- [ ] All research/update loops use the current version

### Multi-app from One Request
- [ ] One master request can produce multiple apps
- [ ] Apps run in parallel with isolated state
- [ ] `/start` shows master request + all apps and their stages

### Pipeline
- [ ] Research supports Original + Competitor Killer
- [ ] Ranked MMMVP proposals
- [ ] Prototype + user review
- [ ] Epics + Stories + concurrent Kanban
- [ ] Test store per app
- [ ] Release only after explicit user approval
- [ ] Ongoing update loop works
- [ ] Human approval gates enforced per app

---

## Workflow Guideline

```
Master Request (request.md + history)
        ↓
Research (Original | Competitor Killer)
        ↓
MMMVP Proposals → User selects apps
        ↓
┌─────────────────────────────┐
│  For each selected app:     │
│  Prototype → Review         │
│  → Production Goals         │
│  → Epics + Stories (Kanban) │
│  → Test Store               │
│  → User Approval → Release  │
└─────────────────────────────┘
        ↓
Ongoing: Update master request or re-research → Propose updates → Apply (with approval)
```

---

## Phase 0 – Master Request & Foundation

- [ ] `request.md` (current master request)
- [ ] `request-history.md` (full tracked changelog)
- [ ] `apps/<app-name>/` structure
- [ ] Per-app: `status.md`
- [ ] App registry / dashboard data
- [ ] `/update-request` skill (mandatory reason + auto-track)

---

## Phase 1 – Research & MMMVP

> **Nothing in Phases 0–5 is implemented.** The harness that once satisfied some of these boxes was
> replaced by the AHGS import at `fec6e35`, so the agents and skills named here either no longer exist or
> survive only in game form. Every box starts unchecked; the R0–R10 checklist below is authoritative for
> what "done" means.

**Agents**
- [ ] `product-director`
- [ ] `research-specialist`

**Skills**
- [ ] `/start` (dashboard: master request + all apps)
- [ ] `/research`
- [ ] `/mmmvp-proposals`
- [ ] `/update-request`

---

## Phase 2 – Prototype

**Agents**
- [ ] `prototype-builder`

**Skills**
- [ ] `/scaffold --app <name>`
- [ ] `/build-prototype --app <name>`
- [ ] `/prototype-review --app <name>`

---

## Phase 3 – SDLC (Concurrent Kanban)

**Agents**
- [ ] `technical-director`
- [ ] `app-architect`

**Skills**
- [ ] `/create-epics --app <name>`
- [ ] `/create-stories --app <name>`
- [ ] `/dev-story --app <name>`
- [ ] `/kanban-status` (one app or `--all`)

---

## Phase 4 – Quality & Release

**Agents**
- [ ] `security-specialist`
- [ ] `app-store-reviewer`
- [ ] `release-manager`
- [ ] `test-store-manager`

**Skills**
- [ ] `/security-audit --app <name>`
- [ ] `/app-store-checklist --app <name>`
- [ ] `/create-test-store --app <name>`
- [ ] `/deploy-to-test-store --app <name>`
- [ ] `/release --app <name>`

---

## Phase 5 – Ongoing Update Loop

**Skills**
- [ ] `/update-research` (against current master request)
- [ ] `/propose-updates`
- [ ] `/apply-updates --app <name>`

---

## Hooks (Minimal)

| Hook | Purpose | Status |
|------|---------|--------|
| `session-start.sh` | Show master request + all apps & stages | ☐ |
| `track-request-changes.sh` | Enforce tracking on master request updates | ☐ |
| `app-store-gate.sh` | Block release if checklist fails | ☐ |

---

## Human Approval Gates (per app)

1. MMMVP selection (which become apps)
2. Prototype → Production
3. Scope confirmation before full SDLC
4. Test Store → Live Release
5. Any update proposal

---

## Removed / Deferred (Not needed for core pipeline)

- Low-level specialists (Liquid, Polaris, App Bridge, GraphQL, Webhooks, Billing, Auth, Performance)
- Extra skills (`/webhook-design`, `/billing-setup`, `/polaris-ui`, `/code-review`, `/hotfix`, etc.)
- Growth / UX leads
- Most validation hooks

These can be added later if needed.

> **Superseded by R2–R6 below — this whole section is void.** The imported framework already
> provides the machinery, so the Shopify API layer (Liquid, Polaris, App Bridge, GraphQL, Webhooks,
> Billing, Auth), the growth/UX leads, `/code-review`, `/hotfix` and the validation hooks are all
> back in scope. Where R2–R6 and this section disagree, R2–R6 win. Delete this section when R0 is
> ratified.

---

## Framework Refactor — Game Dev Harness → Shopify Pipeline

**Baseline:** harness imported at `fec6e35` is the AHGS *game* framework — 49 agents, 75 skills, 12 hooks, 11 rules, 37 templates, 18 reference docs. All domain content is still game/engine-oriented. This section is the checklist to convert it so the **Goal** and **Acceptance Criteria** above become achievable.

**Refactor rules**

- **Replace, don't extend.** Every item is delete → replace. Nothing game-domain survives "just in case".
- **One task = one commit** on `main`, conventional commit: `refactor(agents): ...`, `refactor(rules): ...`.
- **Machinery stays.** Hook plumbing, `statusline.sh`, `.codex/generate_compat.py`, `log-agent*.sh`, `pre/post-compact.sh`, `notify.sh` are domain-neutral — re-point them, don't rewrite from scratch.
- **Baseline metric:** 163 files currently match `godot|unity|unreal|gdextension|gds`. Whole-refactor definition of done: **0 outside `docs/legacy/`**.
- **Recovery:** previous Shopify harness is at `2e8c57e`; project intent preserved in `docs/legacy/CLAUDE.shopify-pipeline.md`.
- **Execution order ≠ numbering.** Run `R0 → R1 → R2 → R8 → R3 → R4 → R5 → R6 → R7 → R9 → R10`. R8 lands the `apps/<app-name>/` layout that R3's rule globs, R6's hooks and R4's `/start` all reference; the R-numbers stay fixed so links and commits remain stable.
- **Every phase ends in a gate a command can check**, not a judgement call.

---

### R0 — Ratify the target shape (decisions only)

Every decision lands in one new file, `docs/legacy/REFACTOR-DECISIONS.md`. No existing file is edited in this phase.

- [ ] Write that file with the baseline counts and the imported SHA (`fec6e35`)
- [ ] **Ratify** the R2 agent roster (49 → 31) and the R4 skill buckets (75 → 66) as the target. Anything rejected moves under an `# Open` heading in the same file and must be closed before R1 starts — R2/R4 execute the ratified table, they do not re-litigate it
- [ ] Decide the surviving top-level dirs: `src/`, `design/`, `production/`, `docs/` — and record that `assets/`, `prototypes/`, `tests/`, `tools/` stay absent (they were never imported)
- [ ] Decide the data home for per-app state: `apps/<app>/…` vs `production/apps/<app>/…` (feeds R8's isolation contract)
- [ ] Write `production/hermes-profile-mapping.json` (Hermes profile → agent-role resolution). Hermes parity is a hard gate in R10, so this is required, not optional
- [ ] Record attribution: this repo derives from `ronail/Agent-Harness-Game-Studios` (MIT), itself a fork of `Donchitos/Claude-Code-Game-Studios`; keep `LICENSE`, credit both in `README.md`

**Done when:** `docs/legacy/REFACTOR-DECISIONS.md` holds the ratified roster, the skill table, the directory decisions and the Hermes mapping, and is committed. **No other file changed in this phase.**

---

### R1 — Foundation config

- [ ] `CLAUDE.md` — drop the engine `[CHOOSE: ...]` lines, the engine-specialist note and `@docs/engine-reference/godot/VERSION.md`; keep the `@.claude/docs/*` import graph intact
- [ ] `CLAUDE.md` — restate the stack: TypeScript / React / Polaris / App Bridge / Shopify GraphQL Admin API / Node
- [ ] `AGENTS.md` — rebrand the studio name; keep the Codex tier-mapping table verbatim (it is role-agnostic)
- [ ] `.codex/config.toml` — replace the header comment ("Claude Code Game Studios" → this pipeline)
- [ ] `docs/CLAUDE.md` — replace **both** game blocks: the engine-reference section becomes a `docs/shopify-api-reference/` snapshot policy, and the GDD / `tr-registry.yaml` / `control-manifest.md` sections become their Shopify equivalents (ADR "App Requirements Addressed", per-app requirements registry, per-app control manifest)
- [ ] `src/CLAUDE.md` — replace the game source rules (or delete with `src/` per R0)
- [ ] `README.md` — rewrite (408 lines of game framing; keep the AHGS + Donchitos attribution and the MIT licence)
- [ ] `IDEA.md`, `CONTRIBUTING.md`, `SECURITY.md` — strip game framing
- [ ] `UPGRADING.md` — **delete**, do not edit. It is an 859-line upstream-merge guide whose recommended strategy is `git merge template/main` against AHGS, with per-release "delete these files" lists naming files R2/R4/R5 delete; following it resurrects the framework. Replace with `docs/legacy/DIVERGENCE.md`: this repo diverged permanently at `fec6e35`, no upstream merges, upstream fixes are cherry-picked by hand after being re-expressed for Shopify
- [ ] `.github/CODEOWNERS` — drop the stale `settings.json` line (real path is `.claude/settings.json`, already covered by `.claude/`) and re-point the owner at this repo's account; `.github/FUNDING.yml` — delete (funds the upstream author); keep `PULL_REQUEST_TEMPLATE.md` and `ISSUE_TEMPLATE/*` (framework-shaped, no game text)
- [ ] `.gitignore` — remove the Godot / Unity / Unreal and binary-asset blocks; keep the Claude, secret and build blocks
- [ ] `.claude/settings.json` — audit the permission allow/deny list (no engine tooling); keep the `.env` denies
- [ ] `.claude/docs/technical-preferences.md` — rewrite (engine → Shopify stack, hosting, DB, test runner)
- [ ] `.claude/docs/coding-standards.md` — rewrite (GDScript / C# → TypeScript / React)
- [ ] `.claude/docs/context-management.md` — keep the structure, swap the examples

**Done when:** `CLAUDE.md` loads with no dangling `@`-imports, no engine tech choice remains, and `grep -riE 'godot|unity|unreal' CLAUDE.md AGENTS.md README.md docs/CLAUDE.md src/CLAUDE.md` returns nothing.

---

### R2 — Agent roster (49 → 31)

**Delete — engine specialists (15).** `godot-specialist`, `godot-gdscript-specialist`, `godot-csharp-specialist`, `godot-shader-specialist`, `godot-gdextension-specialist`, `unity-specialist`, `unity-dots-specialist`, `unity-shader-specialist`, `unity-addressables-specialist`, `unity-ui-specialist`, `unreal-specialist`, `ue-gas-specialist`, `ue-blueprint-specialist`, `ue-replication-specialist`, `ue-umg-specialist`

**Delete — game-only roles (16).** `game-designer`, `gameplay-programmer`, `engine-programmer`, `level-designer`, `systems-designer`, `economy-designer`, `narrative-director`, `writer`, `world-builder`, `art-director`, `technical-artist`, `audio-director`, `sound-designer`, `ai-programmer`, `network-programmer`, `live-ops-designer` (live-service game role: seasons, battle pass, retention — no Shopify analogue; `growth-lead` + `release-manager` cover post-launch)

**Rewrite — 18 roles that survive with a new domain.**

| From | To | New domain |
|---|---|---|
| `creative-director` | `product-director` | vision, owner of the master request |
| `technical-director` | `technical-director` | architecture, tech debt, API version policy |
| `producer` | `producer` | pipeline, kanban, milestones, scope gates |
| `lead-programmer` | `lead-engineer` | implementation lead |
| `prototyper` | `prototype-builder` | throwaway merchant-facing prototypes |
| `ux-designer` | `ux-lead` | merchant experience in the embedded admin |
| `ui-programmer` | `polaris-specialist` | Polaris components, admin UX implementation |
| `qa-lead` | `qa-lead` | test strategy, quality gates |
| `qa-tester` | `qa-tester` | manual + regression passes on dev stores |
| `release-manager` | `release-manager` | App Store submission, versioning, release gates |
| `security-engineer` | `security-specialist` | OAuth, session tokens, data handling, audits |
| `devops-engineer` | `devops-engineer` | hosting, CI/CD, environments, deploy to dev store |
| `performance-analyst` | `performance-analyst` | admin load time, API/webhook latency, rate limits |
| `analytics-engineer` | `analytics-engineer` | install funnel, usage events, merchant metrics |
| `accessibility-specialist` | `accessibility-specialist` | admin UI accessibility, keyboard/screen-reader |
| `localization-lead` | `localization-lead` | storefront/extension i18n, market coverage |
| `community-manager` | `community-manager` | merchant support, App Store review responses, changelog comms |
| `tools-programmer` | `tools-engineer` | Shopify CLI, scripts, dev-store automation |

**Add — new Shopify roles (13).** `research-specialist` (idea + competitor research, Phase 1), `app-architect` (per-app architecture), `api-lead` (GraphQL/REST/webhooks ownership), `growth-lead` (monetization, onboarding, retention — consumed by Phase 5 `/propose-updates` and the `pricing-plan` / `merchant-onboarding` templates), `graphql-specialist`, `webhooks-specialist`, `billing-specialist`, `auth-specialist`, `app-bridge-specialist`, `liquid-specialist`, `checkout-specialist`, `app-store-reviewer`, `test-store-manager`

**Per-agent work (every surviving and new agent)**

- [ ] Frontmatter: `name`, `description`, and a `model` tier (`opus` / `sonnet` / `haiku`) that still reflects the role's weight
- [ ] Prompt body: remove engine / art / audio / narrative content and every game file path
- [ ] Keep the **Collaboration Protocol** section (question → options → decision → draft → approval)
- [ ] Point output paths at `apps/<app-name>/`, `docs/`, `production/` — never `src/game/`, `assets/`
- [ ] Record in `.claude/docs/agent-roster.md` (this phase owns that file) which rule and which skill invoke the agent. No agent ships without an owner — `ai-agent-engineer` was dropped for exactly this reason
- [ ] Regenerate the Codex layer: `python3 .codex/generate_compat.py`; delete stale `.codex/agents/*.toml`

**Done when:** `ls .claude/agents` = **31** files matching the roster above exactly, `.codex/agents` = 31, zero engine names remain, and every roster row has an owner recorded.

---

### R3 — Rules layer (11 → 13)

**Delete (5):** `engine-code.md`, `gameplay-code.md`, `shader-code.md`, `ai-code.md`, `narrative.md`

**Rewrite (6):** `ui-code.md` (→ Polaris / App Bridge), `network-code.md` (→ GraphQL / Webhooks), `data-files.md`, `design-docs.md`, `prototype-code.md`, `test-standards.md`

**Add (7):** `admin-embed-code.md`, `theme-extension-code.md`, `webhook-code.md`, `graphql-code.md`, `billing-code.md`, `auth-code.md`, `functions-code.md`

- [ ] Each rule's `paths:` frontmatter glob matches at least one file that exists on disk when the rule is written — run `find` against every glob and paste the command into the commit message. `apps/**` globs land after R8, so either write those rules after R8 or note the deferral in the commit
- [ ] `.claude/docs/rules-reference.md` lists every rule file, 1:1
- [ ] No rule contradicts `.claude/docs/coding-standards.md` or `technical-preferences.md`

**Done when:** `ls .claude/rules` = **13** files == the entries in `rules-reference.md`, and every glob has been resolved by a `find` you can re-run.

---

### R4 — Skills layer (75 → 66)

**Delete outright — game-only (23):** `setup-engine`, `godot-screenshot`, `balance-check`, `playtest-report`, `asset-spec`, `asset-audit`, `art-bible`, `map-systems`, `design-system`, `review-all-gdds`, `propagate-design-change`, `vertical-slice`, `content-audit`, `day-one-patch` (game-ship artifact — no pressing/submission cutoff exists for a Shopify app; `/hotfix` and `/release` cover it), `team-combat`, `team-narrative`, `team-audio`, `team-level`, `team-ui`, `team-qa`, `team-polish`, `team-release`, `team-live-ops`

**Rewrite — workflow survives, domain changes (31):** `start` (**first** — it routes everything), `brainstorm`, `quick-design`, `design-review`, `ux-design`, `ux-review`, `create-architecture`, `architecture-decision`, `architecture-review`, `create-control-manifest`, `release-checklist`, `launch-checklist`, `changelog`, `patch-notes`, `hotfix`, `qa-plan`, `soak-test`, `smoke-check`, `regression-suite`, `perf-profile`, `security-audit`, `consistency-check`, `project-stage-detect`, `onboard`, `localize`, `prototype`, `reverse-document`, `milestone-review`, `gate-check`, `scope-check`, `tech-debt`

**Keep as-is — domain-neutral (21):** `help`, `adopt`, `skill-test`, `skill-improve`, `create-epics`, `create-stories`, `dev-story`, `story-readiness`, `story-done`, `sprint-plan`, `sprint-status`, `estimate`, `retrospective`, `code-review`, `bug-report`, `bug-triage`, `feature-request`, `test-setup`, `test-helpers`, `test-evidence-review`, `test-flakiness`

**Add (14):** `research` (Original | Competitor Killer, consumes the current `request.md`), `scaffold --app <name>` (creates `apps/<app-name>/` — the only task that produces the layout R3's globs and R6's hooks need), `mmmvp-proposals`, `update-request`, `build-prototype`, `prototype-review`, `kanban-status`, `app-store-checklist`, `create-test-store`, `deploy-to-test-store`, `release`, `update-research`, `propose-updates`, `apply-updates`

- [ ] Rewrite `/start` before anything else and re-run it: dashboard = master request + every app + its stage, read from `docs/registry/apps.json`
- [ ] Each surviving skill: frontmatter `description` free of game terms; body paths updated
- [ ] `.claude/docs/skills-reference.md` — **this phase owns the file**: regenerate it from `docs/legacy/REFACTOR-DECISIONS.md` (R0 only records the decision)
- [ ] `.claude/docs/workflow-catalog.yaml` — `/help` resolves every `step` id to an existing skill directory (manual pass; record the command used)
- [ ] `.agents/skills` symlink still resolves (Codex discovery)

**Done when:** `ls -d .claude/skills/*/` = **66** directories == the entries in `skills-reference.md` == the set of skills referenced by surviving agents (no orphans either direction).

---

### R5 — Templates (37 → 35)

**Delete — game (14):** `game-concept`, `game-design-document`, `game-pillars`, `hud-design`, `level-design-document`, `narrative-character-sheet`, `faction-design`, `economy-model`, `difficulty-curve`, `art-bible`, `sound-bible`, `player-journey`, `systems-index`, `vertical-slice-report`

**Rewrite (23):** `pitch-document` (→ app pitch), `prototype-report`, `ux-spec`, `interaction-pattern-library`, `technical-design-document`, `architecture-decision-record`, `architecture-doc-from-code`, `architecture-traceability`, `test-plan`, `test-evidence`, `release-checklist-template`, `release-notes`, `changelog-template`, `incident-response`, `post-mortem`, `risk-register-entry`, `sprint-plan`, `milestone-definition`, `project-stage-report`, `concept-doc-from-prototype`, `design-doc-from-implementation`, `accessibility-requirements`, `skill-test-spec`

**Add (12):** `master-request`, `request-history`, `mmmvp-proposal`, `app-concept`, `app-prd`, `prototype-review`, `shopify-app-architecture`, `app-store-listing`, `test-store-plan`, `merchant-onboarding`, `pricing-plan`, `kanban-card`

- [ ] `.claude/docs/templates/collaborative-protocols/` is a **directory**, not one of the 37 templates: review each protocol doc in it for game examples and rewrite the affected ones — do not count it as a template
- [ ] No template keeps GDD / MDA / Bartle / engine concepts as required sections
- [ ] Every `.claude/docs/templates/...` path mentioned in a skill body resolves on disk (R10 automates this)

**Done when:** `.claude/docs/templates` = **35** `.md` files + `collaborative-protocols/`, and every template path referenced by a skill resolves.

---

### R6 — Hooks (12 → 15)

- [ ] `session-start.sh` — print the same dashboard `/start` renders, read from `docs/registry/apps.json`; do **not** duplicate `/start`'s logic
- [ ] `session-stop.sh` — repoint the accomplishment summary and session log at `apps/*/status.md` and `request-history.md` (it currently writes game session state)
- [ ] `detect-gaps.sh` — replace game gap detection with pipeline gaps (`request.md` vs `apps/*/status.md`, stalled apps, missing approvals)
- [ ] `validate-assets.sh` — repurpose (rename to `validate-skill-frontmatter.sh`) to check skill/agent frontmatter, or delete; it currently validates game assets
- [ ] `validate-commit.sh` — keep the semantics, drop the `src/game` / `assets` path rules
- [ ] `validate-push.sh`, `validate-skill-change.sh`, `log-agent.sh`, `log-agent-stop.sh`, `pre-compact.sh`, `post-compact.sh`, `notify.sh` — keep; verify no game paths survive
- [ ] Add `track-request-changes.sh` — enforce tracking when `request.md` is updated (append to `request-history.md`, reject an untracked edit)
- [ ] Add `approval-gate.sh` — read `apps/<app>/approvals.json`; block `/release`, `/apply-updates` and phase transitions unless the required gate id is recorded with timestamp and approver
- [ ] Add `app-store-gate.sh` — block release when the App Store checklist fails
- [ ] Wire every hook in `.claude/settings.json` **and** `.codex/hooks.json`, and register the same set in the Hermes profile's hook config
- [ ] `bash -n` every hook; hooks still exit gracefully when `jq` / `python3` are missing

**Done when:** `ls .claude/hooks/*.sh` = **15**, `bash -n` clean on all of them, every hook wired in all three harness configs, and no game path string survives.

---

### R7 — Docs layer (18 files + `hooks-reference/`)

`agent-roster.md` is owned by R2 and `skills-reference.md` by R4 — this phase cross-checks them, it does not rewrite them.

- [ ] `agent-coordination-map.md`, `coordination-rules.md`, `director-gates.md` — rebuilt for the 31-agent roster and the five approval gates above
- [ ] `rules-reference.md`, `hooks-reference.md` + `hooks-reference/` — rebuilt, 1:1 with disk
- [ ] `.claude/docs/workflow-catalog.yaml` — **this phase owns the file**: phases 0–5 (not game production phases); R4 only re-points `step` ids at surviving skills
- [ ] `quick-start.md`, `setup-requirements.md` — Shopify CLI / Partner account / dev store / pinned API version prerequisites; drop engine SDK setup
- [ ] `agent-memory-setup.md`, `settings-local-template.md`, `CLAUDE-local-template.md` — rebrand, keep the mechanics
- [ ] `review-workflow.md` — code / security / UX / App Store review passes
- [ ] Replace `docs/engine-reference/{godot,unity,unreal,threejs}` (plus its `README.md`) with `docs/shopify-api-reference/` — version-pinned Admin API snapshot + `VERSION.md`
- [ ] `docs/architecture/` — rebuild ADRs for Shopify, including `tr-registry.yaml` → per-app requirements registry and `control-manifest.md` → per-app manifest
- [ ] `docs/registry/`, `docs/examples/` — rebuild for Shopify; delete engine examples
- [ ] `docs/WORKFLOW-GUIDE.md`, `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` — keep the principles, swap every example

**Done when:** every path referenced from `CLAUDE.md`, agents and skills resolves, and no engine reference dir remains (`ls docs/engine-reference` fails).

---

### R8 — Pipeline state & directories (**runs before R3**)

`.claude/docs/directory-structure.md` is owned here — it is where the isolation contract lives.

- [ ] `request.md` — exactly **one**; `track-request-changes.sh` rejects an untracked edit
- [ ] `request-history.md` — every superseded version with reason, timestamp and the loop it fed
- [ ] `apps/<app-name>/status.md` per app — stage, blockers, last approved gate
- [ ] `docs/registry/apps.json` — single append-only registry, the one source both `/start` and `session-start.sh` read
- [ ] `apps/<app>/approvals.json` — schema keyed by the five gate ids above, written by the skill at each gate (gate id, timestamp, approver)
- [ ] Isolation contract in `.claude/docs/directory-structure.md`: per app — own directory, own `.env.local` (git-ignored), own dev-store credentials file, own kanban file, own `production/apps/<app>/{sprints,milestones,session-state}/`; **no shared mutable file outside `docs/registry/apps.json`**; one writer per app dir; registry is append-only
- [ ] `production/` — split into per-app subdirs; the global `session-state/` holds repo-level state only
- [ ] Apply the directory decisions recorded in R0 (do not re-decide them here)
- [ ] Every loop (research, update, propose) reads the **current** `request.md`, never a cached copy

**Done when:** `/start` renders entirely from these files, and two apps can advance through different stages at the same time without either writing a file the other touches.

---

### R9 — Skill testing framework

- [ ] `git mv "AHGS Skill Testing Framework" "Skill Testing Framework"`, then update the three live references: `.claude/skills/skill-test/SKILL.md`, `.claude/skills/skill-improve/SKILL.md`, `docs/architecture/ADR-godot-test-framework-vcs-policy.md` (rename the ADR too)
- [ ] `catalog.yaml`, `README.md`, `CLAUDE.md`, `templates/` inside that tree — rebrand and re-domain (they still describe the game studio and list deleted roles)
- [ ] Respec `agents/` test specs to the R2 roster: delete engine / art / audio / narrative specs, add a spec for each of the 13 new roles under the right group dir
- [ ] Respec `skills/` test specs to the 66 surviving skills
- [ ] `quality-rubric.md` — keep the rubric shape, drop the game-specific criteria

**Done when:** every agent and skill in the roster has a spec, and no spec describes a deleted role.

---

### R10 — Verification gates (bind to Acceptance Criteria)

- [ ] **Zero game strings, tree-wide:** `grep -rliE 'godot|unity|unreal|gdextension|gds|threejs|gdscript' --exclude-dir=.git --exclude-dir=docs/legacy --exclude=TASKS.md .` → **0 results** (same pattern as the 163-file baseline, whole tree, `docs/legacy/` exempt)
- [ ] **Counts:** agents **31** == `.codex/agents`; skills **66**; rules **13**; hooks **15**; templates **35** — each equal to its reference doc
- [ ] `python3 .codex/generate_compat.py` → no diff
- [ ] `bash -n` all hooks; `python3 -m json.tool` on `.claude/settings.json` and `.codex/hooks.json`
- [ ] Add `.claude/scripts/check-references.py` (stdlib only) and run it: fail when (a) an agent named in a skill body is missing from `.claude/agents/`, (b) a skill named in an agent body is missing from `.claude/skills/`, (c) a `.claude/docs/templates/...` path in a skill does not resolve, (d) a name in `agent-roster.md` has no agent file; non-zero exit on any hit
- [ ] **`docs/legacy/AC-TRACE.md`** maps all 16 Acceptance Criteria to the item that satisfies each; any criterion without a linked item becomes a new item here before this gate can pass
- [ ] **Isolation check:** no two apps write the same file outside `docs/registry/apps.json`
- [ ] **Approval check:** `/release` on an app whose `approvals.json` lacks gate 4 exits non-zero
- [ ] **`/start` smoke run in Claude Code, Codex and Hermes** (Hermes through `production/hermes-profile-mapping.json`) — each shows master request, apps and stages

**Done when:** every gate above is green in a single run, and the command output is pasted into the commit message.

---

*Last updated: 2026-10-29*
