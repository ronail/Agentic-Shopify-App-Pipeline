# Contributing to Agentic Shopify App Pipeline

This repo is a coordination framework for building Shopify apps with an AI
coding harness. Contributions are welcome — bug fixes, new skills that fill a
real gap, agent improvements, and hook fixes. PRs that don't fit the framework's
direction will be closed without lengthy explanation.

## What Makes a Good PR

- **Bug fixes** — something is broken, here's the fix
- **New skills** that address a workflow gap not already covered
- **Improvements** to existing agents, skills, or hooks
- **Documentation corrections** — wrong info, broken references, outdated steps

Feature requests submitted as PRs will be closed. Open an issue instead.

**What this repo isn't:**
This repo is the pipeline that helps you build and ship Shopify apps — not a
place to store the apps you build with it. App source, merchant-specific
requirements, ADRs, UX specs, listing copy, or any other output generated for
your own product won't be merged here — keep those in your own repo.

## The Non-Negotiable Technical Rules

These are the things that will get your PR rejected if you miss them.

**Skill files**
- Skills live in `.claude/skills/<name>/SKILL.md` — the subdirectory format is
  required. Flat `.md` files are silently ignored by Claude Code.
- SKILL.md must include YAML frontmatter: `name`, `description`,
  `argument-hint`, `allowed-tools`, and `model`
- Model tier: `haiku` for read-only status checks, `opus` for multi-document
  synthesis and phase gates, `sonnet` for everything else

> **Hermes Model Routing (optional)**: When using Hermes as the harness, the
> `model` tier field in agent/skill frontmatter is advisory only. Subagent models
> come from the `delegation` section of the active Hermes profile
> (`~/.hermes/profiles/<name>/config.yaml`), and `delegation.backend` picks the
> mode — `default`, or `model_map` / `profile_routes` from the official
> `advanced-delegation` plugin. Run `/start hermes` during onboarding to set up
> the routing.

**Hooks**
- Use `grep -E` — never `grep -P` (Perl regex breaks on Windows Git Bash)
- Include fallbacks for systems without `jq` or `python` installed
- Hooks run on every session start — they must exit quickly and gracefully
  (`exit 0`) when not applicable

**Agents**
- New agents must include a **Collaboration Protocol** section that describes
  how the agent asks questions and defers decisions to the user
- Agents must not modify files outside their documented domain without explicit
  user delegation
- Agent domains follow the pipeline layers: product, architecture, API surface,
  admin UI, billing, auth, webhooks, extensions, QA, release, operations

**Reference docs**
- If your PR adds or changes a skill, agent, or hook, update the matching
  reference doc (agent-roster, skills-reference, hooks-reference, or
  rules-reference). PRs that add things without updating the index will be
  sent back.

## The Collaborative Principle

This pipeline is not an autonomous system. Every workflow follows:
**Question → Options → Decision → Draft → Approval → Write**

Skills and agents must ask before acting. Nothing writes to files without
explicit user confirmation. If your contribution has an agent making decisions
or writing files unilaterally, it won't be merged.

## Testing Your Changes

Run it in a Claude Code session and confirm it works end-to-end. For skills,
invoke the skill and verify the output matches what the skill claims to do.
For hooks, trigger the relevant event and confirm the hook fires correctly
and exits cleanly.

For anything that touches app scaffolding or the Admin API surface, also run it
against a development store with `shopify app dev` and confirm the app boots,
authenticates, and registers its webhooks.

Include a brief note in your PR description describing what you tested and
what the output looked like.

## Commit Format

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add /app-store-checklist skill for submission readiness
fix: correct grep -P usage in session-start hook
docs: update skills-reference with new /scaffold entry
```

Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`

## PR Process

- **Use the PR template** — start from `.github/PULL_REQUEST_TEMPLATE.md` and
  retain every heading, checkbox, and section in the final PR body. Fill in
  the template instead of replacing it with a custom summary. Mark checklist
  items accurately and include the actual verification performed.
- Your PR will be auto-assigned to the maintainer via CODEOWNERS
- Reviews happen when they happen — this is a solo-maintained project
- If your PR sits open without feedback for a few weeks, a nudge comment is fine
- Merged contributors are credited in release notes

## Upstream Relationship

This repo diverged permanently from its upstream at a fixed commit and does not
merge upstream changes; see [`docs/legacy/DIVERGENCE.md`](docs/legacy/DIVERGENCE.md)
before proposing anything upstream-shaped. Fixes that matter are re-expressed for
Shopify and applied by hand.

## Platform Compatibility

The framework must work on Windows (Git Bash), macOS, and Linux. If your hook or
script uses anything platform-specific, it will be rejected. When in doubt,
test on Windows.
