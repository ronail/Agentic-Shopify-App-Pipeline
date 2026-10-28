#!/usr/bin/env bash
# Codex PostToolUse advisory for edits to the project's Claude-compatible
# skills. Codex-aware path extraction supports both apply_patch and Bash edits.

INPUT=$(cat)

if command -v jq >/dev/null 2>&1; then
    TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
    FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
    PATCH=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
else
    TOOL_NAME=$(printf '%s' "$INPUT" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
    FILE_PATH=$(printf '%s' "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
    PATCH=""
fi

FILE_PATHS="$FILE_PATH"
if [ -z "$FILE_PATHS" ] && [ "$TOOL_NAME" = "apply_patch" ] && [ -n "$PATCH" ]; then
    FILE_PATHS=$(printf '%s\n' "$PATCH" | sed -n -E \
        -e 's/^\*\*\* (Add|Update|Delete) File: //p' \
        -e 's/^\+\+\+ b\/(.*)$/\1/p' \
        -e 's/^\+\+\+ (.*)$/\1/p')
fi
if [ -z "$FILE_PATHS" ]; then
    FILE_PATHS=$( {
        git diff --name-only 2>/dev/null
        git diff --cached --name-only 2>/dev/null
        git ls-files --others --exclude-standard 2>/dev/null
    } | sort -u )
fi

while IFS= read -r FILE_PATH; do
    FILE_PATH=$(printf '%s' "$FILE_PATH" | sed 's|\\|/|g')
    case "$FILE_PATH" in
        .claude/skills/*|*/.claude/skills/*)
            SKILL_NAME=$(printf '%s' "$FILE_PATH" | sed -E 's|.*\.claude/skills/([^/]+).*|\1|')
            printf '=== Skill Modified: %s ===\n' "$SKILL_NAME" >&2
            printf 'Run /skill-test static %s to validate structural compliance.\n' "$SKILL_NAME" >&2
            printf '%s\n' '====================================' >&2
            ;;
    esac
done <<< "$FILE_PATHS"

exit 0
