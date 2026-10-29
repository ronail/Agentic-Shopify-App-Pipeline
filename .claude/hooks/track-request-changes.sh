#!/usr/bin/env bash
# Enforce that edits to request.md are tracked in request-history.md.
# Non-zero exit blocks the edit. Run from anywhere inside the repo.
set -euo pipefail

cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

request="request.md"
history="request-history.md"

[ -f "$request" ] || exit 0
[ -f "$history" ] || {
  echo "BLOCKED: $request exists but $history does not. Create it and log the change." >&2
  exit 1
}

block() {
  echo "BLOCKED: $request changed but $history was not updated." >&2
  echo "Add an entry to $history (version, reason, timestamp) in the same working tree." >&2
  exit 1
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
