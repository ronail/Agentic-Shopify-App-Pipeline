# session-stop.sh — end-of-session summary

| Field | Value |
| --- | --- |
| Event | SessionEnd |
| Matcher | — |
| Reads | `apps/<slug>/status.md`, `apps/<slug>/approvals.json`, `request-history.md` |
| Writes | appends to `production/session-logs/session-log.md` |
| Blocks | no — always exits 0; a stop hook must never hold the turn open |

## What it does

- Writes an accomplishment summary to stdout and appends the same block to the session log.
- One section per app: stage, last approved gate, open blockers, what changed this session.
- Creates `production/session-logs/` if it is missing.

## Run it

```bash
bash .claude/hooks/session-stop.sh
```

Historic session logs are append-only; nothing here rewrites an earlier entry.
