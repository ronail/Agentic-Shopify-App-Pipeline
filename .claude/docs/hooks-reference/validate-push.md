# validate-push.sh — protected-branch warning

| Field | Value |
| --- | --- |
| Event | PreToolUse (Bash) |
| Matcher | `git push` |
| Reads | the command string on stdin |
| Writes | none |
| Blocks | no — warns only, exits 0 |

## What it does

- Detects a push to `develop`, `main` or `master` (explicit ref or a bare `git push` on that branch).
- Prints the branch and the reminder to open a PR instead of pushing to a protected branch.
- Deliberately never blocks: a release manager may need the push.

## Run it

```bash
echo '{"tool_input":{"command":"git push origin main"}}' | bash .claude/hooks/validate-push.sh
```

Only command strings starting with `git push` are inspected.
