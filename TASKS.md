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

---

### Phase completion rule — non-negotiable

Every phase (R0–R10) carries its own **acceptance criteria** (`AC-Rn.x`) and its own **smoke test**. A phase is complete **only when all four are true**:

1. **Every acceptance criterion in that phase is ticked.** All of them — not most. An unchecked criterion means the phase is in progress, and no later phase in the execution order may start.
2. **The phase smoke test passes when run verbatim:** exit code `0` and the output the phase states. "It looked fine in the editor", "the files exist", or a green result from a *different* command is not a pass. Paste the output into the commit message.
3. **Its gate passes** where the phase defines one (R3, R9, R10 add gates beyond the smoke test).
4. **The tree is clean** — the phase's changes are committed, and `git status --porcelain` shows nothing unexpected.

Corollaries that decide real arguments:

- **No phase is "mostly done".** Files landing is not progress; a phase with a red smoke test is at 0% for completion purposes, however much work is behind it.
- **A criterion may move, never disappear.** If an AC cannot pass in its phase, move it into a later phase's AC list **in the same commit**, with the reason. Deleting it, or leaving it unticked and moving on, is the failure this rule exists to stop.
- **Downstream phases do not compensate.** R4 passing does not excuse a red R8; R8 is a hard precondition for R3–R7 by execution order.
- **Ticking a criterion you did not run is worse than leaving it unticked** — an unticked box is visible, a false tick is not.

Worked example: R6 is a phase with 15 hooks. `ls .claude/hooks/*.sh | wc -l` returning 15 with one hook failing `bash -n` is a **failed** R6, and R7 does not start.

---

### R0 — Ratify the target shape (decisions only)

Every decision lands in one new file, `docs/legacy/REFACTOR-DECISIONS.md`. No existing file is edited in this phase.

- [ ] Write that file with the baseline counts and the imported SHA (`fec6e35`)
- [ ] **Ratify** the R2 agent roster (49 → 31) and the R4 skill buckets (75 → 66) as the target. Anything rejected moves under an `# Open` heading in the same file and must be closed before R1 starts — R2/R4 execute the ratified table, they do not re-litigate it
- [ ] Decide the surviving top-level dirs: `src/`, `design/`, `production/`, `docs/` — and record that `assets/`, `prototypes/`, `tests/`, `tools/` stay absent (they were never imported)
- [ ] Decide the data home for per-app state: `apps/<app>/…` vs `production/apps/<app>/…` (feeds R8's isolation contract)
- [ ] Write `production/hermes-profile-mapping.json` (Hermes profile → agent-role resolution). Hermes parity is a hard gate in R10, so this is required, not optional
- [ ] Record attribution: this repo derives from `ronail/Agent-Harness-Game-Studios` (MIT), itself a fork of `Donchitos/Claude-Code-Game-Studios`; keep `LICENSE`, credit both in `README.md`

**Acceptance criteria**

- [ ] **AC-R0.1** `docs/legacy/REFACTOR-DECISIONS.md` exists and has five `##` sections: baseline, roster, skills, directories, Hermes mapping (attribution may be a sixth)
- [ ] **AC-R0.2** The roster section lists exactly 31 agents (18 rewritten + 13 new) and names the 31 deleted ones — the arithmetic 49 − 31 = 18 is stated and correct
- [ ] **AC-R0.3** The skills section assigns **all 75** current skills to Delete / Rewrite / Keep and lists the 14 additions; 23 + 31 + 21 = 75
- [ ] **AC-R0.4** The directories section states keep/drop for `src`, `design`, `production`, `docs` and marks `assets`/`prototypes`/`tests`/`tools` absent
- [ ] **AC-R0.5** `production/hermes-profile-mapping.json` exists and parses as JSON
- [ ] **AC-R0.6** `# Open` is empty — nothing is deferred into R1
- [ ] **AC-R0.7** `git status --porcelain` lists only the two files above

**Smoke test**

```bash
test -f docs/legacy/REFACTOR-DECISIONS.md \
  && python3 -m json.tool production/hermes-profile-mapping.json >/dev/null \
  && [ "$(grep -c '^## ' docs/legacy/REFACTOR-DECISIONS.md)" -ge 5 ] \
  && [ "$(git status --porcelain | wc -l)" -eq 2 ] && echo R0-OK
```

Expected: `R0-OK`. Any other output — missing file, unparsable JSON, extra modified file — is a failed phase.

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

**Acceptance criteria**

- [ ] **AC-R1.1** No engine technology choice remains in the five config files: `grep -riE 'godot|unity|unreal|gdscript'` over `CLAUDE.md AGENTS.md README.md docs/CLAUDE.md src/CLAUDE.md` returns nothing
- [ ] **AC-R1.2** Every `@`-import in `CLAUDE.md` resolves to an existing path
- [ ] **AC-R1.3** `UPGRADING.md` is gone and `docs/legacy/DIVERGENCE.md` states the no-upstream-merge rule and the divergence SHA
- [ ] **AC-R1.4** `.gitignore` has no Godot/Unity/Unreal/binary-asset block; still ignores `.env*`, `.claude/settings.local.json`, `node_modules/`
- [ ] **AC-R1.5** `.github/FUNDING.yml` is gone, CODEOWNERS has no `settings.json` entry, PR + issue templates are intact
- [ ] **AC-R1.6** `docs/CLAUDE.md` no longer requires a "GDD Requirements Addressed" ADR section or `tr-registry.yaml`
- [ ] **AC-R1.7** `coding-standards.md` and `technical-preferences.md` name the Shopify stack, and `grep -iE 'gdscript|c#'` on them returns nothing

**Smoke test**

```bash
! grep -riE 'godot|unity|unreal|gdscript' CLAUDE.md AGENTS.md README.md docs/CLAUDE.md src/CLAUDE.md \
  && ! test -e UPGRADING.md && test -f docs/legacy/DIVERGENCE.md \
  && grep -oE '^@[^ ]+' CLAUDE.md | tr -d '@' | while read -r p; do test -e "$p" || { echo "MISSING $p"; exit 1; }; done \
  && echo R1-OK
```

Expected: `R1-OK` with no `MISSING` line. A `MISSING` path means `CLAUDE.md` still points at a deleted doc.

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

**Acceptance criteria**

- [ ] **AC-R2.1** `ls .claude/agents/*.md` = **31** files and the names match the rewrite table + Add list exactly — no leftover, no extra
- [ ] **AC-R2.2** All 31 deleted agents are gone from `.claude/agents` and from `.codex/agents`
- [ ] **AC-R2.3** `.codex/agents/*.toml` = 31 and `python3 .codex/generate_compat.py` produces no diff
- [ ] **AC-R2.4** No engine/audio/art/narrative string in any agent body: `grep -rliwE 'godot|unity|unreal|gdscript|gdd|battle pass' .claude/agents` returns nothing
- [ ] **AC-R2.5** Every agent has the Collaboration Protocol section (`grep -L 'Collaboration Protocol' .claude/agents/*.md` is empty)
- [ ] **AC-R2.6** Every agent's frontmatter has a valid `model:` tier of `opus|sonnet|haiku`
- [ ] **AC-R2.7** `.claude/docs/agent-roster.md` lists all 31 with an owning rule + skill column, and that file's rows match the directory 1:1

**Smoke test**

```bash
[ "$(ls .claude/agents/*.md | wc -l)" -eq 31 ] \
  && [ "$(ls .codex/agents/*.toml | wc -l)" -eq 31 ] \
  && ! grep -rliwE 'godot|unity|unreal|gdscript|battle pass' .claude/agents \
  && [ -z "$(grep -L 'Collaboration Protocol' .claude/agents/*.md)" ] \
  && [ -z "$(grep -L -E '^model: (opus|sonnet|haiku)' .claude/agents/*.md)" ] \
  && echo R2-OK
```

Expected: `R2-OK`. Any count mismatch, game string, or agent missing the protocol/model line fails the phase.

---

### R3 — Rules layer (11 → 13)

**Delete (5):** `engine-code.md`, `gameplay-code.md`, `shader-code.md`, `ai-code.md`, `narrative.md`

**Rewrite (6):** `ui-code.md` (→ Polaris / App Bridge), `network-code.md` (→ GraphQL / Webhooks), `data-files.md`, `design-docs.md`, `prototype-code.md`, `test-standards.md`

**Add (7):** `admin-embed-code.md`, `theme-extension-code.md`, `webhook-code.md`, `graphql-code.md`, `billing-code.md`, `auth-code.md`, `functions-code.md`

- [ ] Each rule's `paths:` frontmatter glob matches at least one file that exists on disk when the rule is written — run `find` against every glob and paste the command into the commit message. `apps/**` globs land after R8, so either write those rules after R8 or note the deferral in the commit
- [ ] `.claude/docs/rules-reference.md` lists every rule file, 1:1
- [ ] No rule contradicts `.claude/docs/coding-standards.md` or `technical-preferences.md`

**Acceptance criteria**

- [ ] **AC-R3.1** `ls .claude/rules/*.md` = **13** files, matching the delete/rewrite/add lists
- [ ] **AC-R3.2** No rule references a game path: `grep -riE 'src/game|assets/|shader|\bgodot\b|\bunity\b|\bunreal\b' .claude/rules` returns nothing
- [ ] **AC-R3.3** Every rule has `paths:` frontmatter whose glob resolves to ≥1 existing file (record the `find` per glob in the commit)
- [ ] **AC-R3.4** `rules-reference.md` has exactly 13 entries and each names a file that exists
- [ ] **AC-R3.5** Each of the 7 new rules has a stated owner among the R2 agents

**Smoke test**

```bash
[ "$(ls .claude/rules/*.md | wc -l)" -eq 13 ] \
  && ! grep -riE 'src/game|assets/|shader|\bgodot\b|\bunity\b|\bunreal\b' .claude/rules \
  && for f in $(grep -oE '[a-z0-9-]+\.md' .claude/docs/rules-reference.md | sort -u); do test -f ".claude/rules/$f" || { echo "MISSING $f"; exit 1; }; done \
  && echo R3-OK
```

Expected: `R3-OK`. Then run the per-glob `find` checks manually — that part cannot be faked by a count.

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

**Acceptance criteria**

- [ ] **AC-R4.1** `ls -d .claude/skills/*/` = **66** directories; the 23 deleted names are absent, the 14 new names are present
- [ ] **AC-R4.2** `.agents/skills` is a symlink that resolves to `.claude/skills`
- [ ] **AC-R4.3** No skill frontmatter/body carries game vocabulary: `grep -rliwE 'godot|unity|unreal|gdd|bartle|mda framework' .claude/skills/*/SKILL.md` returns nothing
- [ ] **AC-R4.4** `skills-reference.md` has 66 entries, each naming a directory that exists
- [ ] **AC-R4.5** Every skill named in an agent body exists, and every agent named in a skill body exists (R10's `check-references.py` is the arbiter; it must report zero here)
- [ ] **AC-R4.6** `/research` and `/scaffold` exist as directories with `SKILL.md` and are listed in the catalog
- [ ] **AC-R4.7** `/start` run once shows master request + apps + stages (empty-state output is acceptable before R8 seeds data, but the command must not error)

**Smoke test**

```bash
[ "$(ls -d .claude/skills/*/ | wc -l)" -eq 66 ] \
  && [ -L .agents/skills ] && [ -e .agents/skills ] \
  && test -f .claude/skills/research/SKILL.md && test -f .claude/skills/scaffold/SKILL.md \
  && ! grep -rliwE 'godot|unity|unreal|gdd|bartle' .claude/skills/*/SKILL.md \
  && echo R4-OK
```

Expected: `R4-OK`, then a manual `/start` invocation recorded in the commit message.

---

### R5 — Templates (37 → 35)

**Delete — game (14):** `game-concept`, `game-design-document`, `game-pillars`, `hud-design`, `level-design-document`, `narrative-character-sheet`, `faction-design`, `economy-model`, `difficulty-curve`, `art-bible`, `sound-bible`, `player-journey`, `systems-index`, `vertical-slice-report`

**Rewrite (23):** `pitch-document` (→ app pitch), `prototype-report`, `ux-spec`, `interaction-pattern-library`, `technical-design-document`, `architecture-decision-record`, `architecture-doc-from-code`, `architecture-traceability`, `test-plan`, `test-evidence`, `release-checklist-template`, `release-notes`, `changelog-template`, `incident-response`, `post-mortem`, `risk-register-entry`, `sprint-plan`, `milestone-definition`, `project-stage-report`, `concept-doc-from-prototype`, `design-doc-from-implementation`, `accessibility-requirements`, `skill-test-spec`

**Add (12):** `master-request`, `request-history`, `mmmvp-proposal`, `app-concept`, `app-prd`, `prototype-review`, `shopify-app-architecture`, `app-store-listing`, `test-store-plan`, `merchant-onboarding`, `pricing-plan`, `kanban-card`

- [ ] `.claude/docs/templates/collaborative-protocols/` is a **directory**, not one of the 37 templates: review each protocol doc in it for game examples and rewrite the affected ones — do not count it as a template
- [ ] No template keeps GDD / MDA / Bartle / engine concepts as required sections
- [ ] Every `.claude/docs/templates/...` path mentioned in a skill body resolves on disk (R10 automates this)

**Acceptance criteria**

- [ ] **AC-R5.1** `ls .claude/docs/templates/*.md` = **35** files; the 14 deleted names are absent, the 12 new names are present
- [ ] **AC-R5.2** `collaborative-protocols/` still exists and is documented as a directory, not a template
- [ ] **AC-R5.3** No template requires GDD / MDA / Bartle / engine sections: `grep -rilE 'game design document|\bmda\b|bartle|engine compatibility' .claude/docs/templates` returns nothing
- [ ] **AC-R5.4** Every `.claude/docs/templates/<name>.md` path referenced from a skill body resolves
- [ ] **AC-R5.5** Each of the 12 new templates is referenced by at least one skill (otherwise it is dead weight — link it or drop it)

**Smoke test**

```bash
[ "$(ls .claude/docs/templates/*.md | wc -l)" -eq 35 ] \
  && test -d .claude/docs/templates/collaborative-protocols \
  && ! grep -rilE 'game design document|\bmda\b|bartle|engine compatibility' .claude/docs/templates \
  && for p in $(grep -rhoE '\.claude/docs/templates/[a-z0-9/-]+\.md' .claude/skills | sort -u); do test -f "$p" || { echo "MISSING $p"; exit 1; }; done \
  && echo R5-OK
```

Expected: `R5-OK`. A `MISSING` line is a skill pointing at a template that was deleted or never written.

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

**Acceptance criteria**

- [ ] **AC-R6.1** `ls .claude/hooks/*.sh` = **15** and each one is named in `hooks-reference.md`
- [ ] **AC-R6.2** `bash -n` is clean on all 15
- [ ] **AC-R6.3** `.claude/settings.json` and `.codex/hooks.json` both parse as JSON and register the full set
- [ ] **AC-R6.4** The three new hooks exist and are executable by `bash`: `track-request-changes.sh`, `approval-gate.sh`, `app-store-gate.sh`
- [ ] **AC-R6.5** No hook references a game path: `grep -riE 'src/game|assets/|\bgodot\b|\bunity\b|\bunreal\b' .claude/hooks .codex/hooks` returns nothing
- [ ] **AC-R6.6** `approval-gate.sh` and `app-store-gate.sh` were each run against a deliberately failing fixture and exited non-zero **by name** — a gate that has never rejected anything is not verified
- [ ] **AC-R6.7** Hooks still work when `jq` is unavailable (simulate by `PATH` without `jq`)

**Smoke test**

```bash
[ "$(ls .claude/hooks/*.sh | wc -l)" -eq 15 ] \
  && for f in .claude/hooks/*.sh; do bash -n "$f" || exit 1; done \
  && python3 -m json.tool .claude/settings.json >/dev/null \
  && python3 -m json.tool .codex/hooks.json >/dev/null \
  && for h in track-request-changes.sh approval-gate.sh app-store-gate.sh; do test -f ".claude/hooks/$h" || { echo "MISSING $h"; exit 1; }; done \
  && ! grep -riE 'src/game|assets/|\bgodot\b|\bunity\b|\bunreal\b' .claude/hooks .codex/hooks \
  && echo R6-OK
```

Expected: `R6-OK`, then the two negative fixtures recorded in the commit (gate rejects → non-zero). Note the worked example in the completion rule: 15 files with one `bash -n` failure is a **failed** R6.

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

**Acceptance criteria**

- [ ] **AC-R7.1** `docs/engine-reference/` no longer exists; `docs/shopify-api-reference/VERSION.md` does and pins a concrete API version
- [ ] **AC-R7.2** No game-engine string under `.claude/docs/` or `docs/` outside `docs/legacy/` (`godot|unity|unreal|threejs|gdscript`)
- [ ] **AC-R7.3** Every reference doc that enumerates a set (roster, skills, rules, hooks) is 1:1 with disk
- [ ] **AC-R7.4** `workflow-catalog.yaml` parses as YAML and its top-level phases are 0–5
- [ ] **AC-R7.5** `quick-start.md` boots a fresh reader: Partner account → dev store → `shopify app dev` → `/start`, with no engine step
- [ ] **AC-R7.6** Every path referenced from `CLAUDE.md`, agents and skills resolves

**Smoke test**

```bash
test ! -d docs/engine-reference \
  && test -f docs/shopify-api-reference/VERSION.md \
  && ! grep -rliwE 'godot|unity|unreal|threejs|gdscript' --exclude-dir=legacy .claude/docs docs \
  && python3 -c "import sys;d=open('.claude/docs/workflow-catalog.yaml').read();assert 'phase' in d.lower()" \
  && echo R7-OK
```

Expected: `R7-OK`. If `grep` prints filenames instead, the docs layer still teaches the game framework.

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

**Acceptance criteria**

- [ ] **AC-R8.1** `request.md` exists, and exactly one non-history `request*.md` exists (`request.md`; `request-history.md` is the history and is excluded)
- [ ] **AC-R8.2** `request-history.md` exists and its format records version, reason, timestamp
- [ ] **AC-R8.3** `docs/registry/apps.json` parses as JSON and lists every directory under `apps/`
- [ ] **AC-R8.4** Each `apps/<app>/` has `status.md` and `approvals.json`; the latter parses as JSON and its keys are a subset of the five gate ids
- [ ] **AC-R8.5** `directory-structure.md` contains the isolation contract, including the "no shared mutable file outside the registry" rule and the one-writer-per-app rule
- [ ] **AC-R8.6** `production/apps/<app>/` exists for each app and holds `sprints/`, `milestones/`, `session-state/`
- [ ] **AC-R8.7** Two seed apps exist (`/scaffold` twice) and neither writes a file inside the other's directory — demonstrate with `git status` after touching both
- [ ] **AC-R8.8** An untracked edit to `request.md` is rejected by `track-request-changes.sh` (negative fixture, non-zero exit)

**Smoke test**

```bash
test -f request.md && test -f request-history.md \
  && [ "$(ls request*.md | grep -v '^request-history\.md$' | wc -l)" -eq 1 ] \
  && python3 -m json.tool docs/registry/apps.json >/dev/null \
  && [ "$(ls -d apps/*/ | wc -l)" -ge 2 ] \
  && for a in apps/*/; do
       test -f "$a/status.md" || { echo "MISSING $a/status.md"; exit 1; }
       python3 -m json.tool "$a/approvals.json" >/dev/null || exit 1
     done \
  && grep -q 'no shared mutable file' .claude/docs/directory-structure.md \
  && echo R8-OK
```

Expected: `R8-OK` with **at least two** app directories — the point of the phase is proving isolation, and one app proves nothing. This gate must be green before R3, R4's `/start`, or R6's `session-start.sh` are judged.

---

### R9 — Skill testing framework

- [ ] `git mv "AHGS Skill Testing Framework" "Skill Testing Framework"`, then update the three live references: `.claude/skills/skill-test/SKILL.md`, `.claude/skills/skill-improve/SKILL.md`, `docs/architecture/ADR-godot-test-framework-vcs-policy.md` (rename the ADR too)
- [ ] `catalog.yaml`, `README.md`, `CLAUDE.md`, `templates/` inside that tree — rebrand and re-domain (they still describe the game studio and list deleted roles)
- [ ] Respec `agents/` test specs to the R2 roster: delete engine / art / audio / narrative specs, add a spec for each of the 13 new roles under the right group dir
- [ ] Respec `skills/` test specs to the 66 surviving skills
- [ ] `quality-rubric.md` — keep the rubric shape, drop the game-specific criteria

**Acceptance criteria**

- [ ] **AC-R9.1** `Skill Testing Framework/` exists; `AHGS Skill Testing Framework/` does not
- [ ] **AC-R9.2** No live reference to the old name outside `docs/legacy/` and `TASKS.md`
- [ ] **AC-R9.3** Every one of the 31 agents has a spec, and no spec describes a deleted role
- [ ] **AC-R9.4** Every one of the 66 skills has a spec, or is listed in `catalog.yaml` as intentionally untested with a reason
- [ ] **AC-R9.5** `catalog.yaml` parses as YAML and names only existing directories
- [ ] **AC-R9.6** `quality-rubric.md` has no game-specific criterion (`grep -riE 'game|fun|player' quality-rubric.md` reviewed line by line, not by keyword count)

**Smoke test**

```bash
test -d "Skill Testing Framework" && test ! -d "AHGS Skill Testing Framework" \
  && [ -z "$(grep -rl 'AHGS Skill Testing Framework' .claude docs 2>/dev/null | grep -v '^docs/legacy/')" ] \
  && python3 -c "import sys;d=open('Skill Testing Framework/catalog.yaml').read();assert d.strip()" \
  && echo R9-OK
```

Expected: `R9-OK`. A leftover reference outside `docs/legacy/` means R4's `skill-test`/`skill-improve` still point at the old tree.

---

### R10 — Verification gates (bind to Acceptance Criteria)

- [ ] **Zero game strings, tree-wide:** `grep -rliwE 'godot|unity|unreal|gdextension|gds|threejs|gdscript' --exclude-dir=.git --exclude-dir=docs/legacy --exclude=TASKS.md .` → **0 results** (word-boundary variant of the baseline pattern, whole tree, `docs/legacy/` exempt)
- [ ] **Counts:** agents **31** == `.codex/agents`; skills **66**; rules **13**; hooks **15**; templates **35** — each equal to its reference doc
- [ ] `python3 .codex/generate_compat.py` → no diff
- [ ] `bash -n` all hooks; `python3 -m json.tool` on `.claude/settings.json` and `.codex/hooks.json`
- [ ] Add `.claude/scripts/check-references.py` (stdlib only) and run it: fail when (a) an agent named in a skill body is missing from `.claude/agents/`, (b) a skill named in an agent body is missing from `.claude/skills/`, (c) a `.claude/docs/templates/...` path in a skill does not resolve, (d) a name in `agent-roster.md` has no agent file; non-zero exit on any hit
- [ ] **`docs/legacy/AC-TRACE.md`** maps all 16 project Acceptance Criteria **and** every `AC-Rn.x` in this section to the item that satisfies each; any criterion without a linked item becomes a new item here before this gate can pass
- [ ] **Isolation check:** no two apps write the same file outside `docs/registry/apps.json`
- [ ] **Approval check:** `/release` on an app whose `approvals.json` lacks gate 4 exits non-zero
- [ ] **`/start` smoke run in Claude Code, Codex and Hermes** (Hermes through `production/hermes-profile-mapping.json`) — each shows master request, apps and stages

**Acceptance criteria**

- [ ] **AC-R10.1** The tree-wide engine grep returns 0 files
- [ ] **AC-R10.2** All five counts match their reference docs (31 / 66 / 13 / 15 / 35)
- [ ] **AC-R10.3** `check-references.py` exists, exits 0, and was proven to fail by pointing it at a renamed agent (negative fixture restored afterwards)
- [ ] **AC-R10.4** `docs/legacy/AC-TRACE.md` covers 16 project criteria + every `AC-Rn.x`, with no empty mapping cell
- [ ] **AC-R10.5** Isolation and approval negative fixtures both exit non-zero by name
- [ ] **AC-R10.6** `/start` runs in all three harnesses; output pasted in the commit
- [ ] **AC-R10.7** `git status --porcelain` is clean and the final commit message contains the pasted gate output

**Smoke test**

```bash
! grep -rliwE 'godot|unity|unreal|gdextension|gds|threejs|gdscript' --exclude-dir=.git --exclude-dir=docs/legacy --exclude=TASKS.md . \
  && [ "$(ls .claude/agents/*.md | wc -l)" -eq 31 ] \
  && [ "$(ls -d .claude/skills/*/ | wc -l)" -eq 66 ] \
  && [ "$(ls .claude/rules/*.md | wc -l)" -eq 13 ] \
  && [ "$(ls .claude/hooks/*.sh | wc -l)" -eq 15 ] \
  && [ "$(ls .claude/docs/templates/*.md | wc -l)" -eq 35 ] \
  && python3 .claude/scripts/check-references.py \
  && test -f docs/legacy/AC-TRACE.md \
  && echo R10-OK
```

Expected: `R10-OK`. This is the last gate; a partial pass is a failed refactor, and the project Acceptance Criteria block at the top of this file stays unticked until this line prints.

---

*Last updated: 2026-10-29*
