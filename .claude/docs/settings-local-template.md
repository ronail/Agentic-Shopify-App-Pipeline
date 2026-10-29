# settings.local.json Template

Create `.claude/settings.local.json` for personal overrides that should NOT
be committed to version control. Add it to `.gitignore`.

## Example settings.local.json

```json
{
  "permissions": {
    "allow": [
      "Bash(git *)",
      "Bash(npm run *)",
      "Bash(npx vitest *)",
      "Bash(shopify app dev *)",
      "Bash(shopify app info *)",
      "Bash(shopify theme *)",
      "Read",
      "Glob",
      "Grep"
    ],
    "deny": [
      "Bash(rm -rf *)",
      "Bash(git push --force *)",
      "Bash(shopify app deploy *)",
      "Bash(shopify app release *)"
    ]
  }
}
```

`shopify app dev` is safe to auto-approve — it starts a local server and tunnel
against your dev store. `shopify app deploy` is deliberately denied: it pushes
scopes, webhooks, and extensions to a real store, so it stays a human decision.

## Permission Modes

Recommended for this pipeline:

### During Development (Default)
Use **normal mode** — Claude asks before running most commands. This is safest
for production code and anything touching a store.

### During Prototyping
Use **auto-accept mode** with limited scope — faster iteration on throwaway
prototypes. Only use this when working inside `apps/<app>/prototype/`, which
production code cannot import.

### During Code Review
Use **read-only** permissions — Claude can read and search but not modify files.
Pairs with `/code-review` and `/architecture-review`, both of which are
read-only audits.

## Customizing Hooks Locally

You can add personal hooks in `settings.local.json` that extend (not override)
the project hooks. For example, a notification when a session ends:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'echo Session ended at $(date)'",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

Useful personal hooks for this repo:

| Hook | Command idea |
| --- | --- |
| `PostToolUse` on `Write` | `jq . <file>` after editing any `*.json` in `apps/<app>/` |
| `Stop` | Print the current app's stage from `docs/registry/apps.json` |
| `PreToolUse` on `Bash` | Refuse `shopify app deploy` unless `--force` was typed by you |

Personal hooks must not override the project's gate and quality hooks — extend
them. If a personal hook makes a project hook unreachable, delete the personal
one.

## Not in this file

These belong in the committed `.claude/settings.json`, because every agent needs
them:

- The pipeline's own hooks (commit validation, gate checks, agent audit)
- Project-wide permissions
- Any setting that changes what a gate decides
