#!/bin/bash
# Claude Code SessionStart hook: print the pipeline dashboard.
# Renders the same state /start's Phase 2 renders — docs/registry/apps.json plus
# each apps/<slug>/status.md — without duplicating /start's routing, model setup
# or writes. Read-only: never creates an app dir, never edits the registry.
# Works without jq or python3 (pure bash/sed/grep).
set +e

ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -n "$ROOT" ]; then
  cd "$ROOT" || exit 0
fi

REGISTRY="docs/registry/apps.json"
REQUEST="request.md"
HISTORY="request-history.md"
REVIEW_MODE_FILE="production/review-mode.txt"

# --- helpers -----------------------------------------------------------------

json_str() { # json_str '<line>' '<key>'
  printf '%s\n' "$1" | sed -nE 's/.*"'"$2"'"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p'
}

kv() { # kv <file> <Field>: value of a "Field: value" line
  sed -nE "s/^[[:space:]]*$2:[[:space:]]*(.*)$/\1/p" "$1" 2>/dev/null | head -1 | sed -E 's/[[:space:]]+$//'
}

md_table_last_row() { # md_table_last_row <file>
  grep -E '^\|' "$1" 2>/dev/null | grep -vE '^\|[[:space:]]*-' | grep -v 'Version' | tail -1
}

age_days() { # age_days <path>
  local m now
  m=$(stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null) || return 1
  [ -n "$m" ] || return 1
  now=$(date +%s)
  echo $(( (now - m) / 86400 ))
}

next_skill() { # next_skill <stage> <slug>
  case "$1" in
    research)  echo "/research $2" ;;
    prototype) echo "/scaffold $2" ;;
    scope)     echo "/scope-check $2" ;;
    build)     echo "/sprint-plan $2" ;;
    qa)        echo "/qa-plan $2" ;;
    release)   echo "/app-store-checklist $2" ;;
    update)    echo "/update-request $2" ;;
    *)         echo "/project-stage-detect $2" ;;
  esac
}

next_reason() { # next_reason <stage>
  case "$1" in
    research)  echo "research not settled" ;;
    prototype) echo "prototype missing or unreviewed" ;;
    scope)     echo "production scope not set" ;;
    build)     echo "stories in flight" ;;
    qa)        echo "verification outstanding" ;;
    release)   echo "store submission pending" ;;
    update)    echo "live app, updates flowing" ;;
    *)         echo "stage unknown" ;;
  esac
}

# --- static context ----------------------------------------------------------

req_version="?"; req_status="?"
if [ -f "$REQUEST" ]; then
  req_version=$(grep -m1 -E '^Version:' "$REQUEST" | sed -E 's/^Version:[[:space:]]*//')
  req_status=$(grep -m1 -E '^Status:' "$REQUEST" | sed -E 's/^Status:[[:space:]]*//')
fi
[ -n "$req_version" ] || req_version="?"
[ -n "$req_status" ] || req_status="?"

review_mode="lean"
if [ -f "$REVIEW_MODE_FILE" ]; then
  v=$(head -1 "$REVIEW_MODE_FILE" | tr -d '[:space:]')
  [ -n "$v" ] && review_mode="$v"
fi

goal=""
if [ -f "$REQUEST" ]; then
  goal=$(awk '/^## Goal/{f=1;next} f&&/^## /{exit} f&&NF{print; exit}' "$REQUEST" \
    | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
fi

gates_line=$(grep -oE 'gate-[1-5]-[a-z]+' "$REQUEST" 2>/dev/null \
  | awk '!seen[$0]++{printf "%s%s", (n++ ? " > " : ""), $0}')

last_change=""
if [ -f "$HISTORY" ]; then
  row=$(md_table_last_row "$HISTORY")
  if [ -n "$row" ]; then
    last_change=$(printf '%s' "$row" | sed -E 's/^\|[[:space:]]*//; s/[[:space:]]*\|[[:space:]]*/ — /g; s/[[:space:]]*\|$//; s/[[:space:]]*—[[:space:]]*$//')
  fi
fi

# --- registry ----------------------------------------------------------------
# Bash state machine over the pretty-printed registry: no jq/python3 needed.

SLUGS=(); NAMES=(); RSTAGES=(); RGATES=()
cur_slug=""; cur_name=""; cur_stage=""; cur_gate=""

flush_app() {
  [ -n "$cur_slug" ] || return 0
  SLUGS+=("$cur_slug"); NAMES+=("$cur_name")
  RSTAGES+=("$cur_stage"); RGATES+=("$cur_gate")
  cur_slug=""; cur_name=""; cur_stage=""; cur_gate=""
}

if [ -f "$REGISTRY" ]; then
  while IFS= read -r line; do
    # Keys may share a line (pretty-printed or minified), so test each one.
    v=$(json_str "$line" slug)
    if [ -n "$v" ]; then
      flush_app
      cur_slug="$v"
    fi
    v=$(json_str "$line" name);               [ -n "$v" ] && cur_name="$v"
    v=$(json_str "$line" stage);              [ -n "$v" ] && cur_stage="$v"
    v=$(json_str "$line" last_approved_gate); [ -n "$v" ] && cur_gate="$v"
  done < "$REGISTRY"
  flush_app
fi

# --- dashboard ---------------------------------------------------------------

echo "=== Shopify App Pipeline — Dashboard ==="
echo "Master request: $req_version ($req_status) | review mode: $review_mode"
[ -n "$goal" ] && echo "Goal: $goal"
[ -n "$gates_line" ] && echo "Gates: $gates_line"
[ -n "$last_change" ] && echo "Last request change: $last_change"
echo ""

count=${#SLUGS[@]}
if [ "$count" -eq 0 ]; then
  echo "Apps: none registered yet"
  echo ""
  echo "Nothing is in the pipeline. That is the expected starting state."
  echo ""
  echo "NEXT"
  echo "1. /brainstorm open        — find a merchant pain worth an app"
  echo "2. /research <slug>        — validate demand and API access for a known idea"
  echo "======================================="
  exit 0
fi

echo "APPS ($count)"
printf '| %-22s | %-10s | %-18s | %-9s | %-12s | %s\n' "App" "Stage" "Last gate" "Prototype" "Pipeline" "Next"
printf '|%s|%s|%s|%s|%s|%s\n' \
  "------------------------" "------------" "--------------------" "-----------" "--------------" "-----"

DRIFT=()
BLOCKERS=()
NEXT_LINES=()

i=0
while [ "$i" -lt "$count" ]; do
  slug="${SLUGS[$i]}"
  name="${NAMES[$i]}"
  rstage="${RSTAGES[$i]}"
  rgate="${RGATES[$i]}"

  sfile="apps/$slug/status.md"
  sstage=""; sgate=""; sblockers=""
  if [ -f "$sfile" ]; then
    sstage=$(kv "$sfile" "Stage")
    sgate=$(kv "$sfile" "Last approved gate")
    sblockers=$(kv "$sfile" "Blockers")
  fi

  # Stage and gate come from status.md first, registry second (/start's rule).
  stage="$sstage"
  [ -n "$stage" ] || stage="$rstage"
  [ -n "$stage" ] || stage="unknown"

  gate="$sgate"
  [ -n "$gate" ] || gate="$rgate"
  [ -n "$gate" ] || gate="—"

  if [ -n "$sstage" ] && [ -n "$rstage" ] && [ "$sstage" != "$rstage" ]; then
    DRIFT+=("$slug: status.md stage '$sstage' != registry stage '$rstage'")
  fi
  if [ -n "$sgate" ] && [ -n "$rgate" ] && [ "$sgate" != "$rgate" ]; then
    DRIFT+=("$slug: status.md gate '$sgate' != registry gate '$rgate'")
  fi

  proto="empty"
  if [ -d "apps/$slug/prototype" ]; then
    if [ -n "$(find "apps/$slug/prototype" -mindepth 1 -maxdepth 1 ! -name '.gitkeep' 2>/dev/null | head -1)" ]; then
      proto="built"
    fi
  fi

  pipeline="—"
  pdir="production/apps/$slug/session-state"
  if [ -d "$pdir" ]; then
    pn=$(find "$pdir" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "${pn:-0}" -gt 0 ]; then
      newest=$(find "$pdir" -type f 2>/dev/null -exec ls -t {} + 2>/dev/null | head -1)
      ag=$(age_days "$newest" 2>/dev/null)
      pipeline="$pn files / ${ag:-?}d"
    fi
  fi

  printf '| %-22s | %-10s | %-18s | %-9s | %-12s | %s\n' \
    "$slug" "$stage" "$gate" "$proto" "$pipeline" "$(next_skill "$stage" "$slug")"

  if [ -n "$sblockers" ] && [ "$sblockers" != "none" ] && [ "$sblockers" != "-" ]; then
    BLOCKERS+=("$slug: $sblockers")
  fi
  NEXT_LINES+=("$slug — $(next_reason "$stage"): $(next_skill "$stage" "$slug")")

  i=$((i + 1))
done

if [ ${#DRIFT[@]} -gt 0 ]; then
  echo ""
  for d in "${DRIFT[@]}"; do echo "DRIFT: $d"; done
fi

echo ""
echo "BLOCKERS"
if [ ${#BLOCKERS[@]} -eq 0 ]; then
  echo "- none"
else
  for b in "${BLOCKERS[@]}"; do echo "- $b"; done
fi

echo ""
echo "NEXT"
n=1
for line in "${NEXT_LINES[@]}"; do
  echo "$n. $line"
  n=$((n + 1))
done

echo "======================================="
exit 0
