# notify.sh — desktop notification

| Field | Value |
| --- | --- |
| Event | Notification |
| Matcher | — |
| Reads | the notification `message` on stdin |
| Writes | none |
| Blocks | no — never fails the turn |

## What it does

- PowerShell toast on Windows, `osascript` on macOS, `notify-send` on Linux, a plain printed line elsewhere.
- Falls back to "Agent needs your attention" when the payload has no message.
- `jq` when present, grep/sed fallback otherwise.

## Run it

```bash
echo '{"message":"App Store checklist is ready"}' | bash .claude/hooks/notify.sh
```

Presentational only; nothing depends on it succeeding.
