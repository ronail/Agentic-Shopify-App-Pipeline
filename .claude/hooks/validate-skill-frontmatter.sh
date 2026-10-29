#!/bin/bash
# Claude Code PostToolUse hook: validate YAML frontmatter on skill and agent definitions.
# Replaces the old game-asset validator. Checks, per file:
#   * a frontmatter block exists (line 1 is ---)
#   * name: and description: are present and non-empty
#   * model: is present and is one of haiku|sonnet|opus
#   * agent: <name> resolves to .claude/agents/<name>.md
#   * skills: [...] entries resolve to .claude/skills/<name>/SKILL.md  (advisory)
#
# Modes:
#   stdin hook (Write|Edit) -> validates the touched file when it is a SKILL.md or an agent .md
#   --all                   -> validates every skill and agent definition in the repo
#
# Exit behavior:
#   exit 0 = clean, or advisory warnings only
#   exit 2 = frontmatter error (reported after the write: PostToolUse cannot block)
# Graceful without jq or python3.

set +e

HOOK="validate-skill-frontmatter.sh"
ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -n "$ROOT" ]; then
  cd "$ROOT" || exit 0
fi

SCAN_ALL=0
for arg in "$@"; do
  case "$arg" in
    --all|-a) SCAN_ALL=1 ;;
  esac
done

frontmatter() { # frontmatter <file>: the block between the first two --- lines
  awk 'NR==1 && /^---[ \t\r]*$/ {f=1; next} f && /^---[ \t\r]*$/ {exit} f {print}' "$1" 2>/dev/null
}

rel_path() { # rel_path <path>: repo-relative form
  printf '%s' "$1" | sed -E 's|^.*(/\.claude/)|\1|; s|^\./||; s|\\|/|g'
}

# --- collect targets ---------------------------------------------------------

TARGETS=()

if [ "$SCAN_ALL" -eq 1 ]; then
  for f in .claude/skills/*/SKILL.md .claude/agents/*.md; do
    [ -f "$f" ] && TARGETS+=("$f")
  done
else
  INPUT=""
  if [ ! -t 0 ]; then
    INPUT=$(cat 2>/dev/null)
  fi

  FILE_PATH=""
  if [ -n "$INPUT" ]; then
    if command -v jq >/dev/null 2>&1; then
      FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // .file_path // empty' 2>/dev/null)
    fi
    if [ -z "$FILE_PATH" ]; then
      FILE_PATH=$(printf '%s' "$INPUT" | grep -oE '"(file_path|path)"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 \
        | sed -E 's/^"(file_path|path)"[[:space:]]*:[[:space:]]*"//; s/"$//')
    fi
  fi

  FILE_PATH=$(printf '%s' "$FILE_PATH" | sed 's|\\|/|g')
  if [ -n "$FILE_PATH" ]; then
    REL=$(rel_path "$FILE_PATH")
    case "$REL" in
      .claude/agents/*.md)       TARGETS+=("$REL") ;;
      .claude/skills/*/SKILL.md) TARGETS+=("$REL") ;;
    esac
  fi
fi

if [ "${#TARGETS[@]}" -eq 0 ]; then
  exit 0
fi

# --- validate ----------------------------------------------------------------

ERRORS=""

for f in "${TARGETS[@]}"; do
  [ -f "$f" ] || continue

  first=$(head -1 "$f" 2>/dev/null | tr -d '\r')
  if [ "$first" != "---" ]; then
    ERRORS="$ERRORS\n  NOFRONT: $f — line 1 must be '---' (frontmatter block missing)"
    continue
  fi

  FM=$(frontmatter "$f" | tr -d '\r')
  if [ -z "$FM" ]; then
    ERRORS="$ERRORS\n  NOFRONT: $f — frontmatter block is empty"
    continue
  fi

  name=$(printf '%s\n' "$FM" | sed -nE 's/^name:[[:space:]]*(.*)$/\1/p' | head -1 | sed -E 's/^"(.*)"$/\1/')
  desc=$(printf '%s\n' "$FM" | sed -nE 's/^description:[[:space:]]*(.*)$/\1/p' | head -1)
  model=$(printf '%s\n' "$FM" | sed -nE 's/^model:[[:space:]]*(.*)$/\1/p' | head -1 | tr -d '"' | tr -d '[:space:]')
  agent_ref=$(printf '%s\n' "$FM" | sed -nE 's/^agent:[[:space:]]*(.*)$/\1/p' | head -1 | tr -d '"' | tr -d '[:space:]')

  [ -n "$name" ] || ERRORS="$ERRORS\n  NAME: $f has no 'name:' field"
  [ -n "$desc" ] || ERRORS="$ERRORS\n  DESCRIPTION: $f has no 'description:' field"

  if [ -z "$model" ]; then
    ERRORS="$ERRORS\n  MODEL: $f has no 'model:' field (expected haiku|sonnet|opus)"
  elif ! printf '%s' "$model" | grep -qE '^(haiku|sonnet|opus)$'; then
    ERRORS="$ERRORS\n  MODEL: $f declares model '$model' — expected haiku|sonnet|opus"
  fi

  if [ -n "$agent_ref" ] && [ ! -f ".claude/agents/${agent_ref}.md" ]; then
    ERRORS="$ERRORS\n  AGENT-REF: $f points at agent '$agent_ref' but .claude/agents/${agent_ref}.md does not exist"
  fi

  # Advisory: skills: [a, b] on an agent should name real skills.
  skill_refs=$(printf '%s\n' "$FM" | sed -nE 's/^skills:[[:space:]]*\[(.*)\][[:space:]]*$/\1/p' | head -1)
  if [ -n "$skill_refs" ]; then
    printf '%s' "$skill_refs" | tr ',' '\n' | while IFS= read -r s; do
      s=$(printf '%s' "$s" | tr -d " []\"'")
      [ -n "$s" ] || continue
      if [ ! -f ".claude/skills/$s/SKILL.md" ]; then
        echo "WARN [$HOOK]: $f references skill '$s' with no .claude/skills/$s/SKILL.md" >&2
      fi
    done
  fi
done

if [ -n "$ERRORS" ]; then
  echo "=== $HOOK: ERRORS (Blocking) ===" >&2
  printf '%b\n' "$ERRORS" >&2
  echo "Fix the frontmatter before continuing — an invalid definition will not load." >&2
  echo "=============================" >&2
  exit 2
fi

exit 0
