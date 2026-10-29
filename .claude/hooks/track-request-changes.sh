#!/usr/bin/env bash
# Enforce that edits to request.md are tracked in request-history.md.
# PostToolUse hook: exit 2 reports an untracked edit by name (the write has
# already landed — Claude Code / Codex only block on PreToolUse), exit 0 for
# every other file. Run from anywhere inside the repo.
set -euo pipefail

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo .)
cd "$ROOT"

request="request.md"
history="request-history.md"

# Only gate an edit to request.md itself. A payload for any other file exits 0;
# with no payload (direct CLI use) fall through to the dirty-tree check below.
FILE_PATH=""
if [ ! -t 0 ]; then
  INPUT=$(cat 2>/dev/null || true)
  if [ -n "$INPUT" ]; then
    if command -v jq >/dev/null 2>&1; then
      FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // .file_path // empty' 2>/dev/null || true)
    fi
    if [ -z "$FILE_PATH" ]; then
      FILE_PATH=$(printf '%s' "$INPUT" | grep -oE '"(file_path|path)"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 \
        | sed -E 's/^"(file_path|path)"[[:space:]]*:[[:space:]]*"//; s/"$//' || true)
    fi
  fi
fi

if [ -n "$FILE_PATH" ]; then
  FILE_PATH=$(printf '%s' "$FILE_PATH" | sed 's|\\|/|g')
  # `-ef` compares device+inode, so a symlinked cwd (/var vs /private/var, or a
  # symlinked checkout) still resolves to the repo root's request.md.
  if [ "$(basename "$FILE_PATH")" != "$request" ] || [ ! "$(dirname "$FILE_PATH")" -ef "$ROOT" ]; then
    exit 0
  fi
fi

[ -f "$request" ] || exit 0
[ -f "$history" ] || {
  echo "BLOCKED: $request exists but $history does not. Create it and log the change." >&2
  exit 2
}

block() {
  echo "BLOCKED: $request changed but $history was not updated." >&2
  echo "Add an entry to $history (version, reason, timestamp) in the same working tree." >&2
  exit 2
}

is_tracked() { git ls-files --error-unmatch -- "$1" >/dev/null 2>&1; }
changed() { ! git diff --quiet -- "$1" 2>/dev/null || ! git diff --cached --quiet -- "$1" 2>/dev/null; }

if is_tracked "$request" && is_tracked "$history"; then
  if changed "$request" && ! changed "$history"; then block; fi
else
  # ponytail: mtime heuristic while either file is uncommitted; tightens to git diff once both are tracked
  if [ "$request" -nt "$history" ]; then block; fi
fi

exit 0
