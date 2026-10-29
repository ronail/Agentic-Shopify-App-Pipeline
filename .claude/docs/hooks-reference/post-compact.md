# post-compact.sh — point back at the checkpoints after compaction

| Field | Value |
| --- | --- |
| Event | PostCompact |
| Matcher | — |
| Reads | `production/apps/*/session-state/active.md`, `apps/<slug>/status.md`, `request.md` |
| Writes | none |
| Blocks | no |

## What it does

- Lists each surviving session-state file with its line count and says to read it to restore the app in flight.
- Points at `request.md` and the last `request-history.md` row.
- Complements the pre-compaction dump: one captures, the other recovers.

## Run it

```bash
bash .claude/hooks/post-compact.sh
```

Recovery is a pointer, not a summary — the agent still has to read the files.
