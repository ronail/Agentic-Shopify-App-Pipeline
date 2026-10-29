# Agentic Shopify App Pipeline

## Codex pipeline-agent spawning

When Codex spawns a pipeline agent, use the agent definition in
`.claude/agents/<agent-name>.md` as the source of truth. Read its YAML
frontmatter `model` field and resolve that shared tier through
`.codex/agent-models.toml` before creating the subagent.

Pass the resolved Codex model explicitly on the subagent or child-task request.
Do not rely on the project-wide `model` in `.codex/config.toml` when the agent's
tier is `haiku` or `opus`; that setting is only the fallback for unclassified
work.

| Agent frontmatter | Codex model |
|-------------------|-------------|
| `model: haiku` | `gpt-6-luna` |
| `model: sonnet` or omitted | `gpt-6.1-terra` |
| `model: opus` | `gpt-6.1-sol` |

Example: `producer`, `product-director`, and `technical-director` declare
`model: opus`, so a Codex-spawned instance of any of them must receive
`gpt-6.1-sol` explicitly.

Before spawning, also read any original skill referenced by the agent or
orchestration workflow. The Codex model mapping changes execution selection;
it does not replace the original skill or agent instructions.
