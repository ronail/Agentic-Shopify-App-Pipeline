# validate-skill-change.sh — remind to test a changed skill

| Field | Value |
| --- | --- |
| Event | PostToolUse (Write/Edit) |
| Matcher | any path under `.claude/skills/` |
| Reads | the written path on stdin |
| Writes | none |
| Blocks | no — advisory, exits 0 |

## What it does

- Names the edited skill and says to run `/skill-test static <skill>` before committing.
- Fires on any file inside the skill directory, not just `SKILL.md`.
- Payloads for paths outside `.claude/skills/` exit 0 silently.

## Run it

```bash
echo '{"tool_input":{"file_path":".claude/skills/help/SKILL.md"}}' | bash .claude/hooks/validate-skill-change.sh
```

Cheap nudge, not a gate — a skill edit that is not re-tested is the usual source of silent drift.
