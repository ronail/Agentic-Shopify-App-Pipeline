# AC Trace — project Acceptance Criteria → items

Every criterion in the **Acceptance Criteria** block of `TASKS.md` (P1–P16) and every
`AC-Rn.x` in its R0–R10 sections, each mapped to the concrete item, file or command that
satisfies it. Generated for the R10 gate (AC-R10.4). No row may have an empty mapping cell.

**Count note.** `TASKS.md`'s Acceptance Criteria block contains **15** checkboxes, while
AC-R10.4 calls them 16. P1–P15 map those 15 criteria one-to-one; P16 maps the block-level
gate (the block is never ticked until the R10 smoke test prints `R10-OK`). No criterion was
invented and none is unaccounted for.

**Totals:** 16 project rows + 72 `AC-Rn.x` rows = **88 rows**.

## Project Acceptance Criteria

| # | Area | Criterion | Satisfied by |
|---|---|---|---|
| P1 | Master Request | Exactly one master request | `request.md` — the only non-history `request*.md`; R8 smoke test asserts the count is 1 (AC-R8.1) |
| P2 | Master Request | Can be updated at any time | `.claude/skills/update-request/SKILL.md` — `/update-request`, which requires a reason and appends to history |
| P3 | Master Request | Every update is tracked with history | `request-history.md` written by `.claude/hooks/track-request-changes.sh`; format asserted by AC-R8.2 |
| P4 | Master Request | All research/update loops use the current version | `.claude/skills/research/SKILL.md`, `.claude/skills/update-research/SKILL.md`, `.claude/skills/propose-updates/SKILL.md` each re-read `request.md` per run (R8 bullet: "never a cached copy") |
| P5 | Multi-app from One Request | One master request can produce multiple apps | `.claude/skills/scaffold/SKILL.md` (`/scaffold --app <name>`) × N; registry entries in `docs/registry/apps.json`; seed apps `apps/discount-bundles/`, `apps/order-tags/` |
| P6 | Multi-app from One Request | Apps run in parallel with isolated state | Isolation contract in `.claude/docs/directory-structure.md` (AC-R8.5): per-app dir, own `.env.local`, own kanban, one writer per app dir |
| P7 | Multi-app from One Request | `/start` shows master request + all apps and their stages | `.claude/skills/start/SKILL.md` reading `docs/registry/apps.json` + `apps/*/status.md`; same dashboard from `.claude/hooks/session-start.sh` |
| P8 | Pipeline | Research supports Original + Competitor Killer | `.claude/skills/research/SKILL.md` — two modes, consumes current `request.md` |
| P9 | Pipeline | Ranked MMMVP proposals | `.claude/skills/mmmvp-proposals/SKILL.md` + `.claude/docs/templates/mmmvp-proposal.md` |
| P10 | Pipeline | Prototype + user review | `.claude/skills/build-prototype/SKILL.md`, `.claude/skills/prototype-review/SKILL.md`, agent `.claude/agents/prototype-builder.md`, template `.claude/docs/templates/prototype-review.md` |
| P11 | Pipeline | Epics + Stories + concurrent Kanban | `.claude/skills/create-epics/SKILL.md`, `.claude/skills/create-stories/SKILL.md`, `.claude/skills/dev-story/SKILL.md`, `.claude/skills/kanban-status/SKILL.md`; card format `.claude/docs/templates/kanban-card.md`, per-app boards under `production/apps/<app>/` |
| P12 | Pipeline | Test store per app | `.claude/skills/create-test-store/SKILL.md`, `.claude/skills/deploy-to-test-store/SKILL.md`, agent `.claude/agents/test-store-manager.md`, template `.claude/docs/templates/test-store-plan.md` |
| P13 | Pipeline | Release only after explicit user approval | `.claude/skills/release/SKILL.md` + `.claude/hooks/approval-gate.sh` (gate `gate-4-release` in `apps/<app>/approvals.json`) |
| P14 | Pipeline | Ongoing update loop works | `.claude/skills/update-research/SKILL.md` → `.claude/skills/propose-updates/SKILL.md` → `.claude/skills/apply-updates/SKILL.md` (gate `gate-5-update`) |
| P15 | Pipeline | Human approval gates enforced per app | `.claude/hooks/approval-gate.sh` against `apps/<app>/approvals.json` with the five gate ids; `.claude/docs/director-gates.md` |
| P16 | Acceptance Criteria block | Block level: no project criterion is ticked until the R10 gate prints `R10-OK` | R10 smoke test (`python3 .claude/scripts/check-references.py && test -f docs/legacy/AC-TRACE.md && echo R10-OK`) — the block stays unticked until it prints; note: TASKS.md's block holds **15** checkboxes, AC-R10.4 calls it 16 — this row is the 16th (the block-level gate itself), no criterion was invented |

## R0 — Ratify the target shape (decisions only)

| AC | Criterion | Satisfied by |
|---|---|---|
| R0.1 | `docs/legacy/REFACTOR-DECISIONS.md` exists with ≥5 `##` sections (baseline, roster, skills, directories, Hermes mapping) | `docs/legacy/REFACTOR-DECISIONS.md`; R0 smoke test clause `[ "$(grep -c '^## ' docs/legacy/REFACTOR-DECISIONS.md)" -ge 5 ]` |
| R0.2 | Roster section lists 31 agents (18 rewritten + 13 new), names the 31 deleted, states 49 − 31 = 18 | `docs/legacy/REFACTOR-DECISIONS.md` roster section, cross-checked against `ls .claude/agents/*.md` in R2 |
| R0.3 | Skills section assigns all 75 to Delete/Rewrite/Keep, lists 14 additions (23 + 31 + 21 = 75) | `docs/legacy/REFACTOR-DECISIONS.md` skills section; the kept counts are enforced on disk by `ls -d .claude/skills/*/ \| wc -l` = 66 (AC-R4.1) |
| R0.4 | Directories section states keep/drop for `src`, `design`, `production`, `docs`; `assets`/`prototypes`/`tests`/`tools` marked absent | `docs/legacy/REFACTOR-DECISIONS.md` directories section; `ls -d src design production docs` on disk, absent dirs stay absent |
| R0.5 | `production/hermes-profile-mapping.json` exists and parses as JSON | `production/hermes-profile-mapping.json`; `python3 -m json.tool production/hermes-profile-mapping.json` |
| R0.6 | `# Open` is empty — nothing deferred into R1 | `docs/legacy/REFACTOR-DECISIONS.md` `# Open` heading with no entries below it |
| R0.7 | `git status --porcelain` lists only the two R0 files | R0 smoke test clause `[ "$(git status --porcelain \| wc -l)" -eq 2 ]` run at the R0 commit |

## R1 — Foundation config

| AC | Criterion | Satisfied by |
|---|---|---|
| R1.1 | No engine technology choice in the five config files | R1 smoke test clause `! grep -riE 'godot\|unity\|unreal\|gdscript' CLAUDE.md AGENTS.md README.md docs/CLAUDE.md src/CLAUDE.md` |
| R1.2 | Every `@`-import in `CLAUDE.md` resolves | R1 smoke test loop `grep -oE '^@[^ ]+' CLAUDE.md \| tr -d '@' \| while read -r p; do test -e "$p" ...` |
| R1.3 | `UPGRADING.md` gone; `docs/legacy/DIVERGENCE.md` states the no-upstream-merge rule and divergence SHA | `docs/legacy/DIVERGENCE.md` + `test ! -e UPGRADING.md` (R1 smoke test) |
| R1.4 | `.gitignore` has no engine/binary-asset block; still ignores `.env*`, `.claude/settings.local.json`, `node_modules/` | `.gitignore` (Claude / secret / build blocks retained) |
| R1.5 | `.github/FUNDING.yml` gone, CODEOWNERS has no `settings.json` entry, PR + issue templates intact | `.github/CODEOWNERS`, `.github/PULL_REQUEST_TEMPLATE.md`, `.github/ISSUE_TEMPLATE/*`; absent `.github/FUNDING.yml` |
| R1.6 | `docs/CLAUDE.md` no longer requires a "GDD Requirements Addressed" ADR section or `tr-registry.yaml` | `docs/CLAUDE.md` — replaced by the `docs/shopify-api-reference/` snapshot policy + per-app requirements registry sections |
| R1.7 | `coding-standards.md` and `technical-preferences.md` name the Shopify stack; no `gdscript`/`c#` | `.claude/docs/coding-standards.md`, `.claude/docs/technical-preferences.md`; `grep -iE 'gdscript\|c#'` on both |

## R2 — Agent roster (49 → 31)

| AC | Criterion | Satisfied by |
|---|---|---|
| R2.1 | `ls .claude/agents/*.md` = 31, names match the rewrite table + Add list | `ls .claude/agents/*.md \| wc -l` → 31; name set cross-checked by `.claude/docs/agent-roster.md` and `check-references.py` (d) |
| R2.2 | All 31 deleted agents gone from `.claude/agents` and `.codex/agents` | `.claude/agents/` and `.codex/agents/*.toml` — no deleted role name present (roster vocabulary in `check-references.py`) |
| R2.3 | `.codex/agents/*.toml` = 31 and `generate_compat.py` produces no diff | `ls .codex/agents/*.toml \| wc -l` → 31; `python3 .codex/generate_compat.py && git diff --exit-code .codex/agents` |
| R2.4 | No engine/audio/art/narrative string in any agent body | `grep -rliwE 'godot\|unity\|unreal\|gdscript\|gdd\|battle pass' .claude/agents` returns nothing (R2 smoke test) |
| R2.5 | Every agent has the Collaboration Protocol section | `grep -L 'Collaboration Protocol' .claude/agents/*.md` is empty (R2 smoke test) |
| R2.6 | Every agent frontmatter has a `model:` tier of opus, sonnet or haiku | `grep -L -E '^model: (opus\|sonnet\|haiku)' .claude/agents/*.md` is empty (R2 smoke test) |
| R2.7 | `.claude/docs/agent-roster.md` lists all 31 with owning rule + skill columns, 1:1 with the directory | `.claude/docs/agent-roster.md` tables; `check-references.py` check (d) fails on any roster row without an agent file |

## R3 — Rules layer (11 → 13)

| AC | Criterion | Satisfied by |
|---|---|---|
| R3.1 | `ls .claude/rules/*.md` = 13, matching delete/rewrite/add lists | `ls .claude/rules/*.md \| wc -l` → 13 (R3 smoke test); files: 5 deleted, 6 rewritten, 7 new |
| R3.2 | No rule references a game path | `grep -riE 'src/game\|assets/\|shader\|\bgodot\b\|\bunity\b\|\bunreal\b' .claude/rules` returns nothing (R3 smoke test) |
| R3.3 | Every rule has `paths:` frontmatter whose glob resolves to ≥1 existing file | per-rule `paths:` glob in `.claude/rules/*.md` exercised with `find` against the tree, pasted into the R3 commit |
| R3.4 | `rules-reference.md` has exactly 13 entries, each naming a file that exists | `.claude/docs/rules-reference.md`; R3 smoke test loop `test -f ".claude/rules/$f"` over its entries |
| R3.5 | Each of the 7 new rules has a stated owner among the R2 agents | Owning Rule column in `.claude/docs/agent-roster.md` names each of `admin-embed-code`, `theme-extension-code`, `webhook-code`, `graphql-code`, `billing-code`, `auth-code`, `functions-code` |

## R4 — Skills layer (75 → 66)

| AC | Criterion | Satisfied by |
|---|---|---|
| R4.1 | `ls -d .claude/skills/*/` = 66; 23 deleted absent, 14 new present | `ls -d .claude/skills/*/ \| wc -l` → 66 (R4 smoke test); `research`, `scaffold`, `mmmvp-proposals`, `update-request`, `build-prototype`, `prototype-review`, `kanban-status`, `app-store-checklist`, `create-test-store`, `deploy-to-test-store`, `release`, `update-research`, `propose-updates`, `apply-updates` |
| R4.2 | `.agents/skills` is a symlink resolving to `.claude/skills` | `.agents/skills` → `readlink .agents/skills` = `../.claude/skills`; R4 smoke test `[ -L .agents/skills ] && [ -e .agents/skills ]` |
| R4.3 | No game vocabulary in skill frontmatter/body | `grep -rliwE 'godot\|unity\|unreal\|gdd\|bartle\|mda framework' .claude/skills/*/SKILL.md` returns nothing |
| R4.4 | `skills-reference.md` has 66 entries, each naming an existing directory | `.claude/docs/skills-reference.md`; `check-references.py` uses it as skill vocabulary and fails any name without a directory |
| R4.5 | Every skill named in an agent body exists and every agent named in a skill body exists | `.claude/scripts/check-references.py` checks (a) and (b), exit 0 (R4's arbiter, reused by R10) |
| R4.6 | `/research` and `/scaffold` exist as directories with `SKILL.md` and are in the catalog | `.claude/skills/research/SKILL.md`, `.claude/skills/scaffold/SKILL.md`, listed in `.claude/docs/workflow-catalog.yaml` |
| R4.7 | `/start` runs and shows master request + apps + stages | `.claude/skills/start/SKILL.md`; `/start` invocation recorded in the R4 commit, no error |

## R5 — Templates (37 → 35)

| AC | Criterion | Satisfied by |
|---|---|---|
| R5.1 | `ls .claude/docs/templates/*.md` = 35; 14 deleted absent, 12 new present | `ls .claude/docs/templates/*.md \| wc -l` → 35 (R5 smoke test); new: `master-request`, `request-history`, `mmmvp-proposal`, `app-concept`, `app-prd`, `prototype-review`, `shopify-app-architecture`, `app-store-listing`, `test-store-plan`, `merchant-onboarding`, `pricing-plan`, `kanban-card` |
| R5.2 | `collaborative-protocols/` still exists and is documented as a directory, not a template | `.claude/docs/templates/collaborative-protocols/`; R5 smoke test `test -d .claude/docs/templates/collaborative-protocols` |
| R5.3 | No template requires GDD / MDA / Bartle / engine sections | `grep -rilE 'game design document\|\bmda\b\|bartle\|engine compatibility' .claude/docs/templates` returns nothing (R5 smoke test) |
| R5.4 | Every `.claude/docs/templates/<name>.md` path referenced from a skill body resolves | `.claude/scripts/check-references.py` check (c) (the R10 automation R5 defers to); R5 smoke test MISSING loop |
| R5.5 | Each of the 12 new templates is referenced by at least one skill | `grep -rl <template>.md .claude/skills/*/SKILL.md` for each new template, e.g. `app-prd.md` → `.claude/skills/research/SKILL.md` |

## R6 — Hooks (12 → 15)

| AC | Criterion | Satisfied by |
|---|---|---|
| R6.1 | `ls .claude/hooks/*.sh` = 15 and each is named in `hooks-reference.md` | `ls .claude/hooks/*.sh \| wc -l` → 15; `.claude/docs/hooks-reference.md` + `.claude/docs/hooks-reference/` |
| R6.2 | `bash -n` clean on all 15 | `bash -n` over every `.claude/hooks/*.sh`, run verbatim in the R6 smoke test |
| R6.3 | `.claude/settings.json` and `.codex/hooks.json` parse and register the full set | `python3 -m json.tool .claude/settings.json`, `python3 -m json.tool .codex/hooks.json`; same set shipped as `production/hermes-hooks.yaml` |
| R6.4 | Three new hooks exist and are bash-executable | `.claude/hooks/track-request-changes.sh`, `.claude/hooks/approval-gate.sh`, `.claude/hooks/app-store-gate.sh` |
| R6.5 | No hook references a game path | `grep -riE 'src/game\|assets/\|\bgodot\b\|\bunity\b\|\bunreal\b' .claude/hooks .codex/hooks` returns nothing (R6 smoke test) |
| R6.6 | `approval-gate.sh` and `app-store-gate.sh` each exited non-zero by name against a failing fixture | `bash .claude/hooks/approval-gate.sh <app-without-gate-4>` and `bash .claude/hooks/app-store-gate.sh <app-with-failing-checklist>`; both rejections recorded in the R6 commit |
| R6.7 | Hooks still work when `jq` is unavailable | run the hooks with a `PATH` lacking `jq` (each falls back to `python3`); recorded in the R6 commit |

## R7 — Docs layer

| AC | Criterion | Satisfied by |
|---|---|---|
| R7.1 | `docs/engine-reference/` gone; `docs/shopify-api-reference/VERSION.md` pins a concrete API version | `docs/shopify-api-reference/VERSION.md`; `test ! -d docs/engine-reference` (R7 smoke test) |
| R7.2 | No engine string under `.claude/docs/` or `docs/` outside `docs/legacy/` | R7 smoke test `! grep -rliwE 'godot\|unity\|unreal\|threejs\|gdscript' --exclude-dir=legacy .claude/docs docs` |
| R7.3 | Every enumerating reference doc (roster, skills, rules, hooks) is 1:1 with disk | `.claude/docs/agent-roster.md`, `.claude/docs/skills-reference.md`, `.claude/docs/rules-reference.md`, `.claude/docs/hooks-reference.md`; enforced by `check-references.py` (a)–(d) |
| R7.4 | `workflow-catalog.yaml` parses as YAML and top-level phases are 0–5 | `.claude/docs/workflow-catalog.yaml`; R7 smoke test `python3 -c "...assert 'phase' in d.lower()"` |
| R7.5 | `quick-start.md` boots a fresh reader: Partner account → dev store → `shopify app dev` → `/start` | `.claude/docs/quick-start.md` |
| R7.6 | Every path referenced from `CLAUDE.md`, agents and skills resolves | `.claude/scripts/check-references.py` (a)–(d) + the R1.2 `@`-import loop for `CLAUDE.md` |

## R8 — Pipeline state & directories

| AC | Criterion | Satisfied by |
|---|---|---|
| R8.1 | `request.md` exists and exactly one non-history `request*.md` | `request.md`; R8 smoke test asserts exactly one non-history `request*.md` beside `request-history.md` |
| R8.2 | `request-history.md` records version, reason, timestamp | `request-history.md` (format per `.claude/docs/templates/request-history.md`) |
| R8.3 | `docs/registry/apps.json` parses and lists every directory under `apps/` | `docs/registry/apps.json`; `python3 -m json.tool docs/registry/apps.json`; lists `discount-bundles`, `order-tags` |
| R8.4 | Each `apps/<app>/` has `status.md` + `approvals.json` parsing with keys ⊆ the five gate ids | `apps/discount-bundles/status.md`, `apps/discount-bundles/approvals.json`, `apps/order-tags/status.md`, `apps/order-tags/approvals.json`; R8 smoke test json.tool loop |
| R8.5 | `directory-structure.md` contains the isolation contract ("no shared mutable file outside the registry", one writer per app) | `.claude/docs/directory-structure.md`; R8 smoke test `grep -q 'no shared mutable file'` |
| R8.6 | `production/apps/<app>/` holds `sprints/`, `milestones/`, `session-state/` | `production/apps/discount-bundles/{sprints,milestones,session-state}`, `production/apps/order-tags/{sprints,milestones,session-state}` |
| R8.7 | Two seed apps exist and neither writes inside the other's directory | `apps/discount-bundles/`, `apps/order-tags/`; `/scaffold` run twice, `git status --porcelain` after touching both shows disjoint paths |
| R8.8 | An untracked edit to `request.md` is rejected by `track-request-changes.sh` (non-zero) | `.claude/hooks/track-request-changes.sh`; negative fixture: edit `request.md` without a `request-history.md` entry → exit 1 |

## R9 — Skill testing framework

| AC | Criterion | Satisfied by |
|---|---|---|
| R9.1 | `Skill Testing Framework/` exists; `AHGS Skill Testing Framework/` does not | `ls -d "Skill Testing Framework"`; `test ! -d "AHGS Skill Testing Framework"` (R9 smoke test) |
| R9.2 | No live reference to the old name outside `docs/legacy/` and `TASKS.md` | R9 smoke test `grep -rl 'AHGS Skill Testing Framework' .claude docs \| grep -v '^docs/legacy/'` is empty |
| R9.3 | Every one of the 31 agents has a spec and no spec describes a deleted role | `Skill Testing Framework/agents/` spec set, one per `.claude/agents/*.md` name |
| R9.4 | Every one of the 66 skills has a spec, or is listed in `catalog.yaml` as intentionally untested | `Skill Testing Framework/skills/` + `Skill Testing Framework/catalog.yaml` untested-with-reason entries |
| R9.5 | `catalog.yaml` parses as YAML and names only existing directories | `Skill Testing Framework/catalog.yaml`; R9 smoke test `python3 -c "...d.strip()"` |
| R9.6 | `quality-rubric.md` has no game-specific criterion | `Skill Testing Framework/quality-rubric.md`, reviewed line by line against AC-R9.6 |

## R10 — Verification gates

| AC | Criterion | Satisfied by |
|---|---|---|
| R10.1 | Tree-wide engine grep returns 0 files | R10 smoke test `! grep -rliwE 'godot\|unity\|unreal\|gdextension\|gds\|threejs\|gdscript' --exclude-dir=.git --exclude-dir=legacy --exclude=TASKS.md .` |
| R10.2 | All five counts match their reference docs (31 / 66 / 13 / 15 / 35) | R10 smoke test count clauses vs `.claude/docs/agent-roster.md`, `skills-reference.md`, `rules-reference.md`, `hooks-reference.md`, `.claude/docs/templates/*.md` |
| R10.3 | `check-references.py` exits 0 and was proven to fail on a renamed agent (fixture restored) | `.claude/scripts/check-references.py` — clean run `OK: 31 agents, 66 skills, 0 broken references` (exit 0); negative fixture `mv .claude/agents/product-director.md{,.bak}` → exit 1 naming the missing agent, then restored |
| R10.4 | `docs/legacy/AC-TRACE.md` covers 16 project criteria + every `AC-Rn.x`, no empty mapping cell | `docs/legacy/AC-TRACE.md` — 16 project rows (P1–P16) + 72 `AC-Rn.x` rows, every row mapped (this file) |
| R10.5 | Isolation and approval negative fixtures both exit non-zero by name | `.claude/hooks/approval-gate.sh` rejecting an app whose `approvals.json` lacks `gate-4-release`; isolation fixture per `.claude/docs/directory-structure.md` one-writer rule — both recorded in the R10 commit |
| R10.6 | `/start` runs in Claude Code, Codex and Hermes and shows master request, apps, stages | `.claude/skills/start/SKILL.md` (`/start claude\|codex\|hermes`) resolving routing through `production/hermes-profile-mapping.json`; outputs pasted in the R10 commit |
| R10.7 | `git status --porcelain` clean and final commit pastes the gate output | `git status --porcelain` empty of unexpected entries + R10 commit message carrying the `R10-OK` output |
