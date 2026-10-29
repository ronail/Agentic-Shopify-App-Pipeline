# Skill Testing Framework — Claude Instructions

This folder is the quality assurance layer for the Agentic Shopify App Pipeline
skill/agent framework. It is self-contained and separate from any app under `apps/`.

## Key files

| File | Purpose |
|------|---------|
| `catalog.yaml` | Master registry for all 66 skills and 31 agents. Contains category, group, spec path and last-test tracking fields. Always read this first when running any test command. |
| `quality-rubric.md` | Category-specific pass/fail metrics. Read the matching `###` section for the skill's category when running `/skill-test category`. |
| `skills/[category]/[name].md` | Behavioral spec for a skill — 5 test cases + protocol compliance assertions. |
| `agents/[group]/[name].md` | Behavioral spec for an agent — 5 test cases + protocol compliance assertions. |
| `templates/skill-test-spec.md` | Template for writing new skill spec files. |
| `templates/agent-test-spec.md` | Template for writing new agent spec files. |
| `results/` | Written by `/skill-test spec` when results are saved. Gitignored. |

## Path conventions

- Skill specs: `Skill Testing Framework/skills/[category]/[name].md`
- Agent specs: `Skill Testing Framework/agents/[group]/[name].md`
- Catalog: `Skill Testing Framework/catalog.yaml`
- Rubric: `Skill Testing Framework/quality-rubric.md`

The `spec:` field in `catalog.yaml` is the authoritative path for each skill/agent spec.
Always read it rather than guessing the path.

## Skill categories (66 skills)

```
gate        → gate-check
review      → architecture-review, design-review, prototype-review
authoring   → architecture-decision, create-architecture, mmmvp-proposals,
              propose-updates, quick-design, update-request, ux-design, ux-review
readiness   → app-store-checklist, story-done, story-readiness
pipeline    → build-prototype, create-control-manifest, create-epics,
              create-stories, create-test-store, deploy-to-test-store, dev-story,
              release, scaffold
analysis    → code-review, consistency-check, estimate, perf-profile, research,
              scope-check, security-audit, tech-debt, test-evidence-review,
              test-flakiness, update-research
sprint      → changelog, milestone-review, patch-notes, retrospective,
              sprint-plan, sprint-status
utility     → adopt, apply-updates, brainstorm, bug-report, bug-triage,
              feature-request, help, hotfix, kanban-status, launch-checklist,
              localize, onboard, project-stage-detect, prototype, qa-plan,
              regression-suite, release-checklist, reverse-document, skill-improve,
              skill-test, smoke-check, soak-test, start, test-helpers, test-setup
```

## Agent groups (31 agents)

```
directors   → product-director, technical-director, producer
leads       → app-architect, api-lead, growth-lead, lead-engineer, ux-lead
specialists → app-bridge-specialist, auth-specialist, billing-specialist,
              checkout-specialist, graphql-specialist, liquid-specialist,
              performance-analyst, polaris-specialist, prototype-builder,
              research-specialist, tools-engineer, webhooks-specialist
operations  → analytics-engineer, app-store-reviewer, community-manager,
              devops-engineer, localization-lead, release-manager,
              test-store-manager
qa          → accessibility-specialist, qa-lead, qa-tester, security-specialist
```

## Workflow for testing a skill

1. Read `catalog.yaml` to get the skill's `spec:` path and `category:`
2. Read the skill at `.claude/skills/[name]/SKILL.md`
3. Read the spec at the `spec:` path
4. Evaluate assertions case by case
5. Offer to write results to `results/` and update `catalog.yaml`

## Workflow for improving a skill

Use `/skill-improve [name]`. It handles the full loop:
test → diagnose → propose fix → rewrite → retest → keep or revert.

## Spec validity note

Specs in this folder describe **current behavior**, not ideal behavior. They were
written by reading the skills, so they may encode bugs. When a skill misbehaves in
practice, correct the skill first, then update the spec to match the fixed behavior.
Treat spec failures as "this needs investigation," not "the skill is definitively wrong."

## This folder is deletable

Nothing in `.claude/` imports from here. Deleting this folder has no effect on the
skills or agents themselves. `/skill-test` and `/skill-improve` will report that
`catalog.yaml` is missing and guide the user to initialize it.
