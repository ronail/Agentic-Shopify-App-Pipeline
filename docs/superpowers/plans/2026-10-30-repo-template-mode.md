# Repo Template Mode — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a GitHub template flow where `scripts/init-template.sh` sanitises a
generated repo, while this repo keeps every example file it has today.

**Architecture:** The template repo stays a living reference implementation.
A single guarded bash script performs all stripping, registry resets, retitling
and optional first-app seeding in the *generated* copy, then runs the repo's two
existing consistency checkers. In-repo edits are limited to three game-fork
defect fixes, neutral `<app>` placeholders in framework docs, and graceful
degradation for the two skills that read `Skill Testing Framework/`.

**Tech Stack:** Bash, Python 3 (existing checkers), Markdown/YAML skills and
docs, `gh` CLI for repository settings.

**Spec:** `docs/superpowers/specs/2026-10-30-repo-template-mode-design.md` (rev. 2)

## Global Constraints

- No tracked file is deleted or content-removed in this repo.
- Every framework reference to a demo app becomes `<app>` (prose) or `my-app`
  (runnable example); historical files keep real names.
- Hook behaviour stays glob/arg-driven — never a hard-coded app slug.
- Skills keep all their modes; STF-dependent modes degrade with a notice.
- Commits: one per task, conventional prefix, no batching.
- Verification is executed, never asserted.

## Review Focus

- **Script run inside this repo** — must refuse on the template-origin remote,
  not delete the demo apps.
- **Script run without `--apply`** — must print the plan and change nothing.
- **Generated repo with `Skill Testing Framework/` gone** — `/skill-test
  category` must report the missing harness, not error, and not claim coverage.
- **Generated repo with `--app` omitted** — registries empty, checkers green,
  `/start` must still route (it prompts for `request.md`).
- **`--app` with an invalid slug** (`My_App`, `../x`) — must refuse before any
  mutation.

---

### Task 1: Fix the game-fork design docs

**Files:**
- Modify: `design/CLAUDE.md` (full rewrite)
- Modify: `design/registry/entities.yaml` (full rewrite)

**Interfaces:** Consumes nothing; produces the empty registry shape the init
script re-writes (`entities: []`, `last_updated: ""`).

- [ ] Rewrite `design/CLAUDE.md` for per-app UX specs (`apps/<app>/design/ux/`),
      quick specs (`apps/<app>/design/quick-specs/`), and `design/` as the
      shared-assets + entity-registry location.
- [ ] Rewrite `design/registry/entities.yaml` as a Design Entity Registry
      (`entities`, `items`, `formulas`, `constants` → empty; Shopify-flavoured
      examples in comments).
- [ ] Verify: `grep -niE 'gdd|player fantasy|goblin|godot' design/` → no hits.
- [ ] Commit: `fix(design): replace game-fork design docs with Shopify design standards`

### Task 2: Fix the status line

**Files:**
- Modify: `.claude/statusline.sh`

**Interfaces:** Reads `docs/registry/apps.json` (`.apps | length`),
`request.md`, `git branch`. Prints `ctx: N% | model | pipeline: <state>`.

- [ ] Retitle to "Agentic Shopify App Pipeline".
- [ ] Replace `design/gdd/*` reads with registry app count + stage, `request.md`
      presence, and branch.
- [ ] Verify: `echo '{}' | bash .claude/statusline.sh` exits 0 and prints no
      `gdd`/`Concept`; run it in this repo and see `2 apps`.
- [ ] Commit: `fix(statusline): report pipeline state instead of game concept files`

### Task 3: Neutral placeholders in framework docs

**Files:** `docs/WORKFLOW-GUIDE.md`, `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md`,
`docs/architecture/README.md`, `docs/architecture/ADR-0001-admin-api-version-policy.md`,
`.claude/docs/agent-memory-setup.md`, `.claude/docs/hooks-reference/{approval-gate,app-store-gate}.md`

- [ ] Replace every `discount-bundles` / `order-tags` with `<app>` (prose) or
      `my-app` (commands).
- [ ] Verify: `grep -rn 'discount-bundles\|order-tags'` on those files → no hits.
- [ ] Commit: `docs: replace demo app slugs with <app> placeholders in framework docs`

### Task 4: Skills — placeholders + STF degradation

**Files:** `.claude/skills/{start,scaffold,adopt,kanban-status,project-stage-detect,tech-debt,update-request,consistency-check,skill-test,skill-improve}/SKILL.md`,
`.claude/hooks/{approval-gate,app-store-gate,pre-compact,session-start,detect-gaps}.sh`

- [ ] Placeholder replacements in the first eight skills and five hook comment
      blocks; no behaviour change.
- [ ] `skill-test`: before `category`/`audit`, guard on
      `Skill Testing Framework/catalog.yaml`; print
      `Skill Testing Framework not installed; static and spec modes available.` and stop.
- [ ] `skill-improve`: Phase 2b skips the category baseline the same way.
- [ ] Verify: `bash -n` on each touched hook; `python3 .claude/scripts/check-references.py`
      still `0 broken references`.
- [ ] Commit: `refactor(skills): neutral app placeholders and graceful STF fallback`

### Task 5: `scripts/init-template.sh`

**Files:** Create `scripts/init-template.sh` (mode 755).

**Interfaces:** Produces flags `--name --description --app --apply --yes
--force --skip-checks`; exits 1 on guard failure, 0 otherwise; deletes itself
at step 8.

- [ ] Implement guards (TEMPLATE.md, template-origin remote, dirty tree, slug
      validation) and the ten mutation steps from the spec.
- [ ] Verify in this repo: `scripts/init-template.sh --name X` → refusal on
      template origin, no mutation (`git status --porcelain` unchanged).
- [ ] Verify invalid slug: `--app My_App` → refusal before mutation.
- [ ] `bash -n scripts/init-template.sh`; `shellcheck` if installed.
- [ ] Commit: `feat(scripts): add init-template.sh sanitizer for generated repos`

### Task 6: `/setup` skill + TEMPLATE.md + README template block

**Files:** Create `.claude/skills/setup/SKILL.md`, `TEMPLATE.md`; modify `README.md`.

- [ ] `/setup` SKILL.md with repo-convention frontmatter, template vs
      initialised mode, dry-run-then-apply flow.
- [ ] `TEMPLATE.md` — template contract, strip list, upstream updates, strip-once
      limitation.
- [ ] README: `TEMPLATE-ONLY` region with the generate URL, dry-run workflow,
      and the worked-examples note; update Project Structure.
- [ ] Verify: `check-references.py` → `32 agents? no: 66 skills → 67`; confirm
      `/setup` found by the checker; `grep TEMPLATE-ONLY README.md`.
- [ ] Commit: `feat(setup): add /setup entry point and template contract`

### Task 7: Docs for the generated-repo flow + Codex compat

**Files:** `.claude/docs/{directory-structure,quick-start,setup-requirements,skills-reference}.md`,
`.claude/docs/workflow-catalog.yaml`, regenerated `.codex/*`

- [ ] Add the generation flow (generate → `init-template.sh` → `/setup` →
      `/start`), `scripts/` and `TEMPLATE.md` to the tree map, `/setup` to the
      skills reference and catalog.
- [ ] `python3 .codex/generate_compat.py`; commit regenerated output.
- [ ] Verify: `check-references.py` green; `git diff --stat` shows only intended
      files.
- [ ] Commit: `docs: document the generated-repo flow and regenerate Codex compat`

### Task 8: Verification and rehearsal

**Files:** none (verification only).

- [ ] In-repo: both checkers green (`2 apps`), hook smoke exit 0, `git diff
      --stat main` shows no deletions of tracked files.
- [ ] Scratch copy → `--name "Acme Bundles" --app acme-bundles --apply --yes`;
      both checkers green in the copy; strip list gone; `TEMPLATE.md` and the
      script gone; `git grep` for demo slugs/STF/legacy/TASKS empty.
- [ ] Safety: `--apply` here without `--force` refuses; dirty tree refuses;
      non-template dir refuses.
- [ ] Dead-link check over `README.md` + `docs/**/*.md`.
- [ ] Commit any fixes as `test(template): ...`.

### Task 9: Repository settings (post-merge)

- [ ] `gh api -X PATCH repos/ronail/Agentic-Shopify-App-Pipeline -f is_template=true`
- [ ] Topics + description.
- [ ] Verify `--jq '.is_template'` → `true`.
