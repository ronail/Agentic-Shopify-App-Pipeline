---
paths:
  - "apps/**/*.json"
---

# App Data & Config File Rules

- Config JSON (`shopify.app.toml` companions, `approvals.json`) must parse cleanly — a broken file blocks the CLI and the build
- The pinned Admin API version lives in exactly one place per app (`shopify.app.toml`); JSON and code read it, never restate it
- Declare scopes, webhook topics, and extension registrations in the app config, not scattered across handlers
- Keys are camelCase; files are kebab-case and match the module that reads them
- Every config block is validated by a `zod` schema at load time with a clear failure message naming the missing or malformed key
- Merchant-tunable values carry a documented default and a rationale comment or companion doc
- Breaking a config schema bumps a `schemaVersion` field and ships a migration for existing installs
- No orphan keys: remove a setting when its last reader is removed
