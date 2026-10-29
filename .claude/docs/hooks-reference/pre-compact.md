# pre-compact.sh — dump pipeline state before compaction

| Field | Value |
| --- | --- |
| Event | PreCompact |
| Matcher | — |
| Reads | `production/apps/<app>/session-state/active.md`, `apps/<slug>/status.md`, `request.md`, `request-history.md` |
| Writes | none |
| Blocks | no |

## What it does

- Prints per-app session state, app stages, modified files, WIP markers and the last request change into the conversation.
- Runs immediately before summarisation so the working state survives compression.
- Sources are the pipeline's own files, not a single state file.

## Run it

```bash
bash .claude/hooks/pre-compact.sh
```

If the output is empty, the session had no app state to lose — not an error.
