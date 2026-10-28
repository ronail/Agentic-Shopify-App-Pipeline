# REFACTOR-DECISIONS — Agent Harness Game Studios → Agentic Shopify App Pipeline

Phase **R0** (decisions only). This document is the single source of truth for the target
shape of the repo. Phases R2 (agents) and R4 (skills) **execute** the tables below; they do
not re-litigate them. Nothing here is provisional.

Ratified: 2026-10-29.

## 1. Baseline

The refactor starts from the imported AHGS *game* framework, unmodified.

| Asset | Count | Location |
|-------|-------|----------|
| Agents | 49 | `.claude/agents/` |
| Skills | 75 | `.claude/skills/` |
| Rules | 11 | `.claude/rules/` |
| Hooks | 12 | `.claude/hooks/` |
| Templates | 37 | `.claude/docs/templates/` (top level) |

- **Imported SHA:** `fec6e35` — `chore: import Agent Harness Game Studios framework as baseline`.
  This is the refactor baseline object and the SHA recorded in `production/hermes-profile-mapping.json`.
- **Current HEAD at ratification:** `258f862` — `docs(tasks): add per-phase acceptance criteria, smoke tests and completion rule`.
  The only tree change between `fec6e35` and HEAD is `TASKS.md` (verified with
  `git diff --name-status fec6e35..HEAD`); no baseline asset was removed, so the counts above
  still hold at HEAD.
- Every one of the 49 agents, 75 skills, 11 rules and 37 templates is game/engine oriented.
  None of it survives the refactor unchanged except the domain-neutral subset named in §2 and §3.

Target counts after R2 and R4: **31 agents**, **66 skills**. Rules, hooks and templates are
re-scoped in R6/R7 against the same roster and skill buckets decided here.

## 2. Agent roster (R2 target) — 49 → 31

**Arithmetic.** `49 − 31 = 18` net reduction. Of the 49 current agents: **31 are deleted**,
**18 are rewritten in place** (same file slot, new domain), so `31 + 18 = 49` accounted for.
Target roster = `18 rewritten + 13 new = 31`.

### 2.1 Delete — engine specialists (15)

godot-specialist, godot-gdscript-specialist, godot-csharp-specialist, godot-shader-specialist,
godot-gdextension-specialist, unity-specialist, unity-dots-specialist, unity-shader-specialist,
unity-addressables-specialist, unity-ui-specialist, unreal-specialist, ue-gas-specialist,
ue-blueprint-specialist, ue-replication-specialist, ue-umg-specialist

Rationale: zero engine in the target product. A Shopify app is a Node/Remix service plus
Polaris admin UI plus optional theme app extensions; no engine specialist has a successor.

### 2.2 Delete — game-only roles (16)

game-designer, gameplay-programmer, engine-programmer, level-designer, systems-designer,
economy-designer, narrative-director, writer, world-builder, art-director, technical-artist,
audio-director, sound-designer, ai-programmer, network-programmer, live-ops-designer

Rationale: craft roles bound to interactive-entertainment artefacts (levels, economies,
narrative bibles, audio, art direction). Their product-management and implementation duties
are absorbed by `product-director`, `lead-engineer`, `ux-lead` and `polaris-specialist`.

**Total deleted: 15 + 16 = 31.**

### 2.3 Rewrite — 18 surviving roles (`From → To`)

| # | From | To | New domain |
|---|------|----|-----------|
| 1 | creative-director | product-director | Product vision; owner of the master request (`request.md`) |
| 2 | technical-director | technical-director | Architecture, tech debt, API version policy |
| 3 | producer | producer | Pipeline, kanban, milestones, scope gates |
| 4 | lead-programmer | lead-engineer | Implementation lead; owns the code review gate |
| 5 | prototyper | prototype-builder | Throwaway merchant-facing prototypes |
| 6 | ux-designer | ux-lead | Merchant experience inside the embedded admin |
| 7 | ui-programmer | polaris-specialist | Polaris components, admin UX implementation |
| 8 | qa-lead | qa-lead | Test strategy, quality gates |
| 9 | qa-tester | qa-tester | Manual + regression passes on dev stores |
| 10 | release-manager | release-manager | App Store submission, versioning, release gates |
| 11 | security-engineer | security-specialist | OAuth, session tokens, data handling, audits |
| 12 | devops-engineer | devops-engineer | Hosting, CI/CD, environments, deploy to dev store |
| 13 | performance-analyst | performance-analyst | Admin load time, API/webhook latency, rate limits |
| 14 | analytics-engineer | analytics-engineer | Install funnel, usage events, merchant metrics |
| 15 | accessibility-specialist | accessibility-specialist | Admin UI accessibility, keyboard/screen-reader |
| 16 | localization-lead | localization-lead | Storefront/extension i18n, market coverage |
| 17 | community-manager | community-manager | Merchant support, App Store review responses, changelog comms |
| 18 | tools-programmer | tools-engineer | Shopify CLI, scripts, dev-store automation |

### 2.4 Add — new Shopify roles (13)

| # | Agent | Domain |
|---|-------|--------|
| 1 | research-specialist | Market, competitor and app-ecosystem research |
| 2 | app-architect | Per-app architecture inside `apps/<app>/` |
| 3 | api-lead | Admin/Storefront API surface, versioning, deprecations |
| 4 | growth-lead | Install funnel, pricing/packaging, merchant acquisition |
| 5 | graphql-specialist | Admin GraphQL, cost-based throttling, bulk operations |
| 6 | webhooks-specialist | Subscription lifecycle, HMAC verification, retries/backfill |
| 7 | billing-specialist | Billing API, subscription/usage charges, plan gating |
| 8 | auth-specialist | OAuth, session tokens, token exchange, embedded-app security |
| 9 | app-bridge-specialist | App Bridge, embedded admin navigation, session/context |
| 10 | liquid-specialist | Liquid templates, theme app extensions, app blocks |
| 11 | checkout-specialist | Checkout UI extensions and checkout-surface constraints |
| 12 | app-store-reviewer | App Store requirements, listing review, submission blockers |
| 13 | test-store-manager | Dev/test store provisioning, seed data, store lifecycle |

### 2.5 Target roster (31)

product-director, technical-director, producer, lead-engineer, prototype-builder, ux-lead,
polaris-specialist, qa-lead, qa-tester, release-manager, security-specialist, devops-engineer,
performance-analyst, analytics-engineer, accessibility-specialist, localization-lead,
community-manager, tools-engineer, research-specialist, app-architect, api-lead, growth-lead,
graphql-specialist, webhooks-specialist, billing-specialist, auth-specialist,
app-bridge-specialist, liquid-specialist, checkout-specialist, app-store-reviewer,
test-store-manager.

## 3. Skill buckets (R4 target) — 75 → 66

**Arithmetic.** `23 Delete + 31 Rewrite + 21 Keep = 75` current skills accounted for.
Target = `31 rewritten + 21 kept + 14 added = 66`.

### 3.1 Delete outright — game-only (23)

setup-engine, godot-screenshot, balance-check, playtest-report, asset-spec, asset-audit,
art-bible, map-systems, design-system, review-all-gdds, propagate-design-change,
vertical-slice, content-audit, day-one-patch, team-combat, team-narrative, team-audio,
team-level, team-ui, team-qa, team-polish, team-release, team-live-ops

### 3.2 Rewrite — workflow survives, domain changes (31)

start, brainstorm, quick-design, design-review, ux-design, ux-review, create-architecture,
architecture-decision, architecture-review, create-control-manifest, release-checklist,
launch-checklist, changelog, patch-notes, hotfix, qa-plan, soak-test, smoke-check,
regression-suite, perf-profile, security-audit, consistency-check, project-stage-detect,
onboard, localize, prototype, reverse-document, milestone-review, gate-check, scope-check,
tech-debt

### 3.3 Keep as-is — domain-neutral (21)

help, adopt, skill-test, skill-improve, create-epics, create-stories, dev-story,
story-readiness, story-done, sprint-plan, sprint-status, estimate, retrospective, code-review,
bug-report, bug-triage, feature-request, test-setup, test-helpers, test-evidence-review,
test-flakiness

### 3.4 Add (14)

| # | Skill | Purpose |
|---|-------|---------|
| 1 | research | Original \| Competitor Killer research; consumes current `request.md` |
| 2 | scaffold | Creates `apps/<app-name>/` skeleton; takes `--app <name>` |
| 3 | mmmvp-proposals | Propose minimal-market-viable-product slices for the current request |
| 4 | update-request | Amend `request.md` with new scope without losing prior intent |
| 5 | build-prototype | Build the throwaway merchant-facing prototype |
| 6 | prototype-review | Review a prototype against the request before committing to a build |
| 7 | kanban-status | Render pipeline/kanban state across apps |
| 8 | app-store-checklist | App Store submission readiness gate |
| 9 | create-test-store | Provision a dev/test store for an app |
| 10 | deploy-to-test-store | Deploy a build to the test store |
| 11 | release | Cut a versioned release for App Store submission |
| 12 | update-research | Refresh market/competitor research inputs |
| 13 | propose-updates | Propose framework/skill/agent updates from observed friction |
| 14 | apply-updates | Apply ratified proposals to agents, skills, rules, hooks |

## 4. Directory layout (R8 isolation input)

### 4.1 Surviving top-level directories — KEEP

| Dir | Role |
|-----|------|
| `src/` | Service implementation (Remix/Node app code, shared libraries) |
| `design/` | Design artefacts: UX specs, architecture docs, ADRs, API contracts |
| `production/` | Pipeline metadata: sprints, milestones, kanban state, session state, Hermes mapping |
| `docs/` | Process documentation, guides, legacy archive (`docs/legacy/`) |

### 4.2 Absent top-level directories — DROP (never imported)

`assets/`, `prototypes/`, `tests/`, `tools/` were **not** part of the imported baseline and
stay **absent**. Nothing is created under those names. Where their intent still matters:

- test code lives beside the source it tests inside `apps/<app>/`;
- throwaway prototypes live inside the app that spawned them, under `apps/<app>/prototype/`;
- dev tooling lives in `src/tools/` or in agent/skill scripts under `.claude/`.

### 4.3 Per-app data home — SPLIT (feeds R8's isolation contract)

Per-app state is split by *mutability*, not by feature:

| Path | Contents | Rule |
|------|----------|------|
| `apps/<app>/` | Per-app **working state and code**: app source, `prototype/`, app-local docs, app config, the app's own `request.md` history | Product-owned. Written by dev/tester/reviewer profiles for that app only. |
| `production/apps/<app>/` | Per-app **build and pipeline artefacts**: `sprints/`, `milestones/`, `session-state/`, release manifests, kanban cards | Producer/planning-owned. Written by planner/devops profiles and read by everyone. |

**Isolation contract for R8:**

1. An agent acting on app `X` may write under `apps/X/`, `production/apps/X/`, and — only for
   cross-app shared assets — `src/` and `design/`. It may also write `docs/`, `.claude/`,
   `.github/`, and repo-root framework files. Anywhere else is forbidden.
2. No agent reads or writes another app's `apps/Y/` or `production/apps/Y/`.
3. `production/apps/<app>/` never contains source; `apps/<app>/` never contains sprint or
   milestone records. The split is enforced by path, so `git status` shows which app a change
   belongs to.
4. Cross-app assets go to `src/` (shared code) or `design/` (shared design), never into an app
   directory.

## 5. Hermes profile mapping (R10 gate)

Hermes parity is a hard gate in R10, so the profile → agent resolution is fixed here.
Machine-readable copy: `production/hermes-profile-mapping.json`.

The delegate-task profile enum is exactly: `planner, product, researcher, dev, tester,
reviewer, devops`. Every one resolves to a target-roster agent.

| Hermes profile | Resolves to agent | Model tier | Purpose |
|----------------|-------------------|-----------|---------|
| planner | producer | opus | Pipeline, kanban, milestones, scope gates |
| product | product-director | opus | Product vision, owner of the master `request.md` |
| researcher | research-specialist | sonnet | Market, competitor and ecosystem research |
| dev | lead-engineer (fallback: app-architect) | opus | Implementation lead; per-app architecture when the task is structural |
| tester | qa-lead | sonnet | Test strategy and quality gates on dev stores |
| reviewer | app-store-reviewer (fallback: technical-director) | sonnet | App Store review; architecture review when the task is structural |
| devops | devops-engineer | sonnet | Hosting, CI/CD, environments, deploy to test store |

Resolution rules:

1. A subagent launched with profile `P` loads `.claude/agents/<agent>.md` from this table.
2. The fallback applies only when the delegated goal is explicitly architecture-shaped
   (`dev`) or architecture-review-shaped (`reviewer`); otherwise the primary agent wins.
3. Model tier in this table must match the agent frontmatter `model:` field once R2 writes it;
   Codex resolution follows `AGENTS.md` → `.codex/agent-models.toml`.
4. If a profile is missing from this table, the launch is a pipeline defect — do not guess.

## 6. Attribution

- This repo derives from **ronail/Agent-Harness-Game-Studios** (MIT), itself a fork of
  **Donchitos/Claude-Code-Game-Studios**.
- Keep `LICENSE` unchanged; it must remain MIT with both upstream copyright notices.
- Credit **both** projects in `README.md` — one line naming each, in derivation order
  (Donchitos upstream, ronail fork, this repo downstream).

# Open

_(empty — every decision above is ratified and closed. Nothing is deferred into R1.)_
