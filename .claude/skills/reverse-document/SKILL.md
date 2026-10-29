---
name: reverse-document
description: "Document existing app code into docs/architecture/apps/<app>/ — system overview, data flow, API surface, webhook map, and ADR candidates — grounded in file:line citations. Use for inherited apps, undocumented features, and before architecture review of an app whose code outran its docs."
argument-hint: "[app: <slug>] [path: <subdir>] [--adr-candidates]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, AskUserQuestion, request_user_input, clarify
model: sonnet
agent: app-architect
---

# Reverse Document

Turns working code into architecture documentation. The output must describe
what the code **does**, not what someone intended — every claim cites a file and
line, and anything not evidenced is labelled as unknown.

**Output:** `docs/architecture/apps/<app>/`

- `system-overview.md` — what the app is, its surfaces, and its boundaries
- `data-flow.md` — request → handler → data → response paths
- `api-surface.md` — Admin API operations, scopes used, API version, cost notes
- `webhook-map.md` — topic → route → side effects → idempotency
- `adr-candidates.md` (only with `--adr-candidates`) — decisions worth recording
  as ADRs, with the code evidence

Do not overwrite an existing document silently. If one exists, produce a diff-style
update and ask.

---

## 1. Inventory Before Reading

Map the app's shape first:

```bash
# file inventory by extension, with sizes
find apps/<app> -type f ! -path "*/node_modules/*" ! -path "*/prototype/*" \
  | sed 's/.*\.//' | sort | uniq -c | sort -rn

# entry points and routes
grep -rn "export default\|export async function loader\|export async function action" \
  apps/<app> --include=*.ts --include=*.tsx

# GraphQL documents
find apps/<app> -name "*.graphql" -o -name "*.gql"

# webhook routes
grep -rln "webhook\|webhooks" apps/<app> --include=*.ts
```

Record: route count, module count, GraphQL operation count, migration count,
test count. Those numbers anchor the document's scope statement.

---

## 2. Read in Dependency Order

1. `apps/<app>/shopify.app.toml` — embedded or not, scopes, webhook topics,
   API version, redirect URLs. This is the app's contract with Shopify.
2. Entry/config: `package.json`, route manifest, server bootstrap.
3. Auth and session modules — how a request becomes an authorised shop context.
4. Primary routes and their data loaders/actions.
5. GraphQL operation files — the actual API surface.
6. Webhook routes.
7. Repository/query layer and migrations — the data model.
8. Background jobs/workers.
9. The app's tests — they encode intended behaviour and edge cases the code
   hides.

While reading, keep a running list of every file that matters. If a file is
unreadable or a behaviour depends on a service you cannot see, write
`UNKNOWN — <reason>` rather than inferring.

---

## 3. Extract Facts, Not Impressions

For each document section, collect these facts with citations:

**System overview**
- Surfaces: embedded admin routes, theme app extension, checkout extension,
  server endpoints, jobs.
- External dependencies, each with the file that uses it.
- Data stores: tables and their owning modules.
- Scopes requested vs scopes actually exercised (mismatch is a finding).

**Data flow**
- For each primary flow, the chain: UI component → route loader/action →
  operation → API → persistence → response → rendered state.
- Where errors are caught and what the merchant sees.
- Where caching sits, and its invalidation trigger.
- Any synchronous external call on a request path (latency and failure risk).

**API surface**
- Operation name, file, requested cost, pagination strategy, throttling
  behaviour.
- Pinned API version, and where it is read from (must be one place per app).
- Deprecated fields in use — check against
  `docs/shopify-api-reference/<version>/` deprecated list.

**Webhook map**
- Topic → route file → work performed → what is queued → idempotency key.
- Which topics are subscribed in toml but have no handler, and which handlers
  exist for unsubscribed topics.

**Data model**
- Tables, key columns, indexes that exist because a query needs them, and
  foreign keys that enforce the shop boundary.
- Rows that grow without bound (jobs, events, logs) and what prunes them.

---

## 4. Write the Documents

Style rules:
- Present tense, describing current behaviour.
- Every non-obvious claim cites `path/to/file.ts:120`.
- Distinguish **observed** (read in code), **inferred** (concluded from several
  files — say so), and **unknown**.
- No recommendations in the descriptive docs. Findings go in a final section or
  in `adr-candidates.md`.
- Diagrams in text (Mermaid) only when the flow is genuinely branching; a
  three-step chain is prose.

Template skeleton for `system-overview.md`:

```markdown
# <app> — System Overview

> Reverse-documented from commit <sha> on <date>. Sources cited inline.

## What the app does
<merchant-facing description, then the mechanism in one paragraph>

## Surfaces
| Surface | Entry point | Notes |

## Boundaries
- Reads: <tables/APIs>
- Writes: <tables/APIs>
- Never touches: <explicit non-goals found in code>

## Request lifecycle
<numbered chain with citations>

## Data stores
| Store | Owner module | Growth bound |

## Known gaps
| Gap | Evidence | Impact |
```

---

## 5. Findings and ADR Candidates

Any of these becomes a documented finding, not a quiet fix:

- a scope requested but never used, or used but not requested,
- an Admin API call from the browser,
- a webhook handler that parses before verifying,
- a query without shop scoping,
- hardcoded API version outside `shopify.app.toml`,
- an unbounded table with no prune,
- a synchronous third-party call before webhook ack.

`--adr-candidates` adds a ranked list:

```markdown
# ADR Candidates — <app>

| # | Decision | Evidence | Why it deserves an ADR | Constraints it creates |
|---|----------|----------|------------------------|------------------------|
```

Only list decisions that constrain *other* work. "We use Postgres" from a shared
preference doc is not an app ADR; "billing state is derived from
`app_subscriptions/update` rather than polled" is.

---

## 6. Verify the Document Against the Code

Before finishing, spot-check five citations at random against the files. A
document with a wrong line reference is worse than no document — it teaches the
team to trust stale facts.

Then ask: *"May I write these documents to
`docs/architecture/apps/<app>/`?"* List every file path in the approval request.

---

## Boundary

- Documenting only. Do not refactor code while documenting; file the finding.
- Do not document the prototype directory — it is throwaway.
- If the code contradicts an existing ADR, that is a finding for
  `/architecture-review`, not something to quietly reconcile in prose.
- Hand-off: findings → the owning specialist; ADR candidates →
  `/architecture-decision`; requirement gaps →
  `docs/architecture/apps/<app>/requirements.yaml` via `app-architect`.
