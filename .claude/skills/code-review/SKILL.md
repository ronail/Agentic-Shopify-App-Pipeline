---
name: code-review
description: "Use when reviewing a file, route, or module in one app before its story closes. Checks the app's control manifest and ADRs, coding standards, SOLID, and Shopify platform concerns — session tokens, webhook HMAC, API cost, rate limits, scopes — with specialist reviews routed by layer."
argument-hint: "[path-to-file-or-directory] [story-path]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Task, AskUserQuestion, request_user_input, clarify
model: sonnet
agent: lead-engineer
---

# Code Review

Reviews an implemented change against the rules the app actually agreed to: its
control manifest, its ADRs, the project's coding standards, and the Shopify platform
constraints that break merchant stores when ignored.

**Scope: one app.** Resolve the app slug from `docs/registry/apps.json`, from the
target path (`apps/<app>/…`), or from the story argument. Never combine two apps'
rules in one review.

---

## Phase 1: Load Target Files

Read the target file(s) in full — not diffs alone. Also read `AGENTS.md` (and
`CLAUDE.md` if present) for project coding standards.

If the target is a directory, Glob every source file under it and read each one.

Report: `Reviewing [N] files — app: [app], layer(s): [...]`.

---

## Phase 2: Load the App's Rules

Read `docs/architecture/apps/<app>/control-manifest.md` — the flat rules sheet for
this app: Required, Forbidden, and Guardrail entries per layer, plus the global
naming, API version, and library rules.

- Manifest present → it is the primary checklist for Phase 4. Note its
  `Manifest Version`; if the story's Context block embeds an older version, flag it:
  "Story was written against an older control manifest — rules may have changed since."
- Manifest missing → say so and continue against
  `.claude/docs/technical-preferences.md` only:
  "No control manifest for [app] — run `/create-control-manifest [app]`; reviewing
  against technical preferences only."

Then read `.claude/docs/technical-preferences.md`, section `## Shopify Specialists`,
including its `### File Type Routing` table. Phase 7 uses that table to pick reviewers.

---

## Phase 3: ADR Compliance Check

**Argument:** `/code-review [file(s)]` may include a story file path as the last
argument (e.g. `/code-review apps/bundles/app/routes/app.bundles.tsx
production/apps/bundles/stories/story-001.md`). If provided, read it and extract the
governing ADR reference.

Search for ADR references in this order:

1. The story file (if provided)
2. Header comments at the top of the implementation files
3. Commit messages touching these files (`git log --oneline -- [file]`)

Look for patterns like `ADR-NNNN` or `docs/architecture/apps/<app>/ADR-`.

If no references are found, note: "No ADR references found — ADR compliance check
skipped. For full compliance review, provide the story path:
`/code-review [files] [story-path]`."

For each referenced ADR: read
`docs/architecture/apps/<app>/ADR-NNNN-<slug>.md`, extract the **Decision** and
**Consequences** sections, then classify any deviation:

- **ARCHITECTURAL VIOLATION** (BLOCKING): uses a pattern the ADR explicitly rejected
- **ADR DRIFT** (WARNING): diverges from the chosen approach without using a
  forbidden pattern
- **MINOR DEVIATION** (INFO): small difference that does not change the architecture

---

## Phase 4: Control Manifest and Standards Compliance

Identify the layer(s) the change belongs to — **admin UI**, **app server**,
**webhooks**, **theme extensions**, **checkout extensions**, **data** — and check
every Required and Forbidden entry the manifest assigns to those layers, plus:

- [ ] Exported functions, types, and route handlers carry doc comments
- [ ] Cyclomatic complexity under 10 per function
- [ ] No function exceeds 40 lines (excluding data declarations)
- [ ] Dependencies are injected (no module-level singletons holding shop or session state)
- [ ] Tunables come from config or the database, not hardcoded literals
- [ ] Each layer exposes interfaces (callers do not reach into another layer's internals)
- [ ] Naming follows the manifest: `PascalCase` types, `camelCase` functions,
      `kebab-case` files, one GraphQL operation per file
- [ ] API version comes from `shopify.app.toml` — no second hardcoded version string

Report the manifest line behind each failure, so the fix is unambiguous.

---

## Phase 5: Architecture and SOLID

**Architecture:**

- [ ] Correct dependency direction (extensions and admin UI → app server → Shopify
      Admin API; never reverse, never UI → Admin API directly)
- [ ] No circular dependencies between modules
- [ ] Proper layer separation (admin UI holds no access token, no merchant data cache)
- [ ] Webhooks or job queues carry cross-boundary communication, not synchronous
      cross-layer calls
- [ ] Consistent with established patterns in the app

**SOLID:**

- [ ] Single Responsibility: each module has one reason to change
- [ ] Open/Closed: extendable without editing call sites
- [ ] Liskov Substitution: implementations are substitutable for their interfaces
- [ ] Interface Segregation: no fat interfaces
- [ ] Dependency Inversion: depends on abstractions, not concretions

---

## Phase 6: Platform-Specific Concerns

- [ ] **Session tokens** — every embedded admin request carries an App Bridge session
      token verified server-side; the `shop` value comes from that token, never from a
      query parameter or form field
- [ ] **OAuth** — state/nonce verified on callback; access token stored server-side
      only, never in a client payload, URL, or log line
- [ ] **Webhook HMAC** — raw request body verified against the HMAC header with a
      timing-safe comparison *before* parsing; unverified payloads are rejected, not
      queued
- [ ] **Webhook idempotency** — duplicate deliveries deduped by event ID or
      topic + resource ID; handlers are safe to run twice; response under the handler
      budget with slow work offloaded to a job
- [ ] **API cost** — no unbounded GraphQL query; list fields paginate (`first`/`after`)
      with a bounded page size; requested cost stays within the app's budget
- [ ] **Rate limits** — throttled and 429 responses handled with backoff honouring the
      retry hint; no tight retry loop; bulk operations used for large exports
- [ ] **Scopes** — code uses only the scopes declared in `shopify.app.toml`; no scope
      is requested that the feature does not need; protected customer data handling
      matches the scopes in use
- [ ] **Billing** — plan gates are enforced server-side on every gated action, not
      only in the UI
- [ ] **Shop scoping** — every read and write is scoped to the authenticated shop; no
      path allows cross-shop access
- [ ] **Secrets** — read from environment or config, never logged, never bundled into
      client code
- [ ] **Resource cleanup** — connections, timers, and job handlers release what they
      acquire; no unbounded growth across requests
- [ ] **Error handling** — null/empty states handled; failures surface a message the
      merchant can act on, and never leak internal detail

---

## Phase 7: Specialist Reviews (Parallel)

Spawn all applicable specialists simultaneously via Task — do not wait for one before
starting the next.

### Routing

Use the `### File Type Routing` table in `.claude/docs/technical-preferences.md` to
map each changed file to a specialist. Any file the table does not cover goes to
`lead-engineer` (the primary review gate).

Typical mapping:

- Admin UI routes and Polaris components → `polaris-specialist`
- App server routes, loaders/actions, Admin GraphQL client → `lead-engineer`
- Webhook handlers and subscription config → `webhooks-specialist`
- Theme app extension blocks and Liquid output → `liquid-specialist`
- Checkout extension targets → `checkout-specialist`
- GraphQL operations and schema/version concerns → `graphql-specialist`
- Auth, session, and token modules → `auth-specialist`
- Billing and plan gating → `billing-specialist`
- App Bridge / embedded context setup → `app-bridge-specialist`
- Migrations, schema, infra config → `devops-engineer`
- Cross-layer change or ADR-governed pattern → also spawn `app-architect`

Give each specialist the changed files, the control manifest rules for its layer, and
the relevant ADR.

### QA Testability Review

For Logic and Integration stories, also spawn `qa-tester` via Task in parallel. Pass:

- The implementation files being reviewed
- The story's `## QA Test Cases` section (the pre-written specs from qa-lead)
- The story's `## Acceptance Criteria`

Ask the qa-tester to evaluate:

- [ ] Are all test hooks and interfaces exposed (not hidden behind private/internal access)?
- [ ] Do the QA test cases map to testable code paths?
- [ ] Are any acceptance criteria untestable as implemented (hardcoded values, no seam for injection)?
- [ ] Does the implementation introduce edge cases the existing QA test cases miss?
- [ ] Are there observable side effects that should have a test but don't?

For UX/Visual and UI stories: qa-tester reviews whether the manual verification steps
in `## QA Test Cases` are achievable with the implementation as written — is the state
the checker must reach actually reachable on a dev store?

Collect all specialist findings before producing output.

---

## Phase 8: Output Review

```
## Code Review: [File/Module Name]

### Control Manifest Compliance: [N/A — no manifest / N/N rules passing]
[Failures, each with the manifest line that governs it]

### Specialist Findings: [CLEAN / ISSUES FOUND]
[Routed findings by specialist, or "No specialist routed." if the file types were uncovered]

### Testability: [N/A — UX/Visual or Config/Data story / TESTABLE / GAPS / BLOCKING]
[qa-tester findings: test hooks, coverage gaps, untestable paths, new edge cases]
[If BLOCKING: implementation must expose [X] before ## QA Test Cases can run]

### ADR Compliance: [NO ADRS FOUND / COMPLIANT / DRIFT / VIOLATION]
[Each ADR checked, result, and any deviation with severity]

### Standards Compliance: [X/N passing]
[Failures with file and line references]

### Architecture: [CLEAN / MINOR ISSUES / VIOLATIONS FOUND]
[Specific architectural concerns]

### SOLID: [COMPLIANT / ISSUES FOUND]
[Specific violations]

### Platform-Specific Concerns
[Session token, HMAC, idempotency, API cost, rate limit, scope, billing, shop-scoping,
secret handling issues — or "None found."]

### Positive Observations
[What is done well — always include this section]

### Required Changes
[Must-fix items before approval — ARCHITECTURAL VIOLATIONs always appear here]

### Suggestions
[Nice-to-have improvements]

### Verdict: [APPROVED / APPROVED WITH SUGGESTIONS / CHANGES REQUIRED]
```

This skill is read-only — no files are written.

---

## Phase 9: Next Steps

Use `AskUserQuestion`, `request_user_input` or `clarify`:

- Prompt: "Code review complete — verdict: [APPROVED / CHANGES REQUIRED]. How would
  you like to proceed?"
- Options (adjust to the verdict):
  - If APPROVED:
    - `[A]` Run `/story-done` to mark the story complete
    - `[B]` Stop here
  - If CHANGES REQUIRED:
    - `[A]` Fix the issues and re-run `/code-review`
    - `[B]` Run `/story-done` anyway with noted exceptions
    - `[C]` Stop here

If an ARCHITECTURAL VIOLATION is found:

- Violation contradicts an **existing ADR** → fix the implementation to comply with
  `docs/architecture/apps/<app>/ADR-NNNN-<slug>.md`. If the design legitimately
  changed, run `/architecture-decision` to *revise* that ADR — never create a
  competing one.
- **No ADR exists** for the violated pattern → run `/architecture-decision` to record
  the correct approach before fixing the code.
- The manifest is stale relative to the fix → run `/create-control-manifest [app]
  update` after the ADR is accepted, so later reviews check the new rule.
