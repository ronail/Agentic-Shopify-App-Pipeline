#!/bin/bash
# Claude Code PreToolUse hook: validate a git commit before it lands.
# Semantics kept from the original: exit 0 = allow (warnings on stderr),
# exit 2 = block. The engine-asset path rules are gone; the checks are now the
# pipeline's own invariants:
#   * every staged .json file must parse                         (blocking)
#   * staged apps/<app>/approvals.json records need id,
#     timestamp and approver                                     (blocking)
#   * a staged request.md needs a staged request-history.md      (blocking)
#   * staged apps/<app>/status.md must keep a Stage: line        (advisory)
#   * TODO/FIXME/HACK in staged code should carry an owner tag   (advisory)
#
# Input schema (PreToolUse for Bash):
# { "tool_name": "Bash", "tool_input": { "command": "git commit -m ..." } }
# Graceful without jq or python3.

set +e

INPUT=""
if [ ! -t 0 ]; then
  INPUT=$(cat 2>/dev/null)
fi

COMMAND=""
if [ -n "$INPUT" ]; then
  if command -v jq >/dev/null 2>&1; then
    COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // .command // empty' 2>/dev/null)
  fi
  if [ -z "$COMMAND" ]; then
    COMMAND=$(printf '%s' "$INPUT" | grep -oE '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 \
      | sed -E 's/^"command"[[:space:]]*:[[:space:]]*"//; s/"$//')
  fi
fi

# Only process git commit commands (also matches `git -C dir commit`).
if ! printf '%s' "$COMMAND" | grep -qE '(^|[&;|][[:space:]]*)git([[:space:]]+-[^[:space:]]+([[:space:]]+[^[:space:]]+)?)?[[:space:]]+commit([[:space:]]|$)'; then
  exit 0
fi

STAGED=$(git diff --cached --name-only 2>/dev/null)
if [ -z "$STAGED" ]; then
  exit 0
fi

WARNINGS=""

PYTHON_CMD=""
for cmd in python3 python py; do
  if command -v "$cmd" >/dev/null 2>&1; then
    PYTHON_CMD="$cmd"
    break
  fi
done

# --- BLOCKING: staged JSON must parse ---------------------------------------

JSON_FILES=$(printf '%s\n' "$STAGED" | grep -E '\.json$')
if [ -n "$JSON_FILES" ]; then
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    [ -f "$file" ] || continue
    if [ -n "$PYTHON_CMD" ]; then
      if ! "$PYTHON_CMD" -m json.tool "$file" >/dev/null 2>&1; then
        echo "BLOCKED: $file is not valid JSON — fix it before committing." >&2
        exit 2
      fi
    else
      WARNINGS="$WARNINGS\nJSON: cannot parse-check $file (no python3 on PATH)"
    fi
  done <<< "$JSON_FILES"
fi

# --- BLOCKING: approval records must be complete ----------------------------

APPROVAL_FILES=$(printf '%s\n' "$STAGED" | grep -E '^apps/[^/]+/approvals\.json$')
if [ -n "$APPROVAL_FILES" ]; then
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    [ -f "$file" ] || continue
    flat=$(tr -d '\n' < "$file")
    gates=$(printf '%s' "$flat" | grep -oE '"gate-[1-5]-[a-z]+"' | tr -d '"' | sort -u)
    for gate in $gates; do
      rec=$(printf '%s' "$flat" | grep -oE "\"$gate\"[[:space:]]*:[[:space:]]*\{[^}]*\}" | head -1)
      if [ -z "$rec" ] \
        || ! printf '%s' "$rec" | grep -qE '"timestamp"[[:space:]]*:[[:space:]]*"[^"]+"' \
        || ! printf '%s' "$rec" | grep -qE '"approver"[[:space:]]*:[[:space:]]*"[^"]+"'; then
        echo "BLOCKED: $file records '$gate' without both a timestamp and an approver." >&2
        echo "         required: {\"$gate\": {\"id\": \"$gate\", \"timestamp\": \"<ISO-8601>\", \"approver\": \"<owner>\"}}" >&2
        exit 2
      fi
    done
  done <<< "$APPROVAL_FILES"
fi

# --- BLOCKING: request changes must be tracked ------------------------------

if printf '%s\n' "$STAGED" | grep -qx 'request\.md'; then
  if ! printf '%s\n' "$STAGED" | grep -qx 'request-history\.md'; then
    echo "BLOCKED: request.md is staged without request-history.md." >&2
    echo "         Append the version, reason and timestamp to request-history.md in the same commit." >&2
    exit 2
  fi
fi

# --- ADVISORY ---------------------------------------------------------------

STATUS_FILES=$(printf '%s\n' "$STAGED" | grep -E '^apps/[^/]+/status\.md$')
if [ -n "$STATUS_FILES" ]; then
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    [ -f "$file" ] || continue
    if ! grep -qE '^[[:space:]]*Stage:' "$file"; then
      WARNINGS="$WARNINGS\nSTATUS: $file has no 'Stage:' line — /start cannot route this app."
    fi
    if ! grep -qE '^[[:space:]]*Last approved gate:' "$file"; then
      WARNINGS="$WARNINGS\nSTATUS: $file has no 'Last approved gate:' line."
    fi
  done <<< "$STATUS_FILES"
fi

CODE_FILES=$(printf '%s\n' "$STAGED" | grep -E '\.(js|jsx|ts|tsx|mjs|cjs|py|sh|liquid)$')
if [ -n "$CODE_FILES" ]; then
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    [ -f "$file" ] || continue
    if grep -qE '(TODO|FIXME|HACK)([^(]|$)' "$file" 2>/dev/null; then
      WARNINGS="$WARNINGS\nSTYLE: $file has TODO/FIXME/HACK without an owner tag. Use TODO(name)."
    fi
  done <<< "$CODE_FILES"
fi

if [ -n "$WARNINGS" ]; then
  echo "=== Commit Validation Warnings ===" >&2
  printf '%b\n' "$WARNINGS" >&2
  echo "=================================" >&2
fi

exit 0
