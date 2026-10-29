#!/usr/bin/env bash
# post-compact.sh — fires after conversation compaction.
# Reminds the agent to restore pipeline context from the file-backed checkpoints:
# apps/<slug>/status.md, request.md and production/apps/<app>/session-state/.

set +e

ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -n "$ROOT" ]; then
  cd "$ROOT" || exit 0
fi

echo "=== Context Restored After Compaction ==="

FOUND=0
for ACTIVE in production/apps/*/session-state/active.md; do
  [ -f "$ACTIVE" ] || continue
  FOUND=$((FOUND + 1))
  SIZE=$(wc -l < "$ACTIVE" 2>/dev/null | tr -d ' ')
  echo "Session state: $ACTIVE (${SIZE:-?} lines) — read it to restore the app in flight."
done

if [ "$FOUND" -eq 0 ]; then
  echo "No per-app session state found under production/apps/<app>/session-state/."
  echo "If you were mid-task, read apps/*/status.md and the last block of"
  echo "production/session-logs/session-log.md instead."
fi

if [ -f request.md ]; then
  echo "Master request: request.md (current version is the 'Version:' line)."
fi
if [ -f request-history.md ]; then
  last=$(grep -E '^\|' request-history.md 2>/dev/null | grep -v 'Version' | tail -1 \
    | sed -E 's/^\|[[:space:]]*//; s/[[:space:]]*\|[[:space:]]*/ — /g; s/[[:space:]]*\|$//; s/[[:space:]]*—[[:space:]]*$//')
  [ -n "$last" ] && echo "Last request change: $last"
fi

echo "========================================="
exit 0
