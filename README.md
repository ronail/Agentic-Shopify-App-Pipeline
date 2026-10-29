# Agentic Shopify App Pipeline

AI-driven research, development, release and review pipeline for Shopify apps.
Built for solo founders who want pipeline-level structure without the headcount.

<p>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License"></a>
  <a href="https://shopify.dev/docs/api/admin-graphql"><img src="https://img.shields.io/badge/Shopify-GraphQL%20Admin%20API-95BF47?logo=shopify&logoColor=white" alt="Shopify GraphQL Admin API"></a>
  <a href="https://docs.anthropic.com/en/docs/claude-code"><img src="https://img.shields.io/badge/Claude%20Code-supported-f5f5f5?logo=anthropic" alt="Claude Code supported"></a>
  <a href="https://developers.openai.com/codex/cli"><img src="https://img.shields.io/badge/Codex-supported-412991?logo=openai&logoColor=white" alt="Codex supported"></a>
</p>

<!-- TEMPLATE-ONLY:START -->
## Use This Template

This repo is a **GitHub template** for solo founders building Shopify apps. It
ships the full pipeline *plus* two worked-example apps, their architecture
records and worked session transcripts — so you can read a finished slice of the
pipeline before you start your own.

**→ [Use this template](https://github.com/ronail/Agentic-Shopify-App-Pipeline/generate)**

Then initialise your new repo once:

```bash
scripts/init-template.sh --name "Acme Bundles" --app acme-bundles            # preview
scripts/init-template.sh --name "Acme Bundles" --app acme-bundles --apply    # apply
```

It strips the worked examples (both demo apps and their ADRs/requirements/sprint
state, `docs/examples/`, `docs/legacy/`, `docs/superpowers/`, `TASKS.md`,
`IDEA.md`, `request*.md`, `Skill Testing Framework/`), resets the registries, retitles the
project, optionally seeds `apps/<slug>/`, runs the repository checks, and
deletes itself. It refuses to run while `origin` points at the template repo, so
this repository can never be stripped by accident.

Full contract: [TEMPLATE.md](TEMPLATE.md).
<!-- TEMPLATE-ONLY:END -->

## Why This Exists

Shipping a Shopify app solo is mostly process work: validating that a merchant
problem is worth solving, scaffolding an embedded admin app, keeping the Admin
API version current, passing App Store review, and not quietly breaking a live
merchant's store on a Friday.

A single chat session does none of that on its own. **Agentic Shopify App
Pipeline** gives the session the structure of a pipeline: a roster of specialised
agents with defined domains and escalation paths, a fixed pipeline from research
to post-launch monitoring, and quality gates that block a stage until its
evidence exists.

You still make every decision. The agents provide structure, specialised review,
and a paper trail.

## Pipeline Stages

| Stage | What happens | Gate before exit |
|-------|--------------|------------------|
| **Research** | Validate the merchant problem, map competing apps, size the wedge | `request.md` written and accepted |
| **Scaffold** | Create `apps/<app-name>/` with TypeScript, React + Polaris, App Bridge, pinned Admin API version, Vitest | App boots in a dev store via Shopify CLI |
| **Plan** | Epics, stories, acceptance criteria, per-app requirements registry | Stories pass readiness check |
| **Build** | Implement against the pinned API snapshot, tests beside source | Tests pass, requirements traced |
| **Review** | Code, security (OAuth, scopes, webhooks, token handling), merchant UX | Blocking findings closed |
| **Ship** | App Store checklist, listing copy, versioned release | Submission checklist complete |
| **Monitor** | Install funnel, error rates, API cost limits, review responses | Post-launch review logged |

Each stage has skills that read and write the pipeline state, so a later stage
knows what an earlier one decided without re-deriving it.

## How to Start

```bash
git clone https://github.com/ronail/Agentic-Shopify-App-Pipeline.git my-app-pipeline
cd my-app-pipeline
```

Open your harness and run `/start`:

```bash
claude      # Claude Code
codex       # Codex  -> /start codex
hermes      # Hermes -> /start hermes
```

`/start` asks where you are — no idea yet, a rough app idea, a written spec, or
an existing app — and routes you to the matching skill. It does not assume.

If you already know what you need:

- `/research` — original vs. competitor-killer research for a merchant problem
- `/scaffold --app <name>` — create the app skeleton
- `/project-stage-detect` — analyse an existing app and report its stage
- `/kanban-status` — see where every app in the repo stands

## What's In Here

| Layer | Location | Purpose |
|-------|----------|---------|
| Agents | `.claude/agents/` | Specialised roles with domain boundaries and escalation paths |
| Skills | `.claude/skills/` | Slash commands for every pipeline stage |
| Hooks | `.claude/hooks/` | Commit, push, and session/skill validation |
| Rules | `.claude/rules/` | Path-scoped standards enforced while editing |
| Templates | `.claude/docs/templates/` | Requirements, ADRs, UX specs, test evidence, release checklists |
| Scripts | `scripts/` | Template initialisation (`init-template.sh`) and repository checks |

The full role list, tier by tier, is in
[`.claude/docs/agent-roster.md`](.claude/docs/agent-roster.md). Agents are
Claude Code subagents; the same definitions drive Codex and Hermes.

## Project Structure

```
CLAUDE.md                     # Master configuration
AGENTS.md                     # Codex spawn rules and model-tier mapping
TEMPLATE.md                   # Template contract (deleted on initialisation)
.claude/                      # Agents, skills, hooks, rules, docs, settings
.codex/                       # Codex approvals, model mapping, hook wiring
scripts/                      # init-template.sh and repository checks
apps/<app-name>/              # Per-app code: admin UI, server, extensions, tests
src/                          # Shared libraries used across apps
design/                       # UX specs, API contracts, design notes
docs/                         # Process docs, per-app ADRs, API snapshots
production/                   # Sprints, milestones, kanban state, session state
```

## Harness Support

Claude Code is the primary runtime: agents, skills, hooks and rules live in
`.claude/` and are read natively.

- **Codex** — `.codex/config.toml` sets approval policy and sandbox mode;
  `.codex/agent-models.toml` maps the shared `haiku` / `sonnet` / `opus` tiers to
  GPT models. Regenerate compatibility files after editing a skill or role:
  `python3 .codex/generate_compat.py`
- **Hermes** — resolves subagent models per profile rather than per project.
  `/start hermes` writes a paste-ready routing plan into `production/`.

The agents themselves are harness-neutral markdown with YAML frontmatter. Any
harness that can spawn a subagent with a system prompt can run them.

## Contributing

Bug fixes, new skills that close a real workflow gap, and corrections to
existing agents are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) and
[SECURITY.md](SECURITY.md). Do not open a PR that adds your own app's output —
this repo is the pipeline, not the apps built with it.

## Attribution

This pipeline is a permanent fork of two MIT-licensed projects, in derivation
order:

1. [Donchitos/Claude-Code-Game-Studios](https://github.com/Donchitos/Claude-Code-Game-Studios) — the original studio-agent architecture, agent tiering, collaboration protocol, and skill conventions.
2. [ronail/Agent-Harness-Game-Studios](https://github.com/ronail/Agent-Harness-Game-Studios) — the harness-portability work (Codex and Hermes adapters, hook and rule layers) that this repo started from.

The upstream framework targeted game development. This repo keeps its
structure — tiers, gates, request-to-ship pipeline — and retargets every role
and skill at Shopify app work. The divergence record lives in this repository's
git history.

## License

MIT License. See [LICENSE](LICENSE) for details. Both upstream copyright
notices are retained.
