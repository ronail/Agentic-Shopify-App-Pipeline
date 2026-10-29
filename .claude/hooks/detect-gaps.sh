#!/bin/bash
# Hook: detect-gaps.sh
# Event: SessionStart
# Purpose: report pipeline gaps, not documentation gaps.
#   * registry vs disk drift (docs/registry/apps.json <-> apps/<slug>/)
#   * request.md vs apps/<slug>/status.md stage drift
#   * stalled apps (status.md untouched for GAP_STALE_DAYS)
#   * missing or incomplete gate approvals (apps/<slug>/approvals.json)
#   * request.md edited without a request-history.md entry
# Advisory only: always exits 0 so it can never block a session.
# Graceful without jq or python3.

set +e

ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -n "$ROOT" ]; then
  cd "$ROOT" || exit 0
fi

REGISTRY="docs/registry/apps.json"
REQUEST="request.md"
HISTORY="request-history.md"
STALE_DAYS="${GAP_STALE_DAYS:-14}"

json_str() {
  printf '%s\n' "$1" | sed -nE 's/.*"'"$2"'"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p'
}

kv() { # kv <file> <Field>
  sed -nE "s/^[[:space:]]*$2:[[:space:]]*(.*)$/\1/p" "$1" 2>/dev/null | head -1 | sed -E 's/[[:space:]]+$//'
}

age_days() { # age_days <path>
  local m now
  m=$(stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null) || return 1
  [ -n "$m" ] || return 1
  now=$(date +%s)
  echo $(( (now - m) / 86400 ))
}

# gate_recorded <approvals.json> <gate-id>: true when the gate has a timestamp and an approver.
gate_recorded() {
  local f="$1" g="$2" flat rec
  [ -f "$f" ] || return 1
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$f" "$g" <<'PY' 2>/dev/null
import json, sys
try:
    data = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(1)
rec = data.get(sys.argv[2]) if isinstance(data, dict) else None
if not isinstance(rec, dict):
    sys.exit(1)
ok = bool(str(rec.get("timestamp", "")).strip()) and bool(str(rec.get("approver", "")).strip())
sys.exit(0 if ok else 1)
PY
    return $?
  fi
  flat=$(tr -d '\n' < "$f")
  rec=$(printf '%s' "$flat" | grep -oE "\"$g\"[[:space:]]*:[[:space:]]*\{[^}]*\}" | head -1)
  [ -n "$rec" ] || return 1
  printf '%s' "$rec" | grep -qE '"timestamp"[[:space:]]*:[[:space:]]*"[^"]+"' || return 1
  printf '%s' "$rec" | grep -qE '"approver"[[:space:]]*:[[:space:]]*"[^"]+"' || return 1
  return 0
}

GAPS=()
gap() { GAPS+=("$1"); }

# --- registry ----------------------------------------------------------------

SLUGS=(); RSTAGES=(); RGATES=()
cur_slug=""; cur_stage=""; cur_gate=""
flush_app() {
  [ -n "$cur_slug" ] || return 0
  SLUGS+=("$cur_slug"); RSTAGES+=("$cur_stage"); RGATES+=("$cur_gate")
  cur_slug=""; cur_stage=""; cur_gate=""
}

if [ -f "$REGISTRY" ]; then
  while IFS= read -r line; do
    # Keys may share a line (pretty-printed or minified), so test each one.
    v=$(json_str "$line" slug)
    if [ -n "$v" ]; then flush_app; cur_slug="$v"; fi
    v=$(json_str "$line" stage);              [ -n "$v" ] && cur_stage="$v"
    v=$(json_str "$line" last_approved_gate); [ -n "$v" ] && cur_gate="$v"
  done < "$REGISTRY"
  flush_app
fi

in_registry() {
  local s="$1" i=0
  while [ "$i" -lt "${#SLUGS[@]}" ]; do
    if [ "${SLUGS[$i]}" = "$s" ]; then return 0; fi
    i=$((i + 1))
  done
  return 1
}

# --- request.md stage table --------------------------------------------------

req_stage_for() { # req_stage_for <slug>: stage column of the "Apps in scope" table
  local slug="$1"
  grep -E '^\|' "$REQUEST" 2>/dev/null \
    | grep -F "\`$slug\`" \
    | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $(NF-1)); print $(NF-1); exit}'
}

# --- checks ------------------------------------------------------------------

echo "=== Pipeline Gap Check ==="

if [ "${#SLUGS[@]}" -eq 0 ] && [ ! -d "apps" ]; then
  echo "No apps registered yet. Nothing to check — run /start to see the empty-state dashboard."
  echo "========================="
  exit 0
fi

i=0
while [ "$i" -lt "${#SLUGS[@]}" ]; do
  slug="${SLUGS[$i]}"
  rstage="${RSTAGES[$i]}"
  rgate="${RGATES[$i]}"
  dir="apps/$slug"
  sfile="$dir/status.md"
  afile="$dir/approvals.json"

  if [ ! -d "$dir" ]; then
    gap "GAP: registry lists '$slug' but $dir/ does not exist — create $sfile or drop the registry entry"
    i=$((i + 1))
    continue
  fi

  if [ ! -f "$sfile" ]; then
    gap "GAP: $dir/ has no status.md — every app needs Stage / Last approved gate / Blockers"
    i=$((i + 1))
    continue
  fi

  sstage=$(kv "$sfile" "Stage")
  sgate=$(kv "$sfile" "Last approved gate")

  if [ -z "$sstage" ]; then
    gap "GAP: $sfile has no 'Stage:' line — /start cannot route this app"
  elif [ -n "$rstage" ] && [ "$sstage" != "$rstage" ]; then
    gap "GAP: $slug stage drift — status.md '$sstage' vs registry '$rstage' (pick one and fix the other)"
  fi

  if [ -n "$sgate" ] && [ -n "$rgate" ] && [ "$sgate" != "$rgate" ]; then
    gap "GAP: $slug gate drift — status.md '$sgate' vs registry '$rgate'"
  fi

  rstage_req=$(req_stage_for "$slug")
  if [ -n "$rstage_req" ] && [ -n "$sstage" ] && [ "$rstage_req" != "$sstage" ]; then
    gap "GAP: $slug request.md says '$rstage_req' but status.md says '$sstage'"
  elif [ -z "$rstage_req" ]; then
    gap "GAP: $slug is missing from the request.md '## Apps in scope' table"
  fi

  age=$(age_days "$sfile" 2>/dev/null)
  if [ -n "$age" ] && [ "$age" -gt "$STALE_DAYS" ] 2>/dev/null; then
    gap "STALLED: $slug status.md untouched for ${age}d (limit ${STALE_DAYS}d, stage '$sstage') — run /project-stage-detect $slug"
  fi

  if [ ! -f "$afile" ]; then
    gap "GAP: $slug has no approvals.json — no gate can be verified at $dir/approvals.json"
  else
    for gate in "$sgate" "$rgate"; do
      [ -n "$gate" ] && [ "$gate" != "—" ] || continue
      if ! gate_recorded "$afile" "$gate"; then
        gap "GAP: $slug claims '$gate' but $afile has no recorded approval with timestamp + approver"
      fi
    done
  fi

  i=$((i + 1))
done

# Apps on disk that the registry does not know about.
if [ -d "apps" ]; then
  for d in apps/*/; do
    [ -d "$d" ] || continue
    slug=$(basename "$d")
    if ! in_registry "$slug"; then
      gap "GAP: $d exists but '$slug' is not in $REGISTRY — add it or remove the directory"
    fi
  done
fi

# Request edits that were never tracked.
if [ -f "$REQUEST" ] && [ -f "$HISTORY" ]; then
  if [ "$REQUEST" -nt "$HISTORY" ]; then
    gap "GAP: $REQUEST changed without an entry in $HISTORY — append the version, reason and timestamp"
  fi
elif [ -f "$REQUEST" ] && [ ! -f "$HISTORY" ]; then
  gap "GAP: $REQUEST exists but $HISTORY does not — every change needs a history entry"
fi

# --- summary -----------------------------------------------------------------

if [ "${#GAPS[@]}" -eq 0 ]; then
  echo "✓ No pipeline gaps detected."
else
  echo ""
  for g in "${GAPS[@]}"; do echo "  $g"; done
  echo ""
  echo "${#GAPS[@]} gap(s). Run /start for the full dashboard, /gate-check <app> for approvals."
fi
echo "========================="

exit 0
