---
name: setup
description: "Initialise a repo generated from the Agentic Shopify App Pipeline template: preview what scripts/init-template.sh will strip, collect the project name and first app, apply it, verify the result, then hand off to /start. In an already-initialised repo it runs the repository checks and repairs drift instead."
argument-hint: "[--name <project>] [--app <slug>]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash, AskUserQuestion, request_user_input, clarify
model: sonnet
---

# Setup

`/setup` is the first command in a generated repo, and the repair command in an
initialised one. It wraps `scripts/init-template.sh` — it never re-implements
the stripping logic itself.

**State decides the mode:**

| `TEMPLATE.md` | Mode |
|---|---|
| present | **Template mode** — preview, collect, apply, verify |
| absent | **Initialised mode** — checks and repair only |

---

## Phase 1: Detect State

1. `Read` the repo root listing. `TEMPLATE.md` present → template mode.
2. `Bash`: `git remote get-url origin` and `git status --porcelain`.
   - Origin pointing at `Agentic-Shopify-App-Pipeline` → say so plainly: this is
     the template repository itself, and `/setup` here will refuse to mutate it.
   - Dirty tree → list the modified paths and ask the user to commit or stash
     before continuing. In template mode the script refuses a dirty tree.
3. `Read docs/registry/apps.json` and `request.md` if they exist, and report the
   current app count and whether a request is already written.

Output a one-paragraph state summary, then continue to the matching phase.

---

## Phase 2: Template Mode — Preview, Collect, Apply

### 2A. Preview (always first)

```bash
bash scripts/init-template.sh --name "<placeholder>" --app <slug-if-known>
```

Without `--apply` the script writes nothing and prints every planned action.
Show that plan to the user verbatim. If the script exits non-zero, report the
exact message and stop — do not work around the guard.

### 2B. Collect the three inputs

Ask, one at a time, with a recommended default where one exists:

1. **Project name** — a display name for `README.md` and `CLAUDE.md`. Default:
   the directory name, title-cased.
2. **One-line description** — replaces the template tagline in `README.md`.
   Optional; skip means the template tagline stays.
3. **First app slug** — lowercase kebab (`my-app`). Optional. If the user has an
   app idea, propose a slug from it and confirm. Warn that a seeded app is
   registered at `stage: research` with no gates approved, so `/research` is the
   next step for it.

Validate the slug against `^[a-z][a-z0-9-]*$` before passing it on. Reject
`My_App`, `my app`, and anything with `/` or `..`.

### 2C. Apply

Present the exact command and ask for approval (Question → Options → Decision):

```bash
bash scripts/init-template.sh --name "<name>" [--description "<text>"] [--app <slug>] --apply --yes
```

Only after an explicit yes, run it. The script prints each path it removes,
writes or retitles, then runs the two repository checks.

### 2D. Verify

Confirm, from the actual output — never from assumption:

- `check-references.py` reported `0 broken references`
- `isolation-check.py` reported `ISOLATION OK`
- `TEMPLATE.md` and `scripts/init-template.sh` are gone
- `apps/<slug>/` exists and the registry has one entry, or `apps/` is empty
- `apps/` contains only the seeded app (or just `.gitkeep`) — no worked examples
- `docs/examples/`, `docs/legacy/`, `docs/superpowers/`, `TASKS.md`, `IDEA.md`
  and `Skill Testing Framework/` are gone

If a check failed, report the failure and stop. Do not commit a broken tree.

### 2E. Commit and hand off

Propose:

```bash
git add -A && git commit -m "chore: initialise project from template"
```

Then route to `/start`. If `request.md` does not exist, `/start` will ask for
the app idea or request — say that, so the user is not surprised by the prompt.

---

## Phase 3: Initialised Mode — Check and Repair

`TEMPLATE.md` is absent, so the repo has been initialised (or was never a
template copy). `/setup` is now a verification command.

1. Run both checkers:
   ```bash
   python3 .claude/scripts/check-references.py
   python3 .claude/scripts/isolation-check.py
   ```
2. Report each result and any drift between `docs/registry/apps.json`, `apps/*/`,
   and `production/apps/*/`.
3. Propose repairs as a numbered list with the exact file each change touches.
   Registry entries and app files are append-only in spirit — never delete an
   app or a gate record without the user saying so explicitly.
4. Apply only what the user approves, then re-run the checkers.
5. Hand off to `/start` for routing, or `/consistency-check` when the drift is
   wider than the two checkers cover.

---

## Guardrails

- **Never delete anything the user has not approved.** Every removal comes from
  `scripts/init-template.sh`, whose plan is shown first.
- **Never run the script with `--force`** to bypass the template-origin guard or
  a dirty tree. Escalate to the user instead.
- **Never edit `docs/registry/apps.json` or `docs/registry/architecture.yaml` by
  hand** in template mode — the script owns those resets.
- **Do not commit** unless the user asks.
- If the script is missing in template mode, stop: the repo is corrupt. Say which
  file is missing; do not reconstruct the stripping logic inline.
