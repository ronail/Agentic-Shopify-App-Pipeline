#!/bin/bash
# Claude Code SessionEnd hook: write the end-of-session accomplishment summary.
# The summary is built from pipeline state — apps/<slug>/status.md,
# apps/<slug>/approvals.json and request-history.md — and appended to the
# session log. It no longer archives a game session-state file.
#
# Exit 0 always: a Stop hook must never block the turn from finishing.

set +e

ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -n "$ROOT" ]; then
  cd "$ROOT" || exit 0
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SESSION_LOG_DIR="production/session-logs"
SESSION_LOG="$SESSION_LOG_DIR/session-log.md"
mkdir -p "$SESSION_LOG_DIR" 2>/dev/null

emit_summary() {
  echo "## Pipeline Session End: $TIMESTAMP"

  # --- Apps whose state moved ------------------------------------------------
  echo "### App State Touched"
  touched=$( {
      git diff --name-only 2>/dev/null
      git diff --cached --name-only 2>/dev/null
      git ls-files --others --exclude-standard 2>/dev/null
    } | grep -E '^apps/[^/]+/(status\.md|approvals\.json)$' | sort -u )

  if [ -n "$touched" ]; then
    printf '%s\n' "$touched" | while IFS= read -r f; do
      slug=$(printf '%s' "$f" | sed -E 's|^apps/([^/]+)/.*|\1|')
      stage=$(sed -nE 's/^[[:space:]]*Stage:[[:space:]]*(.*)$/\1/p' "apps/$slug/status.md" 2>/dev/null | head -1)
      gate=$(sed -nE 's/^[[:space:]]*Last approved gate:[[:space:]]*(.*)$/\1/p' "apps/$slug/status.md" 2>/dev/null | head -1)
      echo "  - $slug (stage: ${stage:-unknown}, last gate: ${gate:-none}) — $f"
    done
  else
    # Fall back to status files edited in this sitting even if the tree is clean.
    recent=$(find apps -mindepth 2 -maxdepth 2 -name status.md -newermt '-6 hours' 2>/dev/null | sort)
    if [ -n "$recent" ]; then
      printf '%s\n' "$recent" | while IFS= read -r f; do
        slug=$(printf '%s' "$f" | sed -E 's|^apps/([^/]+)/.*|\1|')
        stage=$(sed -nE 's/^[[:space:]]*Stage:[[:space:]]*(.*)$/\1/p' "$f" 2>/dev/null | head -1)
        echo "  - $slug (stage: ${stage:-unknown}) — status.md updated recently"
      done
    else
      echo "  (no app status or approvals files changed)"
    fi
  fi

  # --- Request history -------------------------------------------------------
  echo "### Last Request Change"
  if [ -f "request-history.md" ]; then
    row=$(grep -E '^\|' request-history.md 2>/dev/null | grep -vE '^\|[[:space:]]*-' | grep -v 'Version' | tail -1 \
      | sed -E 's/^\|[[:space:]]*//; s/[[:space:]]*\|[[:space:]]*/ — /g; s/[[:space:]]*\|$//; s/[[:space:]]*—[[:space:]]*$//')
    if [ -n "$row" ]; then
      echo "  $row"
    else
      echo "  (request-history.md has no entries)"
    fi
  else
    echo "  (no request-history.md)"
  fi

  # --- Git activity ----------------------------------------------------------
  commits=$(git log --oneline --since="8 hours ago" 2>/dev/null)
  modified=$(git diff --name-only 2>/dev/null)
  staged=$(git diff --cached --name-only 2>/dev/null)

  echo "### Commits (last 8h)"
  if [ -n "$commits" ]; then
    printf '%s\n' "$commits" | sed 's/^/  /'
  else
    echo "  (none)"
  fi

  echo "### Uncommitted Changes"
  if [ -n "$modified" ] || [ -n "$staged" ]; then
    { printf '%s\n' "$modified"; printf '%s\n' "$staged"; } | grep -v '^$' | sort -u | sed 's/^/  - /'
  else
    echo "  (none)"
  fi

  echo "---"
  echo ""
}

TMP_SUMMARY=$(mktemp "${TMPDIR:-/tmp}/pipeline-session-summary.XXXXXX" 2>/dev/null)
[ -n "$TMP_SUMMARY" ] || TMP_SUMMARY="${TMPDIR:-/tmp}/pipeline-session-summary.$$"

emit_summary > "$TMP_SUMMARY" 2>/dev/null

cat "$TMP_SUMMARY" 2>/dev/null
cat "$TMP_SUMMARY" >> "$SESSION_LOG" 2>/dev/null
rm -f "$TMP_SUMMARY" 2>/dev/null

exit 0
