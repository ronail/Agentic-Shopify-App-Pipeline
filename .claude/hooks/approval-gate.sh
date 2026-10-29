#!/usr/bin/env bash
# approval-gate.sh — block release / update actions until the gate is approved.
#
# Reads apps/<app>/approvals.json and refuses to let /release, /apply-updates or
# a phase transition through unless the required gate id is recorded there with
# BOTH a timestamp and an approver.
#
# Gate ids: gate-1-research, gate-2-prototype, gate-3-scope, gate-4-release, gate-5-update
#
# Explicit use:
#   bash .claude/hooks/approval-gate.sh --app my-app --gate gate-4-release
#   bash .claude/hooks/approval-gate.sh --app my-app --action release
#   bash .claude/hooks/approval-gate.sh --app my-app --apps <dir> --gate gate-4-release
#
# Hook use (stdin = PreToolUse payload; auto-detects a gated action, silent otherwise):
#   echo '{"tool_input":{"command":"/release my-app"}}' | bash .claude/hooks/approval-gate.sh
#
# Exit codes: 0 = allowed / not a gated action, 2 = BLOCKED (PreToolUse block code).
# Graceful without jq or python3.

set +e

HOOK="approval-gate.sh"
ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -n "$ROOT" ]; then
  cd "$ROOT" || exit 0
fi

APPS_DIR="${APPS_DIR:-apps}"
APP=""
GATE=""
ACTION=""

usage() {
  sed -n '2,22p' "$0" | sed -E 's/^# ?//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --app)     APP="${2:-}"; shift 2 ;;
    --gate)    GATE="${2:-}"; shift 2 ;;
    --apps)    APPS_DIR="${2:-}"; shift 2 ;;
    --action)  ACTION="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *)         shift ;;
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
if [ ! -t 0 ]; then
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

# --- infer the app and the action --------------------------------------------

if [ -z "$APP" ] && [ -n "$CMD" ]; then
  APP=$(printf '%s' "$CMD" | grep -oE '\-\-app[= ][A-Za-z0-9._-]+' | head -1 | sed -E 's/^--app[= ]//')
fi
if [ -z "$APP" ] && [ -n "$CMD" ]; then
  # "/release my-app" / "/apply-updates my-app" — the first token after the action.
  APP=$(printf '%s' "$CMD" | grep -oE '/(release|apply-updates|propose-updates)[[:space:]]+[A-Za-z0-9._-]+' | head -1 | awk '{print $2}')
fi
if [ -z "$APP" ]; then
  # cwd inside an app directory is the strongest signal available.
  case "$(pwd)" in
    */"$APPS_DIR"/*) APP=$(printf '%s' "$(pwd)" | sed -E "s|.*/$APPS_DIR/([^/]+).*|\1|") ;;
  esac
fi
if [ -z "$APP" ] && [ -n "$CMD" ]; then
  # "advance-phase <app> <stage>" — the token after the action unless it is the stage itself.
  APP=$(printf '%s' "$CMD" | grep -oE 'advance-phase[[:space:]]+[A-Za-z0-9._-]+' | head -1 | awk '{print $2}')
  case "$APP" in
    research|prototype|scope|build|qa|release|update) APP="" ;;
  esac
fi

# Only slash-commands and phase transitions are gated, and only in COMMAND
# position (start of the command, or after ; && || |) — never a bare word that
# happens to appear in a path or an argument.
in_command_position() {
  printf '%s' "$CMD" | grep -qE "(^|[;&|])[[:space:]]*$1([[:space:]]|$)"
}

if [ -z "$ACTION" ] && [ -n "$CMD" ]; then
  if in_command_position '/release'; then
    ACTION="release"
  elif in_command_position '/apply-updates'; then
    ACTION="apply-updates"
  elif in_command_position '/propose-updates'; then
    ACTION="apply-updates"
  elif in_command_position 'advance-phase'; then
    ACTION="phase"
  fi
  if [ "$ACTION" = "phase" ]; then
    STAGE=$(printf '%s' "$CMD" | grep -oE 'phase[[:space:]]+([A-Za-z0-9._-]+[[:space:]]+)?(research|prototype|scope|build|qa|release|update)' | head -1 | awk '{print $NF}')
    [ -n "$STAGE" ] && ACTION="phase:$STAGE"
  fi
fi

gate_for_action() {
  case "$1" in
    release)          echo "gate-4-release" ;;
    apply-updates)    echo "gate-5-update" ;;
    phase:research)   echo "gate-1-research" ;;
    phase:prototype)  echo "gate-2-prototype" ;;
    phase:scope)      echo "gate-3-scope" ;;
    phase:release)    echo "gate-4-release" ;;
    phase:update)     echo "gate-5-update" ;;
    *)                echo "" ;;
  esac
}

if [ -z "$GATE" ] && [ -n "$ACTION" ]; then
  GATE=$(gate_for_action "$ACTION")
fi

# Not a gated action and no explicit gate: stay silent and allow.
if [ -z "$GATE" ]; then
  if [ -n "$ACTION" ]; then
    block "unknown gated action '$ACTION'" \
      "known actions: release, apply-updates, phase:<research|prototype|scope|release|update>"
  fi
  exit 0
fi

if [ -z "$APP" ]; then
  # Hook payload for a gated action but no resolvable slug: warn, do not block.
  if [ -n "$CMD" ]; then
    echo "WARN [$HOOK]: gated command but no app slug could be determined — gate skipped" >&2
    exit 0
  fi
  block "$GATE requires an app — cannot determine the slug" \
    "pass --app <slug>, or run from apps/<slug>/, or include app '<slug>' in the command"
fi

# --- verify the approval record ----------------------------------------------

APPROVALS="$APPS_DIR/$APP/approvals.json"

if [ ! -f "$APPROVALS" ]; then
  block "$GATE cannot be verified — $APPROVALS does not exist" \
    "create it with {\"$GATE\": {\"id\": \"$GATE\", \"timestamp\": \"<ISO-8601>\", \"approver\": \"<owner>\"}}"
fi

REASON=""
if command -v python3 >/dev/null 2>&1; then
  PY_OUT=$(python3 - "$APPROVALS" "$GATE" <<'PY' 2>/dev/null
import json, sys
path, gate = sys.argv[1], sys.argv[2]
try:
    data = json.load(open(path))
except Exception as exc:
    print(f"unreadable JSON: {exc}")
    sys.exit(1)
rec = data.get(gate) if isinstance(data, dict) else None
if not isinstance(rec, dict):
    print("no record for this gate")
    sys.exit(1)
missing = [k for k in ("timestamp", "approver") if not str(rec.get(k, "")).strip()]
if missing:
    print("record is missing " + " and ".join(missing))
    sys.exit(1)
sys.exit(0)
PY
)
  rc=$?
  if [ "$rc" -ne 0 ]; then
    REASON="${PY_OUT:-gate record is absent or incomplete}"
  fi
else
  FLAT=$(tr -d '\n' < "$APPROVALS")
  REC=$(printf '%s' "$FLAT" | grep -oE "\"$GATE\"[[:space:]]*:[[:space:]]*\{[^}]*\}" | head -1)
  if [ -z "$REC" ]; then
    REASON="no record for this gate"
  elif ! printf '%s' "$REC" | grep -qE '"timestamp"[[:space:]]*:[[:space:]]*"[^"]+"'; then
    REASON="record is missing timestamp"
  elif ! printf '%s' "$REC" | grep -qE '"approver"[[:space:]]*:[[:space:]]*"[^"]+"'; then
    REASON="record is missing approver"
  fi
fi

if [ -n "$REASON" ]; then
  block "$GATE is not approved for '$APP' ($REASON)" \
    "file: $APPROVALS" \
    "required entry: {\"$GATE\": {\"id\": \"$GATE\", \"timestamp\": \"<ISO-8601>\", \"approver\": \"<owner>\"}}" \
    "run /gate-check $APP to record the approval"
fi

# Approved: stay quiet on the hook path so the session log stays clean.
[ -n "$ACTION" ] && echo "APPROVED [$HOOK]: $GATE recorded for '$APP'" >&2
exit 0
