# Repo Template Mode — Design Spec

**Date:** 2026-10-30
**Status:** Approved for planning (design approved in session)
**Repo:** `ronail/Agentic-Shopify-App-Pipeline`

## 1. Intent

Turn this repository into a **GitHub template repository** that a person can
generate a new repo from and immediately run the pipeline in, without
inheriting this repo's demo apps, retarget build log, or game-fork residue.

Success is: `git clone`/generate → `scripts/init-template.sh --name … --app …`
→ `/start` → a working research/scaffold pipeline, with every internal
consistency check green and zero references to content that no longer exists.

Non-goal: making the framework domain-agnostic. The template stays
Shopify-specific.

## 2. Current state (baseline, measured)

| Fact | Value |
|---|---|
| Agents | 31 |
| Skills | 66 (→ 67 with the new `/setup`) |
| `check-references.py` | `OK: 31 agents, 66 skills, 0 broken references` |
| `isolation-check.py` | prints `ISOLATION OK` |
| Demo project state | `apps/discount-bundles`, `apps/order-tags`, `docs/architecture/apps/*`, `production/apps/*` |
| Retarget artifacts | `TASKS.md` (43 KB), `docs/legacy/` (5 files), `request.md`, `request-history.md` |
| Skill QA harness | `Skill Testing Framework/` (catalog, rubric, 66 specs, 31 agent specs) |
| Game-fork residue | `design/CLAUDE.md` (GDD/Player Fantasy), `design/registry/entities.yaml` (Game World Entity Registry), `.claude/statusline.sh` (title + `design/gdd/game-concept.md`) |

Baseline is green, so any red state after this work is attributable to this
change set.

## 3. Scope

### 3.1 Deletions

| Path | Reason | Disposition |
|---|---|---|
| `apps/discount-bundles/`, `apps/order-tags/` | demo project state | delete; add `apps/.gitkeep` |
| `docs/architecture/apps/` | per-app requirements, control manifests, ADRs | delete; keep `docs/architecture/README.md` and `ADR-0001-admin-api-version-policy.md` |
| `production/apps/` | per-app sprint/milestone/session state | delete; keep `production/.gitkeep`, `production/session-state/.gitkeep` |
| `production/session-logs/*` | session artifacts (already gitignored) | delete local files |
| `docs/examples/session-*.md` (5 files) | session transcripts of the deleted demo apps | delete; rewrite `docs/examples/README.md` to point at `docs/WORKFLOW-GUIDE.md` and state that examples are produced by running the pipeline |
| `docs/legacy/` (5 files) | fork/retarget history | delete |
| `TASKS.md` | retarget build log + AC trace | delete |
| `request.md`, `request-history.md` | this repo's request state; `/start` already prompts when absent | delete |
| `Skill Testing Framework/` | skill QA harness removed by owner | delete whole tree |

`design/registry/entities.yaml` is **rewritten**, not deleted (see 3.3).

### 3.2 Repairs required by the deletions

**Registries reset to their empty, valid shape:**

- `docs/registry/apps.json` → `{"apps": []}`
- `docs/registry/architecture.yaml` → keep `version`, `last_updated`,
  `pinned_admin_api_version`, `api_version_policy`, and the stances section;
  `apps:` becomes an empty map. Header rules/skill wiring stay.
- `design/registry/entities.yaml` → rewritten as a **Design Entity Registry**
  (cross-doc facts for UX/API contracts), empty, Shopify-flavoured examples in
  the header comments only. No game vocabulary.

**Skills that depend on the removed harness:**

- `.claude/skills/skill-test/SKILL.md` — keep `static` and `spec` modes
  (self-contained: they read `.claude/skills/*/SKILL.md` and
  `.claude/docs/templates/skill-test-spec.md`). Remove `category` and `audit`
  modes, all `Skill Testing Framework/…` paths, and update `argument-hint`.
- `.claude/skills/skill-improve/SKILL.md` — replace the Phase 2b
  category-baseline (which reads `Skill Testing Framework/catalog.yaml`) with
  a static-only baseline; remove the STF reference.
- `.claude/hooks/*.sh` — verified by grep to hold no `Skill Testing Framework`
  references, so no hook patch is expected; re-grep after the skill edits.

**Game-fork residue rewritten:**

- `design/CLAUDE.md` → Shopify design-doc standards: `design/ux/` screen specs,
  `design/quick-specs/`, API contracts, interaction patterns; validation via
  `/ux-review` and `/design-review`. No GDD sections, no Player Fantasy, no
  `design/gdd/` or `design/hud` paths.
- `.claude/statusline.sh` → retitle "Agentic Shopify App Pipeline"; replace
  `design/gdd/game-concept.md` / `systems-index.md` reads with the pipeline's
  real signals (`docs/registry/apps.json` app count/stage, `request.md`
  presence, current branch).

**Demo-slug placeholders** — `discount-bundles` / `order-tags` replaced with
`<app>` (docs/prose) or `my-app` (runnable examples) in:

- `docs/WORKFLOW-GUIDE.md`, `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md`,
  `docs/architecture/README.md`,
  `docs/architecture/ADR-0001-admin-api-version-policy.md`
- `.claude/skills/`: `start`, `scaffold`, `adopt`, `kanban-status`,
  `project-stage-detect`, `tech-debt`, `update-request`, `consistency-check`
- `.claude/hooks/`: `approval-gate.sh`, `app-store-gate.sh`, `pre-compact.sh`,
  `session-start.sh`, `detect-gaps.sh` (comments, usage examples, and any
  hard-coded slug list — functional behaviour must stay glob/arg-driven)
- `.claude/docs/`: `agent-memory-setup.md`, `hooks-reference/app-store-gate.md`,
  `hooks-reference/approval-gate.md`

**`docs/legacy` links removed** from `README.md`, `CONTRIBUTING.md`,
`.claude/docs/agent-roster.md`, `.claude/docs/coordination-rules.md`.

**Docs updated for the generated-repo flow:**

- `.claude/docs/directory-structure.md` — `apps/` starts empty; add `scripts/`,
  `TEMPLATE.md` to the map.
- `.claude/docs/setup-requirements.md` — add "generated from template" first-run
  section (init script, then `/setup`, then `/start`).
- `.claude/docs/quick-start.md` — same, and remove the "five steps from
  nothing" duplication if the init script covers it.
- `.claude/docs/skills-reference.md` — add `/setup`, correct `skill-test`
  modes.
- `.claude/docs/workflow-catalog.yaml` — add `setup` entry; remove modes that
  no longer exist.

**Codex compat regenerated** — `python3 .codex/generate_compat.py` after all
skill/agent edits; commit the regenerated `.codex/agents/*.toml` and skill
sidecars.

### 3.3 New artifacts

#### `scripts/init-template.sh`

POSIX bash + `git` (+ `python3` only for the checker invocation). Contract:

```
Usage: scripts/init-template.sh [options]

  --name <project-name>     Repo/project display name (required unless --dry-run)
  --description <text>      One-line description for README/CLAUDE.md
  --app <slug>              Optional first app slug (lowercase kebab)
  --dry-run                 Print the planned actions; write nothing
  --force                   Proceed with a dirty working tree
  --skip-checks             Skip check-references.py / isolation-check.py
```

Steps, in order:

1. Verify it is running inside the template repo (`.claude/agents` +
   `TEMPLATE.md` exist). Refuse otherwise.
2. Refuse when `git status --porcelain` is non-empty, unless `--force`.
3. Validate `--name` and `--app` (kebab-case, no path separators).
4. Rewrite the first `# …` heading of `README.md` and `CLAUDE.md` to
   `# <name>`; replace the README tagline line pairs with `--description`
   (only when provided). Idempotent.
5. Reset registries: `docs/registry/apps.json` → empty, `apps:` map in
   `docs/registry/architecture.yaml` → empty, `design/registry/entities.yaml`
   → empty registry.
6. When `--app` is given, create from the recorded shapes:
   `apps/<slug>/{README.md,status.md,approvals.json,prototype/.gitkeep}` and
   `production/apps/<slug>/{sprints,milestones,session-state}/.gitkeep`, and
   add the registry entry with `stage: research`, no gate approved.
7. Delete template-only content: `TEMPLATE.md`, `scripts/init-template.sh`,
   and the region of `README.md` between `<!-- TEMPLATE-ONLY:START -->` and
   `<!-- TEMPLATE-ONLY:END -->`.
8. Run `python3 .claude/scripts/check-references.py` and
   `python3 .claude/scripts/isolation-check.py`; print both results and exit
   non-zero if either fails (unless `--skip-checks`).
9. Print next steps: edit `request.md` or run `/start`.

Every mutating step prints the path it touches. `--dry-run` prints the same
lines prefixed `would`.

#### `.claude/skills/setup/SKILL.md`

`/setup` — the in-harness wrapper:

1. Detect state: `TEMPLATE.md` present → template mode; absent →
   initialized mode (verify only).
2. Template mode: show the exact changes `scripts/init-template.sh` will make
   (`--dry-run`), ask for approval (Collaboration Protocol), then run it with
   the user's answers as flags.
3. Initialized mode: run both checkers, report drift, propose repairs, do not
   rewrite content without approval.
4. Hand off to `/start`.

Frontmatter matches repo convention: `name`, `description`, `argument-hint`,
`user-invocable: true`, `allowed-tools: Read, Glob, Grep, Write, Bash,
AskUserQuestion, request_user_input, clarify`, `model: sonnet`.

#### `TEMPLATE.md`

The template contract: what ships, what is intentionally empty, what the init
script rewrites/deletes, how to pull framework updates later
(`git remote add upstream`, cherry-pick), and what is out of scope.

#### `README.md`

Add a "Use this template" section (delimited by the `TEMPLATE-ONLY` markers so
the init script strips it) with the generate URL
`https://github.com/ronail/Agentic-Shopify-App-Pipeline/generate` and the
manual clone equivalent. Correct the Project Structure block (`apps/` empty,
`scripts/`, `TEMPLATE.md`).

### 3.4 GitHub repository settings

- `PATCH /repos/ronail/Agentic-Shopify-App-Pipeline` with `is_template: true`
- Topics: `shopify`, `shopify-apps`, `agentic-ai`, `claude-code`, `codex`,
  `hermes`, `app-pipeline`, `template`
- Description updated to mention it is a template.

Verified with `gh api repos/ronail/Agentic-Shopify-App-Pipeline --jq '.is_template'`
→ `true`.

## 4. Verification

All checks are executed, not asserted.

| Check | Command | Pass condition |
|---|---|---|
| Reference integrity | `python3 .claude/scripts/check-references.py` | `0 broken references` |
| App isolation | `python3 .claude/scripts/isolation-check.py` | `ISOLATION OK — 0 apps` |
| Hook smoke (zero apps, no `request.md`) | `bash .claude/hooks/session-start.sh`, `detect-gaps.sh`, `pre-compact.sh`, `post-compact.sh`, `approval-gate.sh`, `app-store-gate.sh` | exit 0, no traceback, no false gate block |
| Residue grep | `git grep -nE 'discount-bundles\|order-tags\|Skill Testing Framework\|docs/legacy\|TASKS\.md'` | no hits |
| Game residue | `git grep -niE '\bGDD\b\|player fantasy\|game studio\|game-concept\|godot\|unity'` | no hits outside `docs/shopify-api-reference` |
| Codex compat | `python3 .codex/generate_compat.py` then `git status` | regenerated files consistent, no stale refs |
| Generated-repo rehearsal | copy tree → scratch → `init-template.sh --name "Acme Bundles" --description "…" --app acme-bundles` | both checkers pass *in the generated repo*; `TEMPLATE.md` and the script are gone; README retitled; `apps/acme-bundles/` + registry entry exist |
| Dead internal links | small python link checker over `README.md` + `docs/**/*.md` | 0 missing relative targets |
| GitHub template flag | `gh api … --jq '.is_template'` | `true` |

## 5. Risks and tradeoffs

- **Worked-session narration is lost.** The 5 `docs/examples/session-*.md`
  transcripts are deleted because they document the deleted apps. The pipeline
  table in `README.md` and `docs/WORKFLOW-GUIDE.md` carry the explanation.
- **`skill-test` loses `category` and `audit`.** Static + spec modes remain and
  are self-contained.
- **Consumers start with no app,** so `/start` is mandatory. Already supported
  (no `request.md` → prompt for idea/request).
- **GitHub template generation copies a snapshot with fresh history,** so the
  repo's own git history is irrelevant to consumers; no history rewrite needed.
- **`.agents/skills` is a symlink** to `.claude/skills`. Template generation
  preserves symlinks; Windows clones may need the link recreated. Out of scope;
  documented in `TEMPLATE.md`.
- **Deleting `docs/legacy/`** removes the record of the fork divergence. The
  upstream relationship is documented in `TEMPLATE.md` instead.

## 6. Out of scope

- Renaming the repository or changing its owner.
- Adding CI workflows.
- Domain-generalization (Shopify → other verticals).
- Removing `docs/shopify-api-reference/` or the pinned 2026-10 API version.
- Rewriting agent bodies beyond the residue fixes listed in 3.2.

## 7. Delivery

- Branch `feat/template-mode` off `main`.
- Conventional commits per task (`chore(template):`, `docs(template):`,
  `refactor(skills):`, `feat(setup):`, `feat(scripts):`), not batched.
- Draft PR opened early with `--body-file`, updated per task, no auto-merge.
