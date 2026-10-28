---
name: start
description: Bootstrap a new session. Detect project stage and recommend next actions for Shopify app development.
---

# /start – Session Bootstrap

You are starting a new session on a Shopify app project.

## Steps

1. **Detect current stage**
   - No idea yet
   - Idea only
   - Scaffolded but empty
   - Features in progress
   - Ready for App Store review
   - Live app

2. **Check for key files**
   - `shopify.app.toml`
   - `package.json`
   - Prisma schema or database setup
   - Existing agents / production notes

3. **Recommend next action** based on stage:

| Stage | Recommended Command |
|-------|---------------------|
| No idea | `/research` or `/idea-validate` |
| Idea ready | `/scaffold` |
| Scaffolded | `/create-epics` |
| Building | `/dev-story` or `/code-review` |
| Feature complete | `/security-audit` + `/app-store-checklist` |
| Ready to ship | `/release` |

4. Summarize current status in 3–5 bullets.
5. Ask the user what they want to focus on today.
