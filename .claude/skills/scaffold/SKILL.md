---
name: scaffold
description: Bootstrap a new Shopify app project with recommended stack.
---

# /scaffold – Create New Shopify App

Set up a production-ready Shopify app foundation.

## Default Stack
- Shopify CLI + Remix (or React Router)
- Polaris + App Bridge
- Prisma + PostgreSQL
- TypeScript
- Official Shopify auth libraries

## Steps
1. Confirm app name and type (public / custom)
2. Run recommended Shopify CLI commands
3. Set up database and environment variables structure
4. Create basic folder structure:
   - `app/` (routes, components)
   - `prisma/`
   - `webhooks/`
   - `services/`
5. Add essential files:
   - `shopify.app.toml`
   - `.env.example`
   - Basic privacy policy placeholder
6. Install recommended dependencies
7. Verify install and auth flow works locally

## Output
- Commands the user should run
- Files created
- Next recommended skill (`/create-epics`)
