# validate-commit.sh — commit-time invariants

| Field | Value |
| --- | --- |
| Event | PreToolUse (Bash) |
| Matcher | `git commit` |
| Reads | staged paths (`git diff --cached --name-only`) |
| Writes | none |
| Blocks | yes — `exit 2` blocks the commit |

## What it does

- Blocking: every staged `.json` file must parse.
- Blocking: staged `apps/<app>/approvals.json` records need `id`, `timestamp` and `approver`.
- Blocking: a staged `request.md` requires a staged `request-history.md`.
- Advisory: staged `apps/<app>/status.md` must keep a `Stage:` line.
- Advisory: staged `TODO`/`FIXME`/`HACK` should carry an owner tag.

## Run it

```bash
echo '{"tool_input":{"command":"git commit -m \"x\""}}' | bash .claude/hooks/validate-commit.sh
```

Any non-commit Bash command exits 0 untouched. Graceful without `jq`/`python3`.
