#!/usr/bin/env bash
# Codex PostToolUse validator for changed files under assets/.
# PostToolUse cannot undo an already-applied edit, so failures are reported as
# actionable diagnostics while the pre-tool command policy remains blocking.

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

# Bash edits and new files may not appear in a patch payload; inspect the
# working tree as a fallback. Sorting also removes duplicate paths.
if [ -z "$FILE_PATHS" ]; then
    FILE_PATHS=$( {
        git diff --name-only 2>/dev/null
        git diff --cached --name-only 2>/dev/null
        git ls-files --others --exclude-standard 2>/dev/null
    } | sort -u )
fi

WARNINGS=""
ERRORS=""
while IFS= read -r FILE_PATH; do
    [ -n "$FILE_PATH" ] || continue
    FILE_PATH=$(printf '%s' "$FILE_PATH" | sed 's|\\|/|g')
    case "$FILE_PATH" in
        assets/*|*/assets/*) ;;
        *) continue ;;
    esac

    FILENAME=$(basename "$FILE_PATH")
    if printf '%s' "$FILENAME" | grep -qE '[A-Z[:space:]-]'; then
        WARNINGS="$WARNINGS\n  NAMING: $FILE_PATH must be lowercase with underscores (got: $FILENAME)"
    fi

    case "$FILE_PATH" in
        assets/data/*.json|*/assets/data/*.json)
            if [ -f "$FILE_PATH" ] && command -v python3 >/dev/null 2>&1 \
                && ! python3 -m json.tool "$FILE_PATH" >/dev/null 2>&1; then
                ERRORS="$ERRORS\n  FORMAT: $FILE_PATH is not valid JSON"
            fi
            ;;
    esac
done <<< "$FILE_PATHS"

if [ -n "$WARNINGS" ]; then
    printf '%b\n' "=== Asset Validation: Warnings ===$WARNINGS\n==================================" >&2
fi
if [ -n "$ERRORS" ]; then
    printf '%b\n' "=== Asset Validation: Errors ===$ERRORS\n===============================" >&2
fi

exit 0
