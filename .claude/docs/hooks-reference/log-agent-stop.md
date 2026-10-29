# log-agent-stop.sh — subagent stop audit record

| Field | Value |
| --- | --- |
| Event | SubagentStop |
| Matcher | — |
| Reads | the event payload |
| Writes | appends to `production/session-logs/agent-audit.log` |
| Blocks | no |

## What it does

- Completes the subagent record started by the SubagentStart hook.
- Same `agent_type` parsing and `jq` fallback as the start record.
- Used to spot agents that were dispatched and never reported back.

## Run it

```bash
echo '{"agent_type":"producer"}' | bash .claude/hooks/log-agent-stop.sh
```

Audit trail only — never inspected by any gate.
