# track-request-changes.sh — request.md edits must be tracked

| Field | Value |
| --- | --- |
| Event | PostToolUse (Write/Edit) |
| Matcher | `request.md` |
| Reads | `request.md`, `request-history.md` |
| Writes | none |
| Blocks | no — PostToolUse cannot block; `exit 2` names the untracked edit after the write |

## What it does

- Rejects an edit to `request.md` that has no matching entry in `request-history.md`.
- Payloads for any other file exit 0 immediately.
- With no payload (direct CLI use) it falls through to a dirty-tree check.

## Run it

```bash
bash .claude/hooks/track-request-changes.sh
```

`request.md` is the source of truth for scope; an untracked edit is why `/scope-check` later argues with itself.
