# Skill Testing Framework

Quality assurance infrastructure for the **Agentic Shopify App Pipeline** framework.
Tests the skills and agents themselves — not any Shopify app built with them.

> **This folder is self-contained and optional.**
> App developers using the pipeline don't need it. To remove it entirely:
> `rm -rf "Skill Testing Framework"` — nothing in `.claude/` depends on it.

---

## What's in here

```
Skill Testing Framework/
├── README.md              ← you are here
├── CLAUDE.md              ← tells Claude how to use this framework
├── catalog.yaml           ← master registry: all 67 skills + 31 agents, coverage tracking
├── quality-rubric.md      ← category-specific pass/fail metrics for /skill-test category
│
├── skills/                ← behavioral spec files for skills (one per skill)
│   ├── gate/              ← gate category specs
│   ├── review/            ← review category specs
│   ├── readiness/         ← readiness category specs
│   ├── authoring/         ← authoring category specs
│   ├── pipeline/          ← pipeline category specs
│   ├── analysis/          ← analysis category specs
│   ├── sprint/            ← sprint category specs
│   └── utility/           ← utility category specs
│
├── agents/                ← behavioral spec files for agents (one per agent)
│   ├── directors/         ← product-director, technical-director, producer
│   ├── leads/             ← lead-engineer, ux-lead, api-lead, app-architect, growth-lead
│   ├── specialists/       ← graphql, webhooks, billing, auth, App Bridge, Liquid, checkout, …
│   ├── qa/                ← qa-lead, qa-tester, security-specialist, accessibility-specialist
│   └── operations/        ← release-manager, devops-engineer, analytics-engineer, …
│
├── templates/             ← spec file templates for writing new specs
│   ├── skill-test-spec.md ← template for skill behavioral specs
│   └── agent-test-spec.md ← template for agent behavioral specs
│
└── results/               ← test run outputs (written by /skill-test spec, gitignored)
```

---

## How to use it

All testing is driven by two skills already in the framework:

### Check structural compliance

```
/skill-test static [skill-name]     # Check one skill (7 checks)
/skill-test static all              # Check all 67 skills
```

### Run a behavioral spec test

```
/skill-test spec gate-check         # Evaluate a skill against its written spec
/skill-test spec code-review
```

### Check against category rubric

```
/skill-test category gate-check     # Evaluate one skill against its category metrics
/skill-test category all            # Run rubric checks across all categorized skills
```

### See full coverage picture

```
/skill-test audit                   # Skills + agents: has-spec, last tested, result
```

### Improve a failing skill

```
/skill-improve code-review          # Test → diagnose → propose fix → retest loop
```

---

## Skill categories

| Category | Skills | Key metrics |
|----------|--------|-------------|
| `gate` | gate-check | Reads `approvals.json` + `status.md`, gate order, READY / NOT READY / BLOCKED, no stage change without approval |
| `review` | design-review, architecture-review, prototype-review | Read-only, per-criterion verdicts, no silent writes |
| `readiness` | story-readiness, story-done, app-store-checklist | Blockers surfaced, three verdict levels, gate record respected |
| `authoring` | create-architecture, architecture-decision, ux-design, ux-review, quick-design, mmmvp-proposals, propose-updates, update-request | Section-by-section May-I-write, skeleton-first, correct approver |
| `pipeline` | create-epics, create-stories, dev-story, create-control-manifest, create-test-store, deploy-to-test-store, build-prototype, scaffold, release | Upstream dependency check, correct schema, approval before write |
| `analysis` | code-review, consistency-check, scope-check, security-audit, perf-profile, tech-debt, estimate, test-flakiness, test-evidence-review, research, update-research | Read-only scan, findings table with file:line, no gates |
| `sprint` | sprint-plan, sprint-status, milestone-review, retrospective, changelog, patch-notes | Reads `production/`, release state respected, no auto-commit |
| `utility` | start, onboard, adopt, help, brainstorm, bug-report, bug-triage, localize, qa-plan, regression-suite, smoke-check, soak-test, test-setup, test-helpers, skill-test, skill-improve, feature-request, apply-updates, hotfix, kanban-status, launch-checklist, release-checklist, prototype, reverse-document, project-stage-detect | Passes the 7 static checks |

---

## Agent groups

Groups mirror the spec directories under `agents/` and the roster tiers in
`.claude/docs/agent-roster.md`.

| Group | Agents |
|-------|--------|
| `directors` | product-director, technical-director, producer |
| `leads` | lead-engineer, ux-lead, api-lead, app-architect, growth-lead |
| `specialists` | graphql-specialist, webhooks-specialist, billing-specialist, auth-specialist, app-bridge-specialist, liquid-specialist, checkout-specialist, tools-engineer, polaris-specialist, performance-analyst, research-specialist, prototype-builder |
| `qa` | qa-lead, qa-tester, security-specialist, accessibility-specialist |
| `operations` | release-manager, devops-engineer, analytics-engineer, localization-lead, app-store-reviewer, test-store-manager, community-manager |

---

## Updating the catalog

`catalog.yaml` tracks test coverage for every skill and agent. After running a test:

- `/skill-test spec [name]` will offer to update `last_spec` and `last_spec_result`
- `/skill-test category [name]` will offer to update `last_category` and `last_category_result`
- `last_static` and `last_static_result` are updated manually or via `/skill-improve`

A skill that has no behavioral spec keeps its row in the catalog with
`intentionally_untested: <reason>` instead of a `spec:` path, so `/skill-test audit`
reports it as a deliberate gap rather than an omission.

---

## Writing a new spec

1. Find the spec template at `templates/skill-test-spec.md`
2. Copy it to `skills/[category]/[skill-name].md`
3. Update the `spec:` field in `catalog.yaml` to point to the new file
4. Run `/skill-test spec [skill-name]` to validate it

---

## Removing this framework

This folder has no hooks into the main project. To remove:

```bash
rm -rf "Skill Testing Framework"
```

The skills `/skill-test` and `/skill-improve` will still function — they'll simply
report that `catalog.yaml` is missing and suggest running `/skill-test audit` to
initialize it.
