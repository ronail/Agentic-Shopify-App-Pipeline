# validate-skill-frontmatter.sh — skill and agent frontmatter

| Field | Value |
| --- | --- |
| Event | PostToolUse (Write/Edit) |
| Matcher | `SKILL.md` or `.claude/agents/*.md` |
| Reads | the written file, `.claude/agents/`, `.claude/skills/` |
| Writes | none |
| Blocks | no — PostToolUse cannot block; `exit 2` reports the error after the write |

## What it does

- Requires a frontmatter block (line 1 is `---`), non-empty `name:` and `description:`.
- Requires `model:` to be one of `haiku`, `sonnet`, `opus`.
- Requires every `agent:` reference to resolve to `.claude/agents/<name>.md`.
- Advisory: every entry in `skills: [...]` must resolve to `.claude/skills/<name>/SKILL.md`.

## Run it

```bash
bash .claude/hooks/validate-skill-frontmatter.sh --all
```

`--all` sweeps the whole repo; stdin mode validates just the touched file. The sweep is how R7 proves all 31 agents and 66 skills are well-formed.
