# Repo Template Mode — Design Spec (rev. 2)

**Date:** 2026-10-30
**Status:** Design approved; rev. 2 incorporates the owner's correction
**Repo:** `ronail/Agentic-Shopify-App-Pipeline`

## 1. Intent

Make this repository a **GitHub template repository** whose sanitisation happens
**at generation time, in the generated repo** — never here.

This repo is a living reference implementation: two demo apps, worked session
transcripts, the retarget log, the Skill Testing Framework. All of it stays.
A person who clicks "Use this template" gets the same tree, then runs one
script that strips it down to a clean starting point for *their* project.

Success is: generate → `scripts/init-template.sh --name … --app …` → `/start` →
a working pipeline with empty registries, no demo state, and every internal
consistency check green — while `main` in this repo still carries all examples.

Non-goals: domain generalisation; CI; **any deletion from this repo**.

## 2. Measured baseline

| Fact | Value |
|---|---|
| Agents / skills | 31 / 66 |
| `check-references.py` | `OK: 31 agents, 66 skills, 0 broken references` |
| `isolation-check.py` | `ISOLATION OK — 2 apps (discount-bundles, order-tags)` |
| Template-only payload (stripped at generation, kept here) | `apps/{discount-bundles,order-tags}`, `docs/architecture/apps/`, `production/apps/`, `docs/examples/`, `docs/legacy/`, `TASKS.md`, `request.md`, `request-history.md`, `Skill Testing Framework/` |
| Game-fork residue (defects, not content) | `design/CLAUDE.md`, `design/registry/entities.yaml`, `.claude/statusline.sh` |

## 3. In-repo changes — corrective or additive only

No file listed in the "template-only payload" row above is modified or removed
by this work.

### 3.1 Game-fork residue (defect fixes)

| File | Current state | Fix |
|---|---|---|
| `design/CLAUDE.md` | GDD files, "Player Fantasy", `design/gdd/`, `/design-system` | Shopify design standards: `design/ux/` screen specs, `design/quick-specs/`, API contracts, interaction patterns; validated by `/ux-review`, `/design-review` |
| `design/registry/entities.yaml` | "Game World Entity Registry", `goblin` examples | Design Entity Registry for cross-doc UX/API facts; empty, Shopify-flavoured header comments |
| `.claude/statusline.sh` | Title "Agent Harness Game Studios"; reads `design/gdd/game-concept.md`, `systems-index.md` | Retitle; read real signals — app count/stage from `docs/registry/apps.json`, `request.md` presence, branch |

### 3.2 Neutral placeholders in framework docs

Framework docs naming `discount-bundles` / `order-tags` would dangle in a
generated repo. Replace with `<app>` (prose) / `my-app` (runnable examples) in:

- `docs/WORKFLOW-GUIDE.md`, `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md`,
  `docs/architecture/README.md`, `docs/architecture/ADR-0001-admin-api-version-policy.md`
- `.claude/skills/`: `start`, `scaffold`, `adopt`, `kanban-status`,
  `project-stage-detect`, `tech-debt`, `update-request`, `consistency-check`
- `.claude/hooks/`: `approval-gate.sh`, `app-store-gate.sh`, `pre-compact.sh`,
  `session-start.sh`, `detect-gaps.sh` — comments and usage examples only;
  behaviour stays glob/arg-driven
- `.claude/docs/`: `agent-memory-setup.md`, `hooks-reference/approval-gate.md`,
  `hooks-reference/app-store-gate.md`

Files stripped at generation (`docs/examples/session-*.md`, `TASKS.md`,
`docs/legacy/`) keep their concrete app names — they are historical documents
and they leave with the demo data.

### 3.3 STF-dependent skills degrade gracefully

`Skill Testing Framework/` stays here and is stripped at generation. Rather
than patching skill text inside the script, the skills detect the absence:

- `.claude/skills/skill-test/SKILL.md` — before `category` or `audit` mode:
  if `Skill Testing Framework/catalog.yaml` is absent, print
  "Skill Testing Framework not installed; `static` and `spec` available" and
  stop. `static` and `spec` remain unchanged and self-contained.
- `.claude/skills/skill-improve/SKILL.md` — Phase 2b category baseline: if the
  catalog is absent, skip with the same notice and continue on static results.

No mode is deleted in either skill.

### 3.4 Docs for the generated-repo flow

- `.claude/docs/directory-structure.md` — add `scripts/`, `TEMPLATE.md`; note
  `apps/` is empty in a generated repo
- `.claude/docs/quick-start.md`, `.claude/docs/setup-requirements.md` — insert
  the generation flow ahead of `/start`
- `.claude/docs/skills-reference.md` — add `/setup`
- `.claude/docs/workflow-catalog.yaml` — add `setup` entry
- `README.md` — "Use this template" section between
  `<!-- TEMPLATE-ONLY:START -->` / `<!-- TEMPLATE-ONLY:END -->`, plus a note
  that `apps/discount-bundles` and `apps/order-tags` are worked examples the
  init script removes
- `TEMPLATE.md` — new (section 6)
- `.codex/generate_compat.py` — run after edits; commit regenerated files

## 4. `scripts/init-template.sh` — the sanitizer

POSIX bash + `git`; `python3` only to invoke the existing checkers.

```
Usage: scripts/init-template.sh [options]

  --name <project-name>   Display name for README/CLAUDE.md (required with --apply)
  --description <text>    One-line description (optional)
  --app <slug>            Optional first app slug (lowercase kebab)
  --apply                 Actually mutate (without it: report only)
  --yes                   Skip the interactive confirmation
  --force                 Allow a dirty tree or a template-origin remote
  --skip-checks           Skip check-references.py / isolation-check.py
```

### 4.1 Guards, in order

1. `.claude/agents/` and `TEMPLATE.md` must both exist, else exit 1 (not
   template mode).
2. If `git remote get-url origin` matches `Agentic-Shopify-App-Pipeline`,
   refuse unless `--force`. **This is what stops the script from sanitising
   this repo.**
3. Refuse a dirty tree (`git status --porcelain`) unless `--force`.
4. Validate `--name` (non-empty, no newlines) and `--app` (`^[a-z][a-z0-9-]*$`).
5. Without `--apply`: print every planned action prefixed `would`, exit 0.

### 4.2 Mutation order

| # | Action |
|---|---|
| 1 | Confirm (unless `--yes`): print the strip list, require `yes` |
| 2 | Rewrite the first `# …` heading of `README.md` and `CLAUDE.md` to `# <name>`; replace the README tagline when `--description` given |
| 3 | Delete demo state: every `apps/*/` directory, `docs/architecture/apps/`, `production/apps/` |
| 4 | Delete this project's history: `docs/examples/`, `docs/legacy/`, `TASKS.md`, `request.md`, `request-history.md`, `production/session-logs/*` |
| 5 | Delete `Skill Testing Framework/` (skills degrade per 3.3) |
| 6 | Reset registries: `docs/registry/apps.json` → `{"apps": []}`; `docs/registry/architecture.yaml` → pins/stances kept, `apps:` empty; `design/registry/entities.yaml` → empty registry |
| 7 | If `--app`: create `apps/<slug>/{README.md,status.md,approvals.json,prototype/.gitkeep}`, `production/apps/<slug>/{sprints,milestones,session-state}/.gitkeep`, and register it at `stage: research`, `last_approved_gate: null` |
| 8 | Strip the `TEMPLATE-ONLY` region of `README.md`; delete `TEMPLATE.md` and `scripts/init-template.sh` |
| 9 | Run both checkers; print results; exit non-zero on failure unless `--skip-checks` |
| 10 | Print next steps: write `request.md` (or let `/start` prompt), then `/start` |

Every mutation prints the path touched. Steps 3–6 are idempotent.

## 5. `.claude/skills/setup/SKILL.md`

`/setup` — in-harness wrapper, state-aware:

1. `TEMPLATE.md` present → template mode: run the script without `--apply`,
   show the plan, collect `--name` / `--description` / `--app` conversationally,
   ask approval, then run with `--apply --yes`.
2. `TEMPLATE.md` absent → initialised mode: run both checkers, report drift,
   propose repairs, never rewrite without approval.
3. Hand off to `/start`.

Frontmatter follows repo convention: `name`, `description`, `argument-hint`,
`user-invocable: true`, `allowed-tools: Read, Glob, Grep, Write, Bash,
AskUserQuestion, request_user_input, clarify`, `model: sonnet`.

## 6. `TEMPLATE.md`

Ships in the template, deleted by step 8 of the script:

- what the template ships, and which parts are worked examples
- the exact strip list
- dry-run-first workflow and the template-origin guard
- how to pull framework updates later (`git remote add upstream`, cherry-pick)
- known limitation: strip-once; re-running is refused because `TEMPLATE.md` is
  gone — re-sanitising a hand-initialised repo is out of scope

## 7. GitHub settings

- `PATCH /repos/ronail/Agentic-Shopify-App-Pipeline` with `is_template: true`
- Topics: `shopify`, `shopify-apps`, `agentic-ai`, `claude-code`, `codex`,
  `hermes`, `app-pipeline`, `template`
- Description mentions it is a template
- Verified with `gh api … --jq '.is_template'` → `true`
- Applied **after** the branch merges, since the flag changes what `main` offers

## 8. Verification

### 8.1 This repo — proof nothing was removed

| Check | Pass condition |
|---|---|
| `git diff --stat main` | no deletions of tracked files; only additions and the modified files in 3.1–3.4 |
| Demo apps, `TASKS.md`, `docs/legacy/`, `docs/examples/session-*.md`, `request.md`, `Skill Testing Framework/` | all present |
| `python3 .claude/scripts/check-references.py` | `0 broken references` |
| `python3 .claude/scripts/isolation-check.py` | `ISOLATION OK — 2 apps` |
| Hook smoke | `session-start`, `detect-gaps`, `pre-compact`, `post-compact`, `approval-gate`, `app-store-gate` all exit 0 |

### 8.2 Generated repo — rehearsal in a scratch copy

1. Copy the tree to the scratch dir.
2. `scripts/init-template.sh --name "Acme Bundles" --app acme-bundles` → prints
   the plan, mutates nothing (`--apply` absent).
3. Same with `--apply --yes` → strip list gone; `apps/acme-bundles/` and its
   registry entry exist; README retitled; `TEMPLATE.md`, the script, and the
   `TEMPLATE-ONLY` region gone.
4. Both checkers run **in the generated copy** → green, reporting one app
   (`acme-bundles`).
5. `git grep -nE 'discount-bundles|order-tags|Skill Testing Framework|docs/legacy|TASKS\.md'`
   → no hits.
6. `Skill Testing Framework` absent, so the skill-test guard path is exercised
   (mode refuses with the notice rather than erroring).

### 8.3 Safety guards

- `--apply` inside this repo's clone without `--force` → refuses
  (template-origin remote).
- Dirty tree → refuses.
- Directory without `TEMPLATE.md` → refuses.

### 8.4 Repo-wide

- Game residue: `git grep -niE '\bGDD\b|player fantasy|game studio|game-concept|godot|unity'`
  → no hits, `TASKS.md` and `docs/legacy/` exempt (historical, and they leave
  with the demo data)
- Dead relative links in `README.md` + `docs/**/*.md` → 0
- `python3 .codex/generate_compat.py` → clean regenerated tree

## 9. Risks

- **Keeping the demo apps means every generated repo inherits them** until the
  script runs. Mitigated by a prominent README step, `TEMPLATE.md`, and the
  guard set.
- **The script is the only barrier between a consumer and demo data.** Hence:
  dry-run by default, template-origin refusal, confirmation prompt, and the
  8.2/8.3 rehearsals.
- **Skill degradation paths** must be exercised (8.2.6) or generated repos get
  misleading `/skill-test` output.
- **Strip-once:** the script deletes itself, so a repo initialised another way
  cannot be re-sanitised by it.

## 10. Out of scope

- Deleting anything from this repo.
- CI workflows, history rewrite, repo rename.
- Domain generalisation; removing `docs/shopify-api-reference/`.
- Re-running init on an already-initialised repo.

## 11. Delivery

- Branch `feat/template-mode` (exists; rev. 1 of this spec is committed there).
- Conventional commits per task, not batched: `docs(template)`,
  `fix(design)`, `fix(statusline)`, `refactor(skills)`, `feat(scripts)`,
  `feat(setup)`, `docs(template)`.
- Draft PR #1 updated per commit with `--body-file`; no auto-merge.
- `is_template` applied after merge.
