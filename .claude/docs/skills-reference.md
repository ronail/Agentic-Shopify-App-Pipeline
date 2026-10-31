# Available Skills (Slash Commands)

67 slash commands organized by pipeline phase. Type `/` to access any skill. The full step→skill map is resolved by /help from `.claude/docs/workflow-catalog.yaml`.

## Onboarding & Navigation

| Command | Purpose |
|---------|---------|
| `/start` | Pipeline dashboard — reads docs/registry/apps.json + request.md + per-app status, prints where each app stands, routes to the next skill. Supports /start claude\|codex\|hermes for model routing. |
| `/help` | Context-aware guidance — reads the current stage and surfaces the next required step. |
| `/onboard` | Onboard a developer or merchant to the project. |
| `/project-stage-detect` | Detect each app's pipeline stage from the registry + status/approvals. |
| `/adopt` | Brownfield audit — structure of an existing app, with a migration plan. |
| `/kanban-status` | Render pipeline/kanban state across all apps. |
| `/sprint-status` | 30-line snapshot of sprint progress. |

## Intake & Research

| Command | Purpose |
|---------|---------|
| `/update-request` | Amend request.md without losing prior intent (history to request-history.md). |
| `/mmmvp-proposals` | Propose minimal-market-viable slices for the current request. |
| `/research` | Original vs Competitor-Killer research, consuming request.md. |
| `/update-research` | Refresh market/competitor research inputs. |
| `/quick-design` | Lightweight spec for a small change, tuning, or tweak. |
| `/brainstorm` | App-concept ideation (merchant pain → app concept, Original/Competitor-Killer). |
| `/design-review` | Review a design spec for completeness, Polaris/accessibility, implementability. |
| `/ux-design` | Per-screen admin (Polaris) UX spec; WCAG 2.1 AA. |
| `/ux-review` | Validate UX specs vs Polaris, App Bridge, accessibility tier. |
| `/feature-request` | Propose a new feature for an app, scoped to request.md. |

## Architecture

| Command | Purpose |
|---------|---------|
| `/create-architecture` | Per-app architecture doc under docs/architecture/apps/<app>/. |
| `/architecture-decision` | ADR from the template, incl. Shopify API Surface + Requirements Addressed. |
| `/architecture-review` | Validate ADRs, requirements.yaml, control-manifest for Shopify conflicts. |
| `/create-control-manifest` | Required/Forbidden/Guardrails sheet per layer (admin server/webhooks/theme/checkout/data). |

## Prototyping

| Command | Purpose |
|---------|---------|
| `/build-prototype` | Build a throwaway merchant-facing prototype under apps/<app>/prototype/. |
| `/prototype` | Scaffold/replace a throwaway prototype (no test/doc-comment requirement). |
| `/prototype-review` | Review a prototype against the request before committing to a build. |

## Planning & Scope

| Command | Purpose |
|---------|---------|
| `/create-epics` | Translate ADRs + requirements into epics (one per architectural module). |
| `/create-stories` | Break each epic into implementable story files. |
| `/sprint-plan` | Plan the current sprint with prioritized, ready stories. |
| `/estimate` | Size stories (story points) from production/epics/. |
| `/story-readiness` | Validate a story is implementation-ready before pickup. |
| `/scope-check` | Detect scope creep by comparing to request.md. |
| `/gate-check` | Verify a pipeline gate (gate-1..5) against apps/<app>/approvals.json. |

## Build

| Command | Purpose |
|---------|---------|
| `/dev-story` | Pick the next ready story and implement it; route to the right agent. |
| `/code-review` | Architectural code review after each story, before story-done. |
| `/story-done` | Verify acceptance criteria and close the story. |
| `/qa-plan` | Per-epic/sprint QA plan; feeds /smoke-check and /regression-suite. |
| `/tech-debt` | Maintain and prioritize a tech-debt log. |

## Testing

| Command | Purpose |
|---------|---------|
| `/test-setup` | Scaffold Vitest once (tests live beside source in apps/<app>/). |
| `/test-helpers` | Generate shared test fixtures for GraphQL/webhook scenarios. |
| `/test-evidence-review` | Review test evidence for coverage and flakiness. |
| `/test-flakiness` | Diagnose and remove flaky tests. |
| `/smoke-check` | Post-change smoke on the test store (critical merchant flows). |
| `/regression-suite` | Run regression suites across apps (Vitest, recorded fixtures). |
| `/soak-test` | Extended stability under webhook load + GraphQL rate limits. |
| `/perf-profile` | Profile admin p75/LCP, bundle size, GraphQL cost. |
| `/security-audit` | OAuth/session/HMAC/PII/scope review with compliance webhooks. |

## Store & Deployment

| Command | Purpose |
|---------|---------|
| `/scaffold` | Create apps/<app-name>/ skeleton (--app <name>); register in registry. |
| `/create-test-store` | Provision a dev/test store for an app. |
| `/deploy-to-test-store` | Deploy a build to the test store for validation. |

## Release

| Command | Purpose |
|---------|---------|
| `/release-checklist` | App Store submission readiness (scopes, billing, compliance, privacy). |
| `/app-page-materials` | Author the App Store listing page: identity, copy, screenshots, icon, pricing, scopes, data handling. |
| `/app-store-checklist` | Final App Store submission gate. |
| `/release` | Cut a versioned release for App Store submission. |
| `/launch-checklist` | Post-approval go-live (deploy, live billing, monitoring, rollback). |
| `/changelog` | Internal changelog from commits, sprints, and design docs. |
| `/patch-notes` | Merchant-facing release notes. |
| `/hotfix` | Production incident hotfix (branch, minimal fix, test, redeploy). |

## Operations

| Command | Purpose |
|---------|---------|
| `/reverse-document` | Document existing app code into docs/architecture/apps/<app>/. |
| `/localize` | Merchant-facing localization (Markets, translations, locale formatting). |
| `/milestone-review` | Review a milestone for an app. |
| `/consistency-check` | Cross-app and cross-doc consistency scan. |
| `/propose-updates` | Propose framework/skill/agent updates from observed friction. |
| `/apply-updates` | Apply ratified proposals to agents, skills, rules, and hooks. |
| `/bug-report` | Log and structure a bug. |
| `/bug-triage` | Prioritize the open bug backlog. |
| `/retrospective` | Post-sprint review to capture what worked and what to change. |

## Meta

| Command | Purpose |
|---------|---------|
| `/skill-test` | Self-test a skill for correctness and safety. |
| `/skill-improve` | Improve a skill from observed usage. |
