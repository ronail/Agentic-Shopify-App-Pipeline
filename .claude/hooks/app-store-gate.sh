#!/usr/bin/env bash
# app-store-gate.sh — block a release when the App Store checklist fails.
#
# The checklist is the verdict written by /app-store-checklist:
#   production/apps/<app>/app-store-checklist.md
#   ## App Store Readiness — <app> — <date>
#   Verdict: ready | not-ready (N fails)
#   | # | Check | Result | Evidence / fix |
#
# Blocked when: the file is missing, the verdict is not `ready`, any row's result
# is FAIL, any checkbox is unchecked, or there is no PASS row at all (a checklist
# with no evidence is not a pass).
#
# Explicit use:
#   bash .claude/hooks/app-store-gate.sh --app order-tags
#   bash .claude/hooks/app-store-gate.sh --checklist /tmp/fixture.md
#   APP_STORE_CHECKLIST=/path/to/checklist.md bash .claude/hooks/app-store-gate.sh
#
# Hook use (stdin = PreToolUse payload): only acts on release-ish commands.
#
# Exit codes: 0 = allowed / not a release action, 2 = BLOCKED (PreToolUse block code).

set +e

HOOK="app-store-gate.sh"
ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -n "$ROOT" ]; then
  cd "$ROOT" || exit 0
fi

APPS_DIR="${APPS_DIR:-apps}"
APP=""
CHECKLIST="${APP_STORE_CHECKLIST:-}"
ACTION=""

usage() {
  sed -n '2,26p' "$0" | sed -E 's/^# ?//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --app)       APP="${2:-}"; shift 2 ;;
    --checklist) CHECKLIST="${2:-}"; shift 2 ;;
    --apps)      APPS_DIR="${2:-}"; shift 2 ;;
    --action)    ACTION="${2:-}"; shift 2 ;;
    -h|--help)   usage; exit 0 ;;
    *)           shift ;;
  esac
done

block() {
  echo "BLOCKED [$HOOK]: $1" >&2
  shift
  for line in "$@"; do echo "  $line" >&2; done
  exit 2
}

# --- hook payload ------------------------------------------------------------

CMD=""
if [ ! -t 0 ] && [ -z "$APP" ] && [ -z "$ACTION" ]; then
  INPUT=$(cat 2>/dev/null)
  if [ -n "$INPUT" ]; then
    if command -v jq >/dev/null 2>&1; then
      CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // .command // empty' 2>/dev/null)
    fi
    if [ -z "$CMD" ]; then
      CMD=$(printf '%s' "$INPUT" | grep -oE '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 \
        | sed -E 's/^"command"[[:space:]]*:[[:space:]]*"//; s/"$//')
    fi
  fi
fi

# Only a token in COMMAND position starts the command (or follows ; && || |).
# A bare substring — `cat production/apps/x/app-store-checklist.md`, `grep app-store` —
# is not a release action.
in_command_position() {
  printf '%s' "$CMD" | grep -qE "(^|[;&|])[[:space:]]*$1([[:space:]]|$)"
}

if [ -z "$ACTION" ] && [ -n "$CMD" ]; then
  if in_command_position '/release' || in_command_position 'app-store-checklist'; then
    ACTION="release"
  fi
fi

if [ -z "$APP" ] && [ -n "$CMD" ]; then
  APP=$(printf '%s' "$CMD" | grep -oE '\-\-app[= ][A-Za-z0-9._-]+' | head -1 | sed -E 's/^--app[= ]//')
fi
# Only infer an app from a `/release <app>` token when the command is actually a
# release action — otherwise a plain `grep -rn /release docs/` would bind APP to
# "docs" and falsely demand production/apps/docs/app-store-checklist.md.
if [ -z "$APP" ] && [ -n "$CMD" ] && [ -n "$ACTION" ]; then
  APP=$(printf '%s' "$CMD" | grep -oE '/release[[:space:]]+[A-Za-z0-9._-]+' | head -1 | awk '{print $2}')
fi

# Nothing to gate: not a release, no explicit checklist.
if [ -z "$ACTION" ] && [ -z "$CHECKLIST" ] && [ -z "$APP" ]; then
  exit 0
fi

if [ -z "$CHECKLIST" ]; then
  if [ -z "$APP" ]; then
    # Hook payload with a release-ish command but no resolvable slug: warn, do not
    # block an unrelated command.
    if [ -n "$CMD" ]; then
      echo "WARN [$HOOK]: release-like command but no app slug could be determined — gate skipped" >&2
      exit 0
    fi
    block "cannot verify the App Store checklist — no app given" \
      "pass --app <slug> or --checklist <path>"
  fi
  CHECKLIST="production/apps/$APP/app-store-checklist.md"
fi

if [ ! -f "$CHECKLIST" ]; then
  block "App Store checklist not found: $CHECKLIST" \
    "run /app-store-checklist ${APP:-<app>} and commit the verdict before releasing"
fi

# --- evaluate the checklist --------------------------------------------------

FAILS=()

verdict=$(grep -iE '^[[:space:]]*Verdict:' "$CHECKLIST" 2>/dev/null | head -1 | sed -E 's/^[[:space:]]*[Vv]erdict:[[:space:]]*//')
if [ -z "$verdict" ]; then
  FAILS+=("checklist has no 'Verdict:' line — the readiness verdict is unknown")
elif printf '%s' "$verdict" | grep -qiE '^(not[- ]ready|fail|no)'; then
  FAILS+=("verdict is '$verdict'")
elif ! printf '%s' "$verdict" | grep -qiE '^ready'; then
  FAILS+=("verdict '$verdict' is not an explicit 'ready'")
fi

fail_rows=$(grep -cE '\|[[:space:]]*FAIL[[:space:]]*\|' "$CHECKLIST" 2>/dev/null)
fail_rows=${fail_rows:-0}
if [ "$fail_rows" -gt 0 ] 2>/dev/null; then
  rows=$(grep -E '\|[[:space:]]*FAIL[[:space:]]*\|' "$CHECKLIST" 2>/dev/null | head -5 | sed -E 's/^[[:space:]]*/    /')
  FAILS+=("$fail_rows checklist row(s) marked FAIL:"$'\n'"$rows")
fi

unchecked=$(grep -cE '^[[:space:]]*- \[ \]' "$CHECKLIST" 2>/dev/null)
unchecked=${unchecked:-0}
if [ "$unchecked" -gt 0 ] 2>/dev/null; then
  FAILS+=("$unchecked unchecked item(s) (- [ ]) remain")
fi

pass_rows=$(grep -cE '\|[[:space:]]*PASS[[:space:]]*\|' "$CHECKLIST" 2>/dev/null)
pass_rows=${pass_rows:-0}
if [ "$pass_rows" -le 0 ] 2>/dev/null; then
  FAILS+=("no PASS row with evidence — an empty checklist is not a pass")
fi

if [ "${#FAILS[@]}" -gt 0 ]; then
  block "App Store checklist failed — release is blocked" \
    "file: $CHECKLIST" \
    "$(printf '  - %s\n' "${FAILS[@]}")" \
    "fix the checklist (/app-store-checklist ${APP:-<app>}) and re-run before releasing"
fi

[ -n "$ACTION" ] && echo "APPROVED [$HOOK]: App Store checklist ready ($pass_rows PASS rows) — $CHECKLIST" >&2
exit 0
