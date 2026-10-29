# log-agent.sh — subagent start audit record

| Field | Value |
| --- | --- |
| Event | SubagentStart |
| Matcher | — |
| Reads | the event payload |
| Writes | appends to `production/session-logs/agent-audit.log` |
| Blocks | no |

## What it does

- Logs `agent_type` plus a timestamp when a subagent is spawned.
- Reads `agent_type` — not `agent_name`, which is null on every invocation.
- grep/sed fallback when `jq` is absent.

## Run it

```bash
echo '{"agent_type":"producer"}' | bash .claude/hooks/log-agent.sh
```

Paired with the SubagentStop record; one without the other means a subagent that never returned.
