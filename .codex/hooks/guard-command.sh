#!/usr/bin/env bash
# Codex PreToolUse guard for restrictions that are broader than a prefix rule.
# Exit 2 blocks the pending Bash call; all other calls are allowed.

INPUT=$(cat)

if command -v jq >/dev/null 2>&1; then
    COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
else
    COMMAND=$(printf '%s' "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' | sed 's/\\"/"/g')
fi

[ -z "$COMMAND" ] && exit 0

is_protected_branch_push() {
    local current_branch
    current_branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)
    [[ "$current_branch" == "main" || "$current_branch" == "master" ]]
}

REASON=""
if [[ "$COMMAND" =~ rm[[:space:]]+(-rf|-fr)([[:space:]]|$) ]] \
    || [[ "$COMMAND" =~ rm[[:space:]]+(-r[[:space:]]+-f|-f[[:space:]]+-r|--recursive[[:space:]]+--force|--force[[:space:]]+--recursive)([[:space:]]|$) ]]; then
    REASON="recursive force deletion"
elif [[ "$COMMAND" =~ git[[:space:]]+push([[:space:]]|$) ]] \
    && [[ "$COMMAND" =~ (--force([[:space:]]|[-]|$)|[[:space:]]-f([[:space:]]|$)) ]]; then
    if [[ "$COMMAND" == *"--force-with-lease"* ]] && ! is_protected_branch_push; then
        :
    else
        REASON="force-pushing"
    fi
elif [[ "$COMMAND" =~ git[[:space:]]+reset[[:space:]]+--hard([[:space:]]|$) ]]; then
    REASON="hard reset"
elif [[ "$COMMAND" =~ git[[:space:]]+clean[[:space:]]+-f ]]; then
    REASON="forced clean"
elif [[ "$COMMAND" =~ sudo([[:space:]]|$) ]]; then
    REASON="privilege escalation"
elif [[ "$COMMAND" =~ chmod[[:space:]]+777([[:space:]]|$) ]]; then
    REASON="world-writable permissions"
elif [[ "$COMMAND" == *".env"* ]]; then
    REASON="accessing an environment file"
fi

if [ -n "$REASON" ]; then
    echo "BLOCKED: $REASON is forbidden by the project Codex policy." >&2
    exit 2
fi

exit 0
