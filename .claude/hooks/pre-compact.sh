#!/bin/bash
# Claude Code PreCompact hook: dump pipeline state before context compression.
# The output lands in the conversation right before compaction so the working
# state survives summarisation. Sources are the pipeline's own files —
# apps/<slug>/status.md, per-app session state under production/apps/<slug>/
# and request-history.md — not a single game state file.

set +e

ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -n "$ROOT" ]; then
  cd "$ROOT" || exit 0
fi

echo "=== SESSION STATE BEFORE COMPACTION ==="
echo "Timestamp: $(date)"

# --- Per-app session state ---------------------------------------------------
echo ""
echo "## App Session State"

FOUND_STATE=0
for STATE_FILE in production/apps/*/session-state/active.md; do
  [ -f "$STATE_FILE" ] || continue
  FOUND_STATE=1
  echo ""
  echo "### $STATE_FILE"
  STATE_LINES=$(wc -l < "$STATE_FILE" 2>/dev/null | tr -d ' ')
  if [ "${STATE_LINES:-0}" -gt 100 ] 2>/dev/null; then
    head -n 100 "$STATE_FILE"
    echo "... (truncated — $STATE_LINES total lines, showing first 100)"
  else
    cat "$STATE_FILE"
  fi
done

if [ "$FOUND_STATE" -eq 0 ]; then
  echo "  (no production/apps/<app>/session-state/active.md found)"
  echo "  Keep one per app in flight so a compaction does not lose the thread."
fi

# --- App stages --------------------------------------------------------------
echo ""
echo "## App Stages"
STAGES_FOUND=0
for f in apps/*/status.md; do
  [ -f "$f" ] || continue
  STAGES_FOUND=1
  slug=$(printf '%s' "$f" | sed -E 's|^apps/([^/]+)/.*|\1|')
  stage=$(sed -nE 's/^[[:space:]]*Stage:[[:space:]]*(.*)$/\1/p' "$f" 2>/dev/null | head -1)
  gate=$(sed -nE 's/^[[:space:]]*Last approved gate:[[:space:]]*(.*)$/\1/p' "$f" 2>/dev/null | head -1)
  echo "  - $slug: stage ${stage:-unknown}, last gate ${gate:-none}"
done
if [ "$STAGES_FOUND" -eq 0 ]; then
  echo "  (no apps/<slug>/status.md found)"
fi

# --- Files modified this session --------------------------------------------
echo ""
echo "## Files Modified (git working tree)"

CHANGED=$(git diff --name-only 2>/dev/null)
STAGED=$(git diff --staged --name-only 2>/dev/null)
UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null)

if [ -n "$CHANGED" ]; then
  echo "Unstaged changes:"
  printf '%s\n' "$CHANGED" | while read -r f; do echo "  - $f"; done
fi
if [ -n "$STAGED" ]; then
  echo "Staged changes:"
  printf '%s\n' "$STAGED" | while read -r f; do echo "  - $f"; done
fi
if [ -n "$UNTRACKED" ]; then
  echo "New untracked files:"
  printf '%s\n' "$UNTRACKED" | while read -r f; do echo "  - $f"; done
fi
if [ -z "$CHANGED" ] && [ -z "$STAGED" ] && [ -z "$UNTRACKED" ]; then
  echo "  (no uncommitted changes)"
fi

# --- Work in progress --------------------------------------------------------
echo ""
echo "## Work In Progress"

WIP_FOUND=false
for f in apps/*/status.md request.md request-history.md; do
  [ -f "$f" ] || continue
  INCOMPLETE=$(grep -nE "TODO|WIP|PLACEHOLDER|\[TO BE|\[TBD\]" "$f" 2>/dev/null)
  if [ -n "$INCOMPLETE" ]; then
    WIP_FOUND=true
    echo "  $f:"
    printf '%s\n' "$INCOMPLETE" | while read -r line; do echo "    $line"; done
  fi
done
if [ "$WIP_FOUND" = false ]; then
  echo "  (no WIP markers found in app status or request files)"
fi

# --- Log compaction event ----------------------------------------------------
SESSION_LOG_DIR="production/session-logs"
mkdir -p "$SESSION_LOG_DIR" 2>/dev/null
echo "Context compaction occurred at $(date)." >> "$SESSION_LOG_DIR/compaction-log.txt" 2>/dev/null

echo ""
echo "## Recovery Instructions"
echo "After compaction, re-read docs/registry/apps.json, the app status.md files named above,"
echo "and production/apps/<app>/session-state/active.md for the app in flight."
echo "=== END SESSION STATE ==="

exit 0
