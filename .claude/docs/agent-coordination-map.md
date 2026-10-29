# Agent Coordination and Delegation Map

The handoff graph for the 31-agent pipeline. The roster itself (domains, owning
rules, model tiers) lives in `agent-roster.md`; this file answers **who hands
what to whom, in which phase, and what artifact crosses the boundary**.

Sources of truth this map must agree with:

| Fact | File |
|---|---|
| Who exists, tier, domain | `.claude/docs/agent-roster.md` |
| Phase order and step ids | `.claude/docs/workflow-catalog.yaml` |
| Gate ids, approvers, evidence | `.claude/docs/director-gates.md` |
| Review passes | `.claude/docs/review-workflow.md` |

Domain: Shopify apps — Remix/Node app server, embedded Polaris admin, theme app
extensions, checkout UI extensions, and the Admin/Storefront GraphQL surface.

---

## Phase model (0–5)

| Phase | Name | Closes with | Catalog stages covered |
|---|---|---|---|
| 0 | Intake | — (no gate) | `intake` |
| 1 | Research | `gate-1-research` | `research` |
| 2 | Architecture & Prototype | `gate-2-prototype` | `architecture`, `prototype` |
| 3 | Scope | `gate-3-scope` | `scope` |
| 4 | Build, Test, Store | `gate-4-release` | `build`, `test`, `store` |
| 5 | Release & Operate | `gate-5-update` (per update) | `release`, `operate` |

A gate is the only place state advances: `gate-check` writes
`apps/<app>/approvals.json`, `apps/<app>/status.md`, and the app's `stage` /
`last_approved_gate` in `docs/registry/apps.json`.

Column meanings below: **From → To** is a single handoff, **Carries** is the
artifact that must exist for the handoff to count, **Done when** is the exit
condition the receiver can check without asking.

---

## Phase 0 — Intake

No gate. Shaping the request and routing it; nothing is built yet.

| From → To | Carries | Done when |
|---|---|---|
| human → `product-director` | feature request, bug report, or support theme | the decision is framed as Question → Options → Decision → Draft → Approval |
| `community-manager` → `product-director` | review complaints, support tickets, escalation counts | each candidate names a merchant segment and a source |
| `analytics-engineer` → `product-director` | success metric for the problem (install rate, task completion, churn signal) | the metric is measurable before the app exists, or says it is not |
| `product-director` → `research-specialist` | scoped `request.md` entry: problem, segment, non-goals | `request.md` carries acceptance criteria and explicit non-goals |
| `product-director` → `technical-director` | scope with architectural risk | feasibility read on API surface, scopes, and protected-data exposure |
| `product-director` → `growth-lead` | monetisation question, if pricing is unresolved | pricing shape (free / subscription / usage) proposed, not decided |
| `product-director` → `producer` | approved scope | a card exists on `production/kanban.md`, routed simple or complex |
| `producer` → owning agent | simple route (≤2 domains, ≤3 stories) | the domain agent accepts and works directly |
| `producer` → `product-director` + specialists | complex route (3-phase: digest, coordinate, verify) | every workstream has an owner and a deadline |

`product-director` never writes code; `producer` never decides scope.

---

## Phase 1 — Research

Closes with `gate-1-research` (approver: `product-director`).

| From → To | Carries | Done when |
|---|---|---|
| `research-specialist` → `product-director` | `production/research/<app>/` brief: competitors, pricing, review complaints, wedge | build/kill recommendation is argued from named comparables |
| `research-specialist` → `growth-lead` | competitor pricing and packaging table | positioning claim is traceable to a real listing |
| `research-specialist` → `ux-lead` | competitor flows and screenshots as UX grounding | the flow being designed is not being invented in a vacuum |
| `research-specialist` → `api-lead` | the operations the wedge requires | the API surface is named (objects, mutations, scopes), not assumed |
| `api-lead` → `technical-director` | pinned Admin API version, deprecation exposure, cost ceiling | a version is chosen and the needed operations exist in it |
| `ux-lead` → `polaris-specialist` | screen inventory, states, copy intent | Polaris components exist for each screen, or the gap is flagged |
| `ux-lead` → `accessibility-specialist` | flows with interaction intent | WCAG 2.1 AA obligations per screen are enumerated |
| `ux-lead` → `localization-lead` | copy inventory and string extraction points | translatable strings are identified before they are hardcoded |
| `ux-lead` → `product-director` | `ux-review` verdict on specs under `apps/<app>/design/ux/` | specs pass Polaris, App Bridge, and accessibility review |
| `app-store-reviewer` → `product-director` | requirement set the app must satisfy (protected data, billing, compliance webhooks) | policy risk is named early enough to change scope |
| `test-store-manager` → `devops-engineer` | dev store with scopes and seed data | `shopify app dev` runs against a real store |

**Gate 1 evidence**: `request.md` problem statement, research brief, named API
surface, policy risk, effort estimate.

---

## Phase 2 — Architecture & Prototype

Closes with `gate-2-prototype` (approver: `technical-director`).

| From → To | Carries | Done when |
|---|---|---|
| `technical-director` → `app-architect` | request + research brief | per-app architecture doc under `docs/architecture/apps/<app>/` |
| `api-lead` → `app-architect` | version policy and deprecation map | every ADR names the API version it assumes |
| `auth-specialist` → `app-architect` | OAuth and session-token model, scope consent flow | install path is decided, not "TBD in build" |
| `billing-specialist` → `app-architect` | plan model, charge type, entitlement enforcement point | plan gating has a server-side enforcement location |
| `webhooks-specialist` → `app-architect` | topic list, mandatory compliance topics, retry/idempotency stance | `shopify.app.toml` webhook declarations are drafted |
| `graphql-specialist` → `app-architect` | query shapes, cost per operation, bulk-operation needs | no operation is assumed to fit the cost budget without a number |
| `liquid-specialist` → `app-architect` | theme app extension blocks and schema | storefront surface is either in scope with a block plan, or excluded |
| `checkout-specialist` → `app-architect` | checkout extension targets and eligibility limits | checkout surface is either in scope, or explicitly excluded |
| `app-bridge-specialist` → `app-architect` | embedded navigation, session bootstrap, modal/toast constraints | admin embedding approach is fixed |
| `security-specialist` → `app-architect` | threat model, data retention, scope minimisation | protected-customer-data paths are enumerated |
| `app-architect` → `technical-director` | ADRs, `requirements.yaml` (`REQ-*`), `control-manifest.md` | ADRs `Accepted`, manifest date-stamped |
| `performance-analyst` → `technical-director` | budgets: admin TTI, GraphQL cost/op, webhook p95, rate-limit headroom | each budget has a number and a measurement method |
| `devops-engineer` → `technical-director` | hosting, environments, CI/CD, secrets, rollback plan | a preview deploy exists for the app |
| `app-architect` → `prototype-builder` | the riskiest merchant flow to answer one question | the question has a falsifiable answer, written before building |
| `prototype-builder` → `ux-lead` | runnable prototype under `apps/<app>/prototype/` | merchant flow can be walked end to end |
| `prototype-builder` → `product-director` | `prototype/README.md`: question, result, promote/iterate/abandon | verdict is recorded, not implied |

**Gate 2 evidence**: runnable prototype, prototype-review findings, production
isolation (no production import), captured requirements, decision.

---

## Phase 3 — Scope

Closes with `gate-3-scope` (approver: `product-director` with `technical-director`).

| From → To | Carries | Done when |
|---|---|---|
| `app-architect` → `producer` | one module per epic boundary | epics map to architecture, not to wishes |
| `producer` → `app-architect` | epic list for module-level review | module boundaries confirmed before stories are cut |
| `producer` → `qa-lead` | epics and acceptance criteria | a risk-based test strategy per epic exists |
| `qa-lead` → `qa-tester` | test plan per story | every story has a testable assertion |
| `qa-lead` → `producer` | readiness verdict per story | stories are estimable or returned |
| `producer` → `lead-engineer` | sprint plan with owners, estimates, dependencies | `production/sprints/sprint-*.md` is written and approved |
| `lead-engineer` → domain specialists | story assignment with module and interface sketch | each story names the files it will touch |
| `localization-lead` → `producer` | translation effort and market coverage | i18n work is estimated, not discovered in build |
| `app-store-reviewer` → `producer` | submission-blocking requirements as stories | listing, privacy policy, and review instructions have owners |
| `growth-lead` → `producer` | pricing and packaging stories | plan gating is scoped with billing |
| `product-director` → `producer` | scope-cut decision when `/scope-check` finds creep | out-of-scope list is explicit and written |

**Gate 3 evidence**: frozen scope statement, `requirements.yaml` with stable
`REQ-*` ids, `Accepted` ADRs, control manifest, estimable stories, explicit
out-of-scope list.

---

## Phase 4 — Build, Test, Store

No gate of its own; it ends at `gate-4-release`.

| From → To | Carries | Done when |
|---|---|---|
| `lead-engineer` → `graphql-specialist` / `webhooks-specialist` / `billing-specialist` / `auth-specialist` / `app-bridge-specialist` / `liquid-specialist` / `checkout-specialist` / `polaris-specialist` | story with module boundary and pattern to follow | pattern is reused, not reinvented per story |
| `tools-engineer` → `lead-engineer` | CLI workflows, scaffolding, codegen, dev-store scripts | manual steps are scripted or explicitly accepted |
| specialists → `lead-engineer` | pull request — code, tests, evidence | `LP-CODE-REVIEW` passes (see `review-workflow.md`) |
| `lead-engineer` → `security-specialist` | auth, token, webhook-signature, and merchant-data paths | `SEC-REVIEW` returns no open Critical/High |
| `security-specialist` → `lead-engineer` | findings with severity, path, owner, fix | every Critical/High has an owner and a fix commit |
| `polaris-specialist` → `accessibility-specialist` | implemented admin screens | keyboard, focus, screen-reader, contrast pass |
| `accessibility-specialist` → `qa-lead` + `polaris-specialist` | `A11Y-REVIEW` report | no WCAG 2.1 AA blocker remains |
| `analytics-engineer` → `lead-engineer` | event schema and instrumentation points | install, activation, and feature events fire on a dev store |
| `localization-lead` → `qa-lead` | locale coverage matrix | shipped locales render without truncation or missing keys |
| `test-store-manager` → `qa-tester` | seeded dev store, staff access, re-consented scopes | test data reproduces the merchant's scenario |
| `qa-lead` → `qa-tester` | regression scope for this build | `QL-TEST-COVERAGE` passes on the story set |
| `qa-tester` → `qa-lead` | bug reports and pass/fail evidence per test plan | failures are reproduced with steps and evidence |
| `qa-lead` → `lead-engineer` | triaged defects with severity | S1/S2 are fixed or waived by name |
| `performance-analyst` → `lead-engineer` | profile results against budgets | admin TTI and API latency are inside budget, or waived |
| `devops-engineer` → `release-manager` | CI pipeline, deploy + rollback, migration plan | the release commit deploys and rolls back cleanly |
| `app-store-reviewer` → `release-manager` | readiness report and checklist under `production/apps/<app>/` | every row PASS, or FAIL with an owner |
| `community-manager` → `qa-lead` | merchant-reported issues from support and reviews | each is triaged into a bug or a known limitation |

---

## Phase 5 — Release & Operate

Enters through `gate-4-release` (approver: `release-manager` with
`technical-director`); each update passes `gate-5-update` (approver:
`product-director`) before `/apply-updates`.

| From → To | Carries | Done when |
|---|---|---|
| `producer` → `release-manager` | release-candidate declaration, milestone state | RC is named by commit |
| `qa-lead` → `release-manager` | regression sign-off on that commit | `/regression-suite --full` PASS, or quarantine with owners |
| `security-specialist` → `release-manager` | `/security-audit` result | no open Critical/High |
| `billing-specialist` → `release-manager` | test-mode billing walk: subscribe, upgrade, downgrade, cancel | entitlement enforced server-side |
| `app-store-reviewer` → `release-manager` | checklist verdict + listing copy + reviewer instructions | submission blockers are zero |
| `localization-lead` → `release-manager` | translated listing metadata and market coverage | each shipped market has localized listing copy |
| `growth-lead` → `release-manager` | pricing, plan config, install-funnel expectations | pricing matches the billing implementation |
| `release-manager` → `devops-engineer` | release tag, deploy + rollback plan | deploy is reproducible from the tag |
| `release-manager` → `community-manager` | changelog, review-response copy, known issues | comms is written before the release is live |
| `devops-engineer` → `performance-analyst` | post-deploy telemetry access | latency and error rates are observable |
| `analytics-engineer` → `growth-lead` | funnel, retention, and churn dashboards | install → activation is measurable per cohort |
| `community-manager` → `analytics-engineer` | support themes and review sentiment | metrics have a qualitative counterpart |
| `community-manager` → `product-director` | recurring merchant pain, App Store review trends | the next request candidate is evidenced |
| `research-specialist` → `product-director` | `/update-research` delta: platform changes, competitor moves | the update is justified by something that changed |
| `product-director` → `release-manager` | approved update scope, `request.md` + `request-history.md` entry | `gate-5-update` recorded |
| `release-manager` → `technical-director` | migration and back-compat plan | existing installs upgrade without data loss |
| `technical-director` → `api-lead` | API version migration decision | pinned version move is scheduled, not discovered |
| `performance-analyst` → `technical-director` | post-release latency and rate-limit report | regressions become tech-debt items |
| `security-specialist` → `technical-director` | incident review, credential rotation | any incident leaves a written finding |

---

## Delegation authority

| Agent | May delegate to |
|---|---|
| `product-director` | `research-specialist`, `growth-lead`, `ux-lead` (product-shape questions) |
| `technical-director` | `app-architect`, `api-lead`, `performance-analyst`, `security-specialist`, `devops-engineer` |
| `producer` | any agent, limited to assignment, sequencing, and unblocking |
| `lead-engineer` | `graphql-specialist`, `webhooks-specialist`, `billing-specialist`, `auth-specialist`, `app-bridge-specialist`, `liquid-specialist`, `checkout-specialist`, `polaris-specialist`, `tools-engineer` |
| `app-architect` | `api-lead` (surface constraints) — advises, does not assign |
| `qa-lead` | `qa-tester`, `test-store-manager` (test environment) |
| `release-manager` | `devops-engineer` (release deploy), `qa-lead` (release regression), `app-store-reviewer` (submission evidence) |
| `ux-lead` | `polaris-specialist`, `accessibility-specialist` (implementation review) |
| `security-specialist` | advisory to any engineer; assigns no work |
| `test-store-manager` | advisory to `qa-tester` and `devops-engineer` on store state |
| `localization-lead` | advisory to `polaris-specialist`, `liquid-specialist`, `community-manager` |

Nobody delegates to a director. Directors delegate downward only.

---

## Escalation

| Situation | Escalate to |
|---|---|
| Two specialists disagree on implementation | `lead-engineer` |
| Implementation vs architecture | `technical-director` |
| Merchant value vs technical cost | `product-director` (value) + `technical-director` (feasibility), `producer` presents the trade |
| Scope creep against `request.md` | `product-director` |
| Schedule or dependency conflict | `producer` |
| Security finding disputed | `security-specialist`, then `technical-director` |
| App Store rejection | `app-store-reviewer`, fix owner named per blocker |
| Performance budget breach | `performance-analyst` flags, `technical-director` waives or blocks |
| Quality gate disagreement | `qa-lead`, then `technical-director` |
| Merchant-facing copy or review reply | `community-manager`, with `product-director` approval |

An escalation that ends in a decision writes the decision down (`request.md`,
ADR, or tech-debt record). Undocumented agreement does not exist.

---

## Coverage — 31 agents, phase and anchor handoff

| Agent | Phases | Anchor handoff |
|---|---|---|
| `product-director` | 0, 1, 3, 5 | scope → `producer` |
| `technical-director` | 0, 1, 2, 5 | ADR set → `lead-engineer` |
| `producer` | 0, 3, 5 | sprint plan → `lead-engineer` |
| `lead-engineer` | 3, 4 | PR review verdict → `qa-lead` |
| `prototype-builder` | 2 | prototype verdict → `product-director` |
| `ux-lead` | 1, 2, 4 | UX spec → `polaris-specialist` |
| `polaris-specialist` | 1, 4 | admin screens → `accessibility-specialist` |
| `qa-lead` | 3, 4, 5 | test plan → `qa-tester` |
| `qa-tester` | 3, 4 | bug report → `qa-lead` |
| `release-manager` | 4, 5 | release tag → `devops-engineer` |
| `security-specialist` | 2, 4, 5 | findings → `lead-engineer` |
| `devops-engineer` | 2, 4, 5 | deploy/rollback plan → `release-manager` |
| `performance-analyst` | 2, 4, 5 | budgets → `technical-director` |
| `analytics-engineer` | 0, 4, 5 | event schema → `lead-engineer` |
| `accessibility-specialist` | 1, 4 | a11y report → `qa-lead` |
| `localization-lead` | 1, 3, 4, 5 | translation scope → `producer` |
| `community-manager` | 0, 4, 5 | merchant themes → `product-director` |
| `tools-engineer` | 4 | scripts → `lead-engineer` |
| `research-specialist` | 1, 5 | research brief → `product-director` |
| `app-architect` | 2, 3 | ADRs + requirements → `producer` |
| `api-lead` | 1, 2, 5 | version policy → `app-architect` |
| `growth-lead` | 0, 3, 5 | pricing → `release-manager` |
| `graphql-specialist` | 2, 4 | operations → `app-architect` |
| `webhooks-specialist` | 2, 4 | subscribed topics → `app-architect` |
| `billing-specialist` | 2, 4, 5 | plan model → `app-architect` |
| `auth-specialist` | 2, 4 | install/auth model → `app-architect` |
| `app-bridge-specialist` | 2, 4 | embedding model → `app-architect` |
| `liquid-specialist` | 2, 4 | app blocks → `app-architect` |
| `checkout-specialist` | 2, 4 | extension targets → `app-architect` |
| `app-store-reviewer` | 1, 3, 4, 5 | readiness report → `release-manager` |
| `test-store-manager` | 1, 4 | seeded store → `qa-tester` |

---

## Anti-patterns

1. **Skipping a tier** — a specialist negotiating scope with `product-director`
   bypasses `lead-engineer` and `technical-director`; route it.
2. **Unnamed artifact** — "handed off to QA" with no test plan is a rumour. If
   the artifact does not exist on disk, the handoff has not happened.
3. **Cross-domain edits** — no agent writes outside its directory without the
   owning agent's delegation (`apps/<app>/`, `docs/`, `production/`, `src/`,
   `scripts/` are partitioned by rule, not habit).
4. **Prototype in production** — nothing under `apps/<app>/prototype/` may be
   imported by production code; gate 2 checks this.
5. **Silent gate advance** — a stage change without an `approvals.json` record
   is a broken pipeline; `approval-gate.sh` blocks it.
