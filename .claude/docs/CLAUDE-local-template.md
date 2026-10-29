# CLAUDE.local.md Template

Copy this file to the project root as `CLAUDE.local.md` for personal overrides.
This file is gitignored and will not be committed.

```markdown
# Personal Preferences

## Model Preferences
- Prefer Opus for architecture review and gate decisions
- Use Haiku for quick lookups and simple edits

## Workflow Preferences
- Always run `npm run test` after code changes
- Compact context proactively at 60% usage
- Use /clear between unrelated apps
- Check `docs/shopify-api-reference/2026-10/` before writing any GraphQL

## Local Environment
- Node: <your LTS version, e.g. v22.x>
- Package manager: npm
- Dev store: <your-store>.myshopify.com
- Start the app with: shopify app dev --store <your-store>
- Shell: Git Bash on Windows
- IDE: VS Code with the Claude Code extension

## Communication Style
- Keep responses concise
- Show file paths in all code references
- Explain architectural decisions briefly

## Personal Shortcuts
- When I say "review", run /code-review on the last changed files in apps/<app>/
- When I say "status", run /kanban-status plus git status
- When I say "ship it", run /gate-check gate-4-release — do not deploy
```

Personal preferences never override the pipeline's gates. If a preference here
contradicts `.claude/docs/technical-preferences.md` or an Accepted ADR, the ADR
wins — fix the ADR or drop the preference.

## Setup

1. Copy this template to your project root: `cp .claude/docs/CLAUDE-local-template.md CLAUDE.local.md`
2. Edit to match your preferences (fill in your dev store handle and Node version)
3. Verify `CLAUDE.local.md` is in `.gitignore` (Claude Code reads it from the project root)
