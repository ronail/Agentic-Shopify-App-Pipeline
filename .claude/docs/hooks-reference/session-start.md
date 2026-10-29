# session-start.sh — session dashboard

| Field | Value |
| --- | --- |
| Event | SessionStart |
| Matcher | — |
| Reads | `docs/registry/apps.json`, `apps/<slug>/status.md`, `request.md`, `request-history.md`, `production/review-mode.txt` |
| Writes | none (read-only) |
| Blocks | no — always exits 0 |

## What it does

- Prints the same dashboard `/start` renders: one block per registered app with stage, last approved gate, prototype, pipeline files, next skill, drift and blockers.
- Reads the registry and status files; it never creates an app directory and never edits `docs/registry/apps.json`.
- Pure bash/sed/grep — works with no `jq` and no `python3`.

## Run it

```bash
bash .claude/hooks/session-start.sh
```

Silent when `docs/registry/apps.json` is missing or empty — a fresh clone gets no noise.
