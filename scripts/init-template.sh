#!/usr/bin/env bash
# init-template.sh — sanitise a repository generated from the
# Agentic Shopify App Pipeline template.
#
# The template repo ships worked examples (two demo apps, session transcripts,
# the retarget log, the Skill Testing Framework). This script strips them from
# the *generated* copy so the result is a clean starting point for your project.
# It never runs in the template repo itself: it refuses a template-origin
# remote, and it deletes itself once applied.
#
# Dry-run is the default. Nothing changes without --apply.
#
# Usage: scripts/init-template.sh --name <project> [--description <text>]
#                                 [--app <slug>] [--apply] [--yes] [--force]
#                                 [--skip-checks]

set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

TEMPLATE_REMOTE_MARKER="Agentic-Shopify-App-Pipeline"

NAME=""
DESCRIPTION=""
APP=""
APPLY=0
ASSUME_YES=0
FORCE=0
SKIP_CHECKS=0

usage() {
  cat <<'EOF'
Usage: scripts/init-template.sh [options]

  --name <project-name>   Display name for README.md and CLAUDE.md
  --description <text>    One-line description replacing the template tagline
  --app <slug>            Optional first app slug (lowercase kebab, e.g. my-app)
  --apply                 Actually modify the repo (default: report only)
  --yes                   Skip the interactive confirmation
  --force                 Allow a dirty tree or a template-origin remote
  --skip-checks           Do not run the reference/isolation checkers
  -h, --help              Show this help

Without --apply the script prints every action it would take and changes
nothing. With --apply it strips the template payload, resets the registries,
retitles the project, and then deletes itself.
EOF
}

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
act() { printf '%s\n' "$*"; }

need_value() {
  [ "$2" -ge 2 ] || die "option $1 needs a value"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --name)        need_value "$1" "$#"; NAME="$2"; shift 2 ;;
    --description) need_value "$1" "$#"; DESCRIPTION="$2"; shift 2 ;;
    --app)         need_value "$1" "$#"; APP="$2"; shift 2 ;;
    --apply)       APPLY=1; shift ;;
    --yes)         ASSUME_YES=1; shift ;;
    --force)       FORCE=1; shift ;;
    --skip-checks) SKIP_CHECKS=1; shift ;;
    -h|--help)     usage; exit 0 ;;
    *)             die "unknown option: $1 (try --help)" ;;
  esac
done

# ── Guards ───────────────────────────────────────────────────────────────────

[ -d "$ROOT/.claude/agents" ] || die "no .claude/agents here — run this from a repo generated from the template"
[ -f "$ROOT/TEMPLATE.md" ] || die "TEMPLATE.md is missing — this repo is already initialised (or was never a template copy)"

ORIGIN=$(git remote get-url origin 2>/dev/null || true)
case "$ORIGIN" in
  *"$TEMPLATE_REMOTE_MARKER"*)
    if [ "$FORCE" -ne 1 ]; then
      die "origin points at the template repo ($ORIGIN).
Refusing to strip the reference repository. Generate a new repo from the
template first (github.com/ronail/Agentic-Shopify-App-Pipeline/generate), or
pass --force if you really mean to sanitise this clone."
    fi
    ;;
esac

if [ -n "$(git status --porcelain 2>/dev/null || true)" ] && [ "$FORCE" -ne 1 ]; then
  die "working tree is dirty. Commit or stash first, or pass --force."
fi

if [ "$APPLY" -eq 1 ]; then
  [ -n "$NAME" ] || die "--name is required with --apply"
fi

case "$NAME" in
  *$'\n'*) die "--name must be a single line" ;;
esac

if [ -n "$APP" ]; then
  printf '%s' "$APP" | grep -Eq '^[a-z][a-z0-9-]*$' \
    || die "--app must be lowercase kebab-case (letters, digits, hyphens), got: $APP"
fi

# ── Plan header ──────────────────────────────────────────────────────────────

if [ "$APPLY" -eq 1 ]; then
  act "Initialising this repo as: ${NAME}"
else
  act "DRY RUN — nothing will be written. Re-run with --apply to execute."
  act "Project name: ${NAME:-<not set>}"
fi
[ -n "$DESCRIPTION" ] && act "Description: $DESCRIPTION"
[ -n "$APP" ] && act "First app: $APP"
act ""

# ── Helpers ──────────────────────────────────────────────────────────────────

remove_path() {
  for path in "$@"; do
    if [ -e "$ROOT/$path" ] || [ -L "$ROOT/$path" ]; then
      if [ "$APPLY" -eq 1 ]; then
        rm -rf -- "$ROOT/$path"
        act "removed: $path"
      else
        act "would remove: $path"
      fi
    else
      act "skip (absent): $path"
    fi
  done
}

# put <repo-relative-path> ; content on stdin
put() {
  path="$1"
  if [ "$APPLY" -eq 1 ]; then
    mkdir -p "$(dirname "$ROOT/$path")"
    cat > "$ROOT/$path"
    act "wrote: $path"
  else
    cat > /dev/null
    act "would write: $path"
  fi
}

make_dir() {
  for path in "$@"; do
    if [ "$APPLY" -eq 1 ]; then
      mkdir -p "$ROOT/$path"
      act "created dir: $path"
    else
      act "would create dir: $path"
    fi
  done
}

# ── Confirmation ─────────────────────────────────────────────────────────────

if [ "$APPLY" -eq 1 ] && [ "$ASSUME_YES" -ne 1 ]; then
  cat <<EOF

This will permanently, in this repository:
  • delete the worked-example apps and their ADRs/requirements/manifests
  • delete docs/examples/, docs/legacy/, docs/superpowers/, TASKS.md,
    request.md, request-history.md and production/session-logs/
  • delete Skill Testing Framework/
  • reset docs/registry/apps.json, docs/registry/architecture.yaml and
    design/registry/entities.yaml to an empty state
EOF
  [ -n "$APP" ] && printf '  • create apps/%s/ and register it at stage: research\n' "$APP"
  cat <<'EOF'
  • delete TEMPLATE.md and this script
EOF
  printf '\nType "yes" to continue: '
  read -r answer
  [ "$answer" = "yes" ] || die "aborted — nothing was changed"
  act ""
fi

# ── 1. Strip the worked-example apps and their per-app artefacts ─────────────

if [ -d "$ROOT/apps" ]; then
  for dir in "$ROOT"/apps/*/; do
    [ -d "$dir" ] || continue
    remove_path "apps/$(basename "$dir")"
  done
else
  make_dir apps
fi

remove_path "docs/architecture/apps" "production/apps"

# ── 2. Strip this project's history ──────────────────────────────────────────

remove_path "docs/examples" "docs/legacy" "docs/superpowers" \
            "TASKS.md" "request.md" "request-history.md"

if [ -d "$ROOT/production/session-logs" ]; then
  if [ "$APPLY" -eq 1 ]; then
    find "$ROOT/production/session-logs" -mindepth 1 -delete 2>/dev/null || true
    act "cleared: production/session-logs/"
  else
    act "would clear: production/session-logs/"
  fi
fi

# ── 3. Strip the skill QA harness (skills degrade gracefully without it) ──────

remove_path "Skill Testing Framework"

# ── 4. Reset the registries ──────────────────────────────────────────────────

put "docs/registry/apps.json" <<'EOF'
{
  "apps": []
}
EOF

put "docs/registry/architecture.yaml" <<'EOF'
# Architecture Registry
#
# PURPOSE: cross-app index and stance list for the Shopify apps in this repo.
# ADRs are per app (docs/architecture/apps/<app>/ADR-*.md); this file is the one
# place that shows all of them side by side, plus the stances every app must
# agree on.
#
# RULES:
#   - Register a stance when it constrains how ANOTHER app must be built. A
#     detail that affects only one app lives in that app's ADR, not here.
#   - Never delete an entry — set status: superseded_by: ADR-NNNN instead.
#   - An app's `adrs` list must match the files in its directory; a missing file
#     is a blocking finding for /architecture-review.
#
# WRITTEN BY: /architecture-decision (after an ADR is Accepted)
#             /architecture-review (Phase 8, when requirements or ADRs change)
# READ BY:    /architecture-decision, /architecture-review, /create-architecture,
#             /create-stories, /consistency-check
#
# SEARCH PATTERNS:
#   Apps and pins:        ^  [a-z].*:$  /  pinned_admin_api_version
#   Stances for one app:  app: <app>
#   All forbidden:        ^  - pattern:

version: 2
last_updated: ""
pinned_admin_api_version: "2026-10"
api_version_policy: docs/architecture/ADR-0001-admin-api-version-policy.md

apps: {}

shared_adrs: []

stances: []

interfaces: []

budgets: []

forbidden_patterns: []
EOF

if [ -f "$ROOT/design/registry/entities.yaml" ]; then
  if [ "$APPLY" -eq 1 ]; then
    python3 - "$ROOT/design/registry/entities.yaml" <<'PY'
import re, sys
path = sys.argv[1]
lines = open(path, encoding="utf-8").read().splitlines()
sections = ("entities", "items", "formulas", "constants")
out, skipping = [], False
for line in lines:
    match = re.match(r'^(entities|items|formulas|constants):', line)
    if match:
        out.append(f"{match.group(1)}: []")
        skipping = True
        continue
    if skipping:
        if line.startswith("# \u2500\u2500\u2500") or re.match(r'^[a-z_]+:', line):
            skipping = False
        else:
            continue
    out.append(line)
open(path, "w", encoding="utf-8").write("\n".join(out) + "\n")
PY
    act "reset: design/registry/entities.yaml (all sections empty)"
  else
    act "would reset: design/registry/entities.yaml (all sections empty)"
  fi
fi

# ── 5. Retitle the project ───────────────────────────────────────────────────

retitle() {
  file="$1"
  [ -f "$ROOT/$file" ] || return 0
  if [ "$APPLY" -eq 1 ]; then
    python3 - "$ROOT/$file" "$NAME" <<'PY'
import sys
path, name = sys.argv[1], sys.argv[2]
lines = open(path, encoding="utf-8").read().splitlines()
for i, line in enumerate(lines):
    if line.startswith("# "):
        title = line[2:]
        suffix = ""
        if " \u2014 " in title:
            suffix = " \u2014 " + title.split(" \u2014 ", 1)[1]
        lines[i] = "# " + name + suffix
        break
open(path, "w", encoding="utf-8").write("\n".join(lines) + "\n")
PY
    act "retitled: $file"
  else
    act "would retitle: $file"
  fi
}

if [ -n "$NAME" ]; then
  retitle "README.md"
  retitle "CLAUDE.md"
fi

if [ -n "$DESCRIPTION" ] && [ -f "$ROOT/README.md" ]; then
  if [ "$APPLY" -eq 1 ]; then
    python3 - "$ROOT/README.md" "$DESCRIPTION" <<'PY'
import sys
path, description = sys.argv[1], sys.argv[2]
lines = open(path, encoding="utf-8").read().splitlines()
try:
    start = next(i for i, line in enumerate(lines) if line.startswith("# ")) + 1
except StopIteration:
    sys.exit(0)
while start < len(lines) and lines[start].strip() == "":
    start += 1
end = start
while end < len(lines) and lines[end].strip() != "":
    end += 1
lines[start:end] = [description]
open(path, "w", encoding="utf-8").write("\n".join(lines) + "\n")
PY
    act "described: README.md"
  else
    act "would describe: README.md"
  fi
fi

# ── 6. Optionally seed the first app ─────────────────────────────────────────

if [ -n "$APP" ]; then
  put "apps/$APP/README.md" <<EOF
# $APP

Describe the merchant problem this app solves, in one paragraph.
EOF
  put "apps/$APP/status.md" <<EOF
# $APP — Status

Stage: research
Last approved gate: none
Blockers: none
EOF
  put "apps/$APP/approvals.json" <<'EOF'
{}
EOF
  put "apps/$APP/prototype/.gitkeep" <<'EOF'
EOF
  make_dir "production/apps/$APP/sprints" "production/apps/$APP/milestones" "production/apps/$APP/session-state"
  put "production/apps/$APP/sprints/.gitkeep" <<'EOF'
EOF
  put "production/apps/$APP/milestones/.gitkeep" <<'EOF'
EOF
  put "production/apps/$APP/session-state/.gitkeep" <<'EOF'
EOF

  if [ "$APPLY" -eq 1 ]; then
    python3 - "$ROOT/docs/registry/apps.json" "$APP" <<'PY'
import datetime, json, sys
path, slug = sys.argv[1], sys.argv[2]
try:
    data = json.load(open(path, encoding="utf-8"))
except Exception:
    data = {"apps": []}
data.setdefault("apps", [])
data["apps"] = [a for a in data["apps"] if a.get("slug") != slug]
data["apps"].append({
    "slug": slug,
    "name": slug.replace("-", " ").title(),
    "purpose": "Describe the merchant problem this app solves.",
    "stage": "research",
    "last_approved_gate": None,
    "created": datetime.date.today().isoformat(),
})
with open(path, "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2)
    fh.write("\n")
PY
    act "registry: added $APP at stage: research"
  else
    act "would add registry entry: $APP (stage: research)"
  fi
else
  put "apps/.gitkeep" <<'EOF'
EOF
  make_dir "production/apps"
  put "production/apps/.gitkeep" <<'EOF'
EOF
fi

# ── 7. Remove the template scaffolding ───────────────────────────────────────

if [ -f "$ROOT/README.md" ]; then
  if [ "$APPLY" -eq 1 ]; then
    python3 - "$ROOT/README.md" <<'PY'
import re, sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
text = re.sub(r"(?s)<!-- TEMPLATE-ONLY:START -->.*?<!-- TEMPLATE-ONLY:END -->\n?", "", text)
open(path, "w", encoding="utf-8").write(text)
PY
    act "stripped TEMPLATE-ONLY sections: README.md"
  else
    act "would strip TEMPLATE-ONLY sections: README.md"
  fi
fi

remove_path "TEMPLATE.md"

# ── 8. Verify ────────────────────────────────────────────────────────────────

status=0
if [ "$SKIP_CHECKS" -eq 0 ] && [ "$APPLY" -eq 1 ]; then
  act ""
  act "Running repository checks:"
  python3 "$ROOT/.claude/scripts/check-references.py" || status=1
  python3 "$ROOT/.claude/scripts/isolation-check.py" || status=1
elif [ "$SKIP_CHECKS" -eq 0 ]; then
  act ""
  act "would run: .claude/scripts/check-references.py, .claude/scripts/isolation-check.py"
fi

# ── 9. Remove this script, then report ───────────────────────────────────────

SELF="$ROOT/scripts/init-template.sh"
if [ "$APPLY" -eq 1 ]; then
  rm -f -- "$SELF"
  act "removed: scripts/init-template.sh"
else
  act "would remove: scripts/init-template.sh"
fi

act ""
if [ "$APPLY" -eq 1 ]; then
  act "Done. Next:"
  act "  1. Write request.md (or just run /start and answer its questions)."
  act "  2. /start            # routes you into research or scaffold"
  act "  3. git add -A && git commit -m \"chore: initialise project from template\""
else
  act "Dry run complete. Re-run with --apply to execute."
fi

if [ "$status" -ne 0 ]; then
  die "one or more repository checks failed — fix them before committing"
fi
