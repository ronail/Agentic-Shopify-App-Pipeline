# Template Contract

This repository is a **GitHub template**. It ships a complete agentic pipeline
for building Shopify apps *and* a worked reference implementation of that
pipeline. This file explains the difference, and what generation does.

Once you run the initialiser, this file is deleted — it has no purpose in a
project that is already initialised.

## What ships

| Layer | Contents | After generation |
|---|---|---|
| Agents | `.claude/agents/` — 31 roles | kept |
| Skills | `.claude/skills/` — one per pipeline step | kept |
| Hooks + rules | `.claude/hooks/`, `.claude/rules/` | kept |
| Docs | `.claude/docs/`, `docs/WORKFLOW-GUIDE.md`, `docs/shopify-api-reference/2026-10/` | kept |
| Harness config | `.codex/`, `production/hermes-*` | kept |
| Worked example apps | `apps/discount-bundles/`, `apps/order-tags/` and their ADRs, requirements, control manifests, sprint state | **stripped** |
| Worked sessions | `docs/examples/session-*.md` | **stripped** |
| Retarget history | `TASKS.md`, `IDEA.md`, `docs/legacy/`, `docs/superpowers/`, `request.md`, `request-history.md` | **stripped** |
| Skill QA harness | `Skill Testing Framework/` | **stripped** |

The worked examples exist so you can read a finished slice of the pipeline —
two apps researched, architected and gated — before you start your own. They are
not a starting point: their registries, ADRs and sprint state belong to this
repository's own history.

Stripping `Skill Testing Framework/` is deliberate. `/skill-test` keeps working
in `static` mode; `spec`, `category` and `audit` report that the harness is not
installed rather than failing.

## Generating a project

**Option A — GitHub:** use
[the template](https://github.com/ronail/Agentic-Shopify-App-Pipeline/generate),
then clone your new repository.

**Option B — manual:**

```bash
git clone https://github.com/ronail/Agentic-Shopify-App-Pipeline.git my-project
cd my-project
git remote set-url origin <your-new-repo-url>
```

Either way, initialise it once:

```bash
# 1. See exactly what would change (nothing is written)
scripts/init-template.sh --name "Acme Bundles" --app acme-bundles

# 2. Apply it
scripts/init-template.sh --name "Acme Bundles" \
  --description "Bundle discounts for Shopify merchants" \
  --app acme-bundles --apply --yes

# 3. Commit the result
git add -A && git commit -m "chore: initialise project from template"
```

The script:

1. refuses to run when `origin` points at the template repo, so this repository
   can never be stripped by accident;
2. refuses a dirty working tree (override with `--force`);
3. deletes the worked-example apps, their per-app artefacts, the session
   transcripts, the retarget history and the skill QA harness;
4. resets `docs/registry/apps.json`, `docs/registry/architecture.yaml` and
   `design/registry/entities.yaml` to their empty shapes;
5. retitles `README.md` and `CLAUDE.md`, and replaces the README tagline when
   `--description` is given;
6. optionally seeds `apps/<slug>/` and `production/apps/<slug>/` and registers
   the app at `stage: research`;
7. runs `.claude/scripts/check-references.py` and
   `.claude/scripts/isolation-check.py`;
8. deletes this file and itself.

### Or let the workflow do it

`.github/workflows/template-init.yml` runs this script for you on the first push
to a repo generated from the template, commits the result, and deletes itself.
It needs no input:

- **project name** ← the repository name (`acme-bundles` → *Acme Bundles*)
- **description** ← the repository description
- **no app is seeded** — seed one by hand with `--app <slug>`, or use
  **Actions → Template init → Run workflow** and pass `name` / `app`

It no-ops in this repository (the `github.repository` guard) and in a repo that
is already initialised (the `TEMPLATE.md` guard). Two things make it skip or
fail: Actions disabled on the new repo — enable them and re-run it from the
Actions tab — and branch protection on `main` that blocks
`github-actions[bot]` — allow the bot, or initialise locally.

## Pulling framework updates later

A generated repo is a fork in spirit, not a git fork. To pick up later pipeline
fixes:

```bash
git remote add upstream https://github.com/ronail/Agentic-Shopify-App-Pipeline.git
git fetch upstream
git cherry-pick <commit>        # or: git checkout upstream/main -- .claude/
```

Cherry-pick rather than merge: your `apps/`, `docs/registry/` and
`request.md` diverge immediately, and a merge would fight you.

## Known limitations

- **Strip-once.** The initialiser deletes itself. A repo initialised by hand
  cannot be re-sanitised by the script.
- **`.agents/skills` is a symlink** to `.claude/skills`. Clones preserve it on
  macOS and Linux; on Windows, recreate it or ignore it.
- **The demo apps ship in every generated repo** until you run the initialiser.
  That is the cost of keeping a readable worked example in the template; the
  README's first instruction is to strip them.
- **`docs/shopify-api-reference/` is pinned to 2026-10.** Moving to a newer API
  version means adding a snapshot directory — see `docs/architecture/ADR-0001-admin-api-version-policy.md`.
