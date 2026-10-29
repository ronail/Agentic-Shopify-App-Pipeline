# Agentic Shopify App Pipeline — Quick Start

## What Is This?

A complete Claude Code agent architecture for building **Shopify apps**. It
organizes 31 specialized AI agents into a studio hierarchy that mirrors a real
product team, with defined responsibilities, delegation rules, and coordination
protocols. Agents cover the whole Shopify surface — embedded Polaris admin,
Remix/Node app server, GraphQL Admin API, webhooks, billing, theme app
extensions, and checkout UI extensions.

The pipeline runs seven stages behind **5 gates**: research → architecture →
prototype → scope → build → test → release (→ update). The Shopify Admin GraphQL
API is **pinned to 2026-10**; every agent checks the pinned snapshot in
`docs/shopify-api-reference/` before writing a query, mutation, or webhook
payload.

## Boot a Fresh Machine

Five steps from nothing to a running app.

### 1. Prerequisites (once per machine)

- Node.js **LTS** and `npm`
- Shopify CLI — installed as a project dependency, or
  `npm install -g @shopify/cli@latest`
- Git, `jq` (hooks use it; see `setup-requirements.md`)

### 2. Create a Partner account

Sign up at [partners.shopify.com](https://partners.shopify.com) if you do not
have one. Everything a development store needs hangs off the Partner account:
app registration, client credentials, extension drafts, and App Store
submission.

### 3. Create a development store

In the Partner dashboard: **Stores → Add store → Development store**. Pick the
"Create a store to test and build" option, no Shopify plan needed. Note the
store handle — it is the `--store` value you pass to the CLI.

### 4. Wire the app and run it locally

```bash
git clone <this repo> && cd <repo>
npm install                      # installs @shopify/cli and app deps
shopify app config link          # attach the repo to your Partner app
shopify app dev --store <your-dev-store>
```

`shopify app dev` starts the Remix server, opens a tunnel, pushes the app
config (scopes, webhooks, extensions) to the store, and prints the embedded
admin URL. If the repo already has a `dev` script, `npm run dev` is equivalent.

Keep this running. `shopify app deploy` is the separate command that pushes
extensions and config for a release — not for local dev.

### 5. Onboard the agents

In a second terminal, start your harness (Claude Code, Codex, or Hermes) and
run:

```
/start
```

`/start` reads `docs/registry/apps.json`, the app status files, and
`production/`, then prints where every app stands and routes you to the next
skill. It also configures model routing — `/start claude`, `/start codex`, or
`/start hermes`. Nothing about your project is assumed.

That is the full loop. Everything below is reference.

## The Hierarchy

- **Tier 1 (Opus)**: directors who make cross-app decisions
  - `product-director` — product vision, owns the master `request.md`
  - `technical-director` — architecture, tech debt, Shopify API version policy
  - `producer` — pipeline, kanban, milestones, scope gates
  - `lead-engineer` — implementation lead, owns the code-review gate

- **Tier 2 (Sonnet)**: leads and specialists who own a surface
  - `app-architect`, `api-lead`, `ux-lead`, `qa-lead`, `localization-lead`,
    `release-manager`, `growth-lead`, `prototype-builder`

- **Tier 3 (Sonnet/Haiku)**: specialists who execute within a surface
  - `polaris-specialist`, `graphql-specialist`, `webhooks-specialist`,
    `billing-specialist`, `auth-specialist`, `app-bridge-specialist`,
    `liquid-specialist`, `checkout-specialist`, `app-store-reviewer`,
    `analytics-engineer`, `devops-engineer`, `tools-engineer`,
    `security-specialist`, `performance-analyst`, `accessibility-specialist`,
    `qa-tester`, `research-specialist`, `community-manager`,
    `test-store-manager`

The full roster with owning rules and skills is `.claude/docs/agent-roster.md`.

## Pick the Right Agent

Ask: "which surface does this touch?"

| I need to... | Use this agent |
|--------------|----------------|
| Decide what the app should be | `product-director` |
| Make an architecture decision | `technical-director` |
| Plan a milestone or sprint | `producer` |
| Review code before a story closes | `lead-engineer` |
| Design the app's system boundaries | `app-architect` |
| Pick or bump the Admin API version | `api-lead` |
| Build an embedded admin screen | `polaris-specialist` |
| Write queries, mutations, bulk ops | `graphql-specialist` |
| Handle webhooks (HMAC, topics) | `webhooks-specialist` |
| Implement billing and plan gating | `billing-specialist` |
| OAuth, session tokens, install flow | `auth-specialist` |
| App Bridge navigation and context | `app-bridge-specialist` |
| Liquid, theme app extension blocks | `liquid-specialist` |
| Checkout UI extensions | `checkout-specialist` |
| Audit accessibility (WCAG 2.1 AA) | `accessibility-specialist` |
| Profile routes, bundle, GraphQL cost | `performance-analyst` |
| Security audit before release | `security-specialist` |
| Deploy, migrations, CI | `devops-engineer` |
| Provision a dev/test store | `test-store-manager` |
| Write test cases and evidence | `qa-tester`, `qa-lead` |
| Localize merchant-facing strings | `localization-lead` |
| Prepare the App Store listing | `app-store-reviewer` |
| Track installs and retention | `analytics-engineer` |
| Write merchant-facing release notes | `community-manager` |
| Validate a market/competitor gap | `research-specialist` |
| Throwaway prototype of a flow | `prototype-builder` |

## Slash Commands

The canonical set is **66 skills** in `.claude/skills/`. The ones you will
actually type:

**Orientation**

| Command | What it does |
|---------|--------------|
| `/start` | Pipeline dashboard — every app's stage, then routes to the next skill |
| `/help` | Context-aware "what do I do next?" |
| `/project-stage-detect` | Detect each app's stage from disk and name the next action |
| `/kanban-status` | Read-only board across all apps |
| `/adopt` | Brownfield audit and migration plan |
| `/consistency-check` | Drift audit across registry, status files, gate approvals, API pins |

**Research → concept**

| Command | What it does |
|---------|--------------|
| `/research` | Merchant problem, competitors, pricing, build/kill recommendation |
| `/brainstorm` | Guided app concept — Original or Competitor-Killer |
| `/mmmvp-proposals` | Smallest slice a merchant would pay for |
| `/update-research` | Refresh stale research with a dated delta |
| `/update-request` | Amend `request.md` without losing prior intent |

**Architecture**

| Command | What it does |
|---------|--------------|
| `/architecture-decision` | Author one ADR, including its Shopify API surface |
| `/create-architecture` | Per-app architecture document |
| `/architecture-review` | REQ → ADR traceability, API cross-check, PASS/CONCERNS/FAIL |
| `/create-control-manifest` | Flat programmer rules sheet from Accepted ADRs |
| `/create-epics` | One epic per architectural module |
| `/create-stories` | Break an epic into implementable story files |

**Prototype & UX**

| Command | What it does |
|---------|--------------|
| `/prototype` | Throwaway Polaris prototype under `apps/<app>/prototype/` |
| `/build-prototype` | Build the prototype the request actually needs |
| `/prototype-review` | Judge the prototype before production work |
| `/ux-design` | Section-by-section UX spec for one admin screen |
| `/ux-review` | Validate against Polaris, App Bridge, WCAG 2.1 AA |
| `/design-review` | Review a requirements/UX/architecture spec |

**Build**

| Command | What it does |
|---------|--------------|
| `/scaffold` | Per-app directory skeleton and registry entry |
| `/story-readiness` | Is this story implementable? READY / NEEDS WORK / BLOCKED |
| `/dev-story` | Implement a story, routed to the right specialist |
| `/code-review` | Review against control manifest, ADRs, Shopify concerns |
| `/story-done` | Verify acceptance criteria, close the story |
| `/feature-request` | Tiered routing for a new ask |
| `/quick-design` | Lightweight spec for a small change |
| `/scope-check` | In-scope / adjacent / creep classification |
| `/tech-debt` | Maintain the per-app debt register |

**Test & release**

| Command | What it does |
|---------|--------------|
| `/qa-plan` | Per-sprint QA plan |
| `/test-setup` | Scaffold Vitest + CI pipeline (run once) |
| `/test-helpers` | Shared factories and request mocks |
| `/regression-suite` | Full Vitest run with coverage gates |
| `/smoke-check` | Post-deploy critical-flow gate on the dev store |
| `/test-evidence-review` | ADEQUATE / INCOMPLETE / MISSING per story |
| `/perf-profile` | Measure against the performance budgets |
| `/security-audit` | Severity-ranked findings with exploit paths |
| `/gate-check` | Check gate-1..gate-5, record the approval |
| `/release` | Versioned release, tag, rollback plan |
| `/release-checklist` | App Store submission readiness |
| `/app-store-checklist` | Listing, scopes, billing, policy compliance |
| `/launch-checklist` | Go/no-go after approval |
| `/changelog`, `/patch-notes` | Merchant-facing changelog and notes |
| `/hotfix` | Emergency path with audit trail |

**Store & sprint ops**

| Command | What it does |
|---------|--------------|
| `/create-test-store`, `/deploy-to-test-store` | Provision and deploy to a dev store |
| `/sprint-plan`, `/sprint-status` | Plan and snapshot the sprint |
| `/milestone-review` | SHIP / HOLD with per-criterion evidence |
| `/retrospective` | Sprint or milestone retro |
| `/bug-report`, `/bug-triage` | File, verify, re-prioritize bugs |
| `/onboard` | Dev, merchant-reviewer, or dev-store onboarding |

## Templates

35 documents in `.claude/docs/templates/`, one per artifact type:

**Request and product definition** — `master-request.md`, `request-history.md`,
`app-concept.md`, `app-prd.md`, `mmmvp-proposal.md`, `pitch-document.md`,
`prototype-report.md`, `prototype-review.md`, `concept-doc-from-prototype.md`,
`design-doc-from-implementation.md`

**Architecture** — `shopify-app-architecture.md`,
`architecture-decision-record.md`, `architecture-traceability.md`,
`architecture-doc-from-code.md`

**UX** — `ux-spec.md`, `interaction-pattern-library.md`,
`accessibility-requirements.md`

**Planning and reporting** — `sprint-plan.md`, `milestone-definition.md`,
`risk-register-entry.md`, `project-stage-report.md`, `post-mortem.md`,
`kanban-card.md`

**Quality and release** — `test-plan.md`, `test-evidence.md`,
`test-store-plan.md`, `release-checklist-template.md`, `release-notes.md`,
`changelog-template.md`, `incident-response.md`, `skill-test-spec.md`

**Commercial** — `app-store-listing.md`, `pricing-plan.md`,
`merchant-onboarding.md`

`.claude/docs/templates/collaborative-protocols/` is a **directory**, not a
template — it holds the protocol docs agents embed:

- `design-agent-protocol.md` — question-options-draft-approval cycle
- `implementation-agent-protocol.md` — story pickup through `/story-done`
- `leadership-agent-protocol.md` — cross-department delegation and escalation

## Coordination Rules

1. Work flows down the hierarchy: directors → leads → specialists.
2. Conflicts escalate up the hierarchy.
3. Cross-surface work is coordinated by the `producer`.
4. Agents do not modify files outside their domain without delegation.
5. All decisions are documented — an ADR, a story, or a recorded gate verdict.

## Gates

Five gates, checked with `/gate-check <gate-id>` against the app's
`approvals.json` and the evidence on disk. Verdicts are advisory: they guide the
decision, never hard-block it.

| Gate | Question | Evidence |
|------|----------|----------|
| `gate-1-research` | Is the merchant problem real and worth building for? | `production/research/<app>/` |
| `gate-2-prototype` | Does the flow prove the value? | `apps/<app>/prototype/`, prototype review |
| `gate-3-scope` | Is the build the smallest shippable slice? | scope check, request history |
| `gate-4-release` | Is the app submittable and safe? | security audit, smoke check, release checklist |
| `gate-5-update` | Is the next iteration justified by evidence? | updated research, metrics |

Director review depth is set once in `production/review-mode.txt`
(`full` / `lean` / `solo`); gate prompts live in `.claude/docs/director-gates.md`.

## First Steps by Situation

### Path A — "I have no app idea"

1. **`/research`** — validate a merchant pain with competitors and pricing.
2. **`/brainstorm`** — turn it into a structured concept; register the app.
3. **`/mmmvp-proposals`** — cut it to the smallest slice a merchant pays for.
4. **`/scaffold`** — create the per-app skeleton.
5. **`/architecture-decision` + `/create-architecture`** — decide boundaries and
   the exact Shopify API surface, against the pinned 2026-10 snapshot.
6. **`/prototype` → `/prototype-review`** — prove the flow before building it.
7. **`/gate-check gate-3-scope`** — then `/create-epics`, `/create-stories`,
   `/sprint-plan`.

### Path B — "I know the app I want"

1. Write `request.md` (template: `.claude/docs/templates/master-request.md`).
2. **`/scaffold`** the app.
3. **`/create-architecture`**, then ADRs for each real decision.
4. **`/create-control-manifest`**, **`/create-epics`**, **`/create-stories`**.
5. **`/sprint-plan`**, then `/story-readiness` → `/dev-story` →
   `/code-review` → `/story-done`.

### Path C — "I have an existing app or repo"

1. **`/adopt`** — audit what exists against template format, get a numbered
   migration plan. Nothing is overwritten.
2. **`/reverse-document`** — turn code into architecture docs and ADR
   candidates.
3. **`/architecture-review`** — cross-check every decision against the pinned
   API snapshot.
4. **`/gate-check`** to see where you actually stand, then `/sprint-plan`.

### Path D — "The app is live and something broke"

1. **`/bug-report`** — reproduce and classify.
2. **`/hotfix`** — branch from the released tag, minimum fix with a reproducing
   test, verify on a test store, deploy with a rollback plan.
3. **`/incident-response`** template for the record.

## File Structure Reference

```
CLAUDE.md                          -- Master config (read this first)
.claude/
  settings.json                    -- hooks and project settings
  agents/                          -- 31 agent definitions (YAML frontmatter)
  skills/                          -- 66 skill definitions (YAML frontmatter)
  hooks/                           -- hook scripts (.sh) wired by settings.json
  rules/                           -- 13 path-specific rule files
  docs/
    quick-start.md                 -- This file
    technical-preferences.md       -- Project standards (written by /start)
    coding-standards.md            -- Code and requirements doc standards
    coordination-rules.md          -- Agent coordination rules
    context-management.md          -- Context budgets and compaction
    directory-structure.md         -- Project directory layout
    workflow-catalog.yaml          -- 7-stage pipeline definition (read by /help)
    setup-requirements.md          -- Prerequisites
    settings-local-template.md     -- Personal settings.local.json guide
    templates/                     -- 35 document templates
apps/<app>/                        -- per-app code, design, prototype
docs/
  architecture/apps/<app>/         -- ADRs, control manifest, requirements.yaml
  shopify-api-reference/<version>/ -- pinned Admin API snapshots (2026-10)
  registry/apps.json               -- app registry (read by /start, /kanban-status)
production/
  apps/<app>/                      -- sprints, QA evidence, milestones
  research/<app>/                  -- research and competitor findings
  session-state/active.md          -- session checkpoint
  review-mode.txt                  -- full / lean / solo
```

---

## Optional: Hermes Model Routing

When using **Hermes as the harness**, subagent models are resolved from the
`delegation` section of the active profile's
`~/.hermes/profiles/<name>/config.yaml`, not from the `model:` field in
skill/agent frontmatter. The frontmatter values (`haiku` / `sonnet` / `opus`)
stay as the shared tier labels; Codex maps them to GPT models, and Hermes maps
them through whichever delegation mode you configure.

Run the routing setup during onboarding:

```bash
/start hermes
```

Phase 3d of `/start` detects your profiles, the active `delegation.backend`, and
whether the advanced-delegation plugin is installed, then asks how a subagent
should pick its model. It writes a paste-ready `production/hermes-delegation.yaml`
plus `production/hermes-profile-mapping.json` as the recorded plan.

### Delegation modes

One mode is active at a time:

| `delegation.backend` | Per-task parameter | Behaviour |
|----------------------|--------------------|-----------|
| `default` (built in) | none | Every child runs on `delegation.model` / `delegation.provider`, else the parent's model. |
| `model_map` | `option` | The agent picks a named model route per task, from routes you define. |
| `profile_routes` | `profile` | The agent runs each child as one of your Hermes profiles, with that profile's model, credentials, skills and `SOUL.md`. |

`model_map` and `profile_routes` come from the official **advanced-delegation**
plugin, which needs Hermes 0.22.5 or newer and is installed per profile — install
it in the profile that delegates:

```bash
hermes plugins install advanced-delegation
```

Configure it interactively, or paste the block yourself:

```bash
hermes delegation config          # pick the mode, then edit its routes
hermes delegation config --show   # print the current mode and routes
```

```yaml
# ~/.hermes/profiles/<name>/config.yaml
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
```

Backend settings live under `delegation.backends.<backend name>`, never beside the
core `delegation` keys. Profile routes list names instead of model ids:

```yaml
delegation:
  backend: profile_routes
  backends:
    profile_routes:
      profiles:
        - name: <profile>
          description: "Producer and director work: phase gates, review, scheduling."
      default: <profile>
```

Five rules matter when you wire this up:

- **Only names and descriptions reach the model.** The provider, model id,
  endpoint and key are never tool parameters, so the agent cannot invent a route.
  That also means `model_map` routes are chosen per task by the agent — the
  `model:` tier in agent frontmatter is carried by the route descriptions and the
  `default` route, not enforced.
- **`delegation.model` / `delegation.provider` are inactive** while `model_map`
  or `profile_routes` is the active mode. Switching back to `default` makes them
  apply again.
- **Fail closed.** A backend that is selected but missing or unable to run makes
  `delegate_task` return an error naming it and the fix. Hermes never falls back
  to `default` on its own.
- **Profile routes share credentials.** Listing a profile lets this profile's
  subagents use that profile's credentials, credential pool, `SOUL.md` and
  terminal policy — only list profiles you are happy to share that with.
- **The tool schema is cached.** The per-task `option` / `profile` list is built
  when a session starts. `/delegation <mode>` saves the mode for the next session
  (`/new`); `/delegation <mode> --now` also rebuilds the running chat's tools, at
  the cost of one prompt-cache break.

### Studio hierarchy settings

Three `delegation` settings change how studio agents nest or collide. `/start
hermes` asks about the first two; check any of them with
`hermes config get delegation.<key>`.

| Setting | Default | Use it when |
|---------|---------|-------------|
| `max_spawn_depth` | `1` (flat) | `2` lets a director's subagent (spawned with `role="orchestrator"`) spawn its own leads and specialists. |
| `worktree_isolation` | `false` | Parallel implementers edit the same repo and would collide. Each child gets its own git worktree, branched from `HEAD`. |
| `max_concurrent_children` | configurable, `10` in 0.22.x | A wider parallel batch. No hard ceiling; cost is the limit. |

At the default depth, `role="orchestrator"` is a no-op: children are leaves and
stop at one level. Raise `max_spawn_depth` deliberately — each extra level
multiplies spend, and children are where the tokens go.

Backends are ordinary Hermes plugins; see
[Delegation Provider Plugins](https://github.com/NousResearch/hermes-agent/blob/main/website/docs/developer-guide/delegation-provider-plugin.md)
for the interface and
[Subagent Delegation](https://github.com/NousResearch/hermes-agent/blob/main/website/docs/user-guide/features/delegation.md)
for the delegation settings themselves.

If you are **not** using Hermes, the `model:` field in each agent/skill definition
is used directly — no changes are needed.

## Optional: Codex Model Setup

When using **Codex as the harness**, the `model:` fields in skill and agent
frontmatter remain the shared `haiku` / `sonnet` / `opus` tier labels. The
project-local `.codex/config.toml` sets the standard GPT model. The tier mapping
is:

| Shared tier | Codex model |
|-------------|-------------|
| Haiku | `gpt-6-luna` |
| Sonnet | `gpt-6.1-terra` |
| Opus | `gpt-6.1-sol` |

The standard tier is the project default. Run `/start codex` during onboarding
to review the mapping and choose a session model.
