#!/usr/bin/env bash
# Agentic Shopify App Pipeline — Status Line
# Receives JSON on stdin, outputs a single-line status.
#
# Segments: ctx% | model | <n> apps @ <furthest stage> | request state | branch

input=$(cat)

# --- Parse JSON (jq with grep fallback) ---
if command -v jq &>/dev/null; then
  model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
  used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
  cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
else
  model=$(echo "$input" | grep -oE '"display_name"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')
  used_pct=$(echo "$input" | grep -oE '"used_percentage"\s*:\s*[0-9]+' | head -1 | sed 's/.*: *//')
  cwd=$(echo "$input" | grep -oE '"current_dir"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')
  [ -z "$model" ] && model="Unknown"
fi

# Normalize Windows paths
cwd=$(echo "$cwd" | sed 's|\\|/|g')
[ -z "$cwd" ] && cwd="."

# --- Context usage ---
if [ -n "$used_pct" ]; then
  ctx_label="ctx: ${used_pct}%"
else
  ctx_label="ctx: --"
fi

# --- Pipeline state: how many apps, how far the furthest one has got ---
registry="$cwd/docs/registry/apps.json"
app_count=0
if [ -f "$registry" ]; then
  app_count=$(grep -o '"slug"' "$registry" 2>/dev/null | wc -l | tr -d ' ')
fi

# stage ranks match the pipeline in README.md
stage_rank() {
  case "$1" in
    research) echo 1 ;;
    architecture) echo 2 ;;
    prototype) echo 3 ;;
    scope) echo 4 ;;
    build) echo 5 ;;
    test) echo 6 ;;
    release) echo 7 ;;
    monitor) echo 8 ;;
    *) echo 0 ;;
  esac
}

best_rank=0
best_stage=""
if [ -d "$cwd/apps" ]; then
  for status_file in "$cwd"/apps/*/status.md; do
    [ -f "$status_file" ] || continue
    stage=$(grep -m1 -E '^Stage:' "$status_file" 2>/dev/null | sed 's/^Stage:[[:space:]]*//' | tr -d '\r')
    [ -z "$stage" ] && continue
    rank=$(stage_rank "$stage")
    if [ "$rank" -gt "$best_rank" ]; then
      best_rank=$rank
      best_stage=$stage
    fi
  done
fi

if [ "$app_count" -gt 0 ] 2>/dev/null; then
  if [ -n "$best_stage" ]; then
    pipeline_label="${app_count} apps @ ${best_stage}"
  else
    pipeline_label="${app_count} apps"
  fi
else
  pipeline_label="no apps"
fi

# --- Request state: /start routes on this ---
if [ -f "$cwd/request.md" ]; then
  request_label="request: set"
else
  request_label="request: none"
fi

# --- Branch (best effort; empty outside a git repo) ---
branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null | tr -d '\r')
[ -z "$branch" ] || [ "$branch" = "HEAD" ] && branch=""

# --- Assemble ---
if [ -n "$branch" ]; then
  printf "%s" "${ctx_label} | ${model} | ${pipeline_label} | ${request_label} | ${branch}"
else
  printf "%s" "${ctx_label} | ${model} | ${pipeline_label} | ${request_label}"
fi
