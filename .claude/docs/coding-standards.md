# Coding Standards

- All app code must include doc comments on public APIs (exported functions,
  types, hooks)
- Every subsystem must have a corresponding architecture decision record in
  `docs/architecture/apps/<app>/`
- Merchant-visible values must be data-driven (external config), never
  hardcoded in components or handlers
- All public functions must be unit-testable (dependency injection over
  module-level singletons)
- Commits must reference the relevant requirement ID or task ID
- **Commit messages**: Use Conventional Commits format — `feat:`, `fix:`,
  `chore:`, `docs:`, `test:`, `refactor:`. Reference the story or task ID in the
  body (e.g., `Story: EPIC-001-S02`).
- **Verification-driven development**: Write tests first when adding a
  subsystem. For admin UI changes, verify with Polaris screenshots or an
  interaction test. Compare expected output to actual output before marking work
  complete. Every implementation should have a way to prove it works.
- **TypeScript**: `strict` on. No `any` in exported signatures — use `unknown`
  plus a parser at the boundary. Types are shared from `apps/<app>/types/`, not
  duplicated per module.
- **React**: function components and hooks only. Server data enters through
  loaders; components do not call the Admin API directly. Every interactive
  control must be keyboard reachable and labelled for screen readers.
- **Polaris**: use the component library before writing custom markup. Custom
  CSS is allowed only when no Polaris primitive covers the case, and it must use
  Polaris design tokens rather than raw hex values.
- **Shopify API version**: the pinned version lives in `apps/<app>/shopify.app.toml`
  and is read from config. Never hardcode an API version string in a query file,
  route, or test.
- **GraphQL**: one operation per file, named after the file, with variables typed
  by an explicit interface. Request only the fields the feature consumes, and
  check the cost estimate before adding nested connections.
- **Webhooks**: verify HMAC before parsing side effects; handlers must be
  idempotent and acknowledge quickly, pushing slow work to the queue.
- **Secrets**: never commit `.env` files. `.env.example` documents every key with
  a placeholder value.

# Requirements Document Standards

- All requirement docs use Markdown, live under `design/` or `apps/<app>/`, and
  are tracked in that app's `requirements.yaml` registry
- Each requirement set must include these 8 sections:
  1. **Overview** -- one-paragraph summary of the merchant problem
  2. **Merchant Job** -- what the merchant is trying to get done, in their words
  3. **Detailed Rules** -- unambiguous behaviour, including edge cases
  4. **Calculations** -- all pricing, discount, or metric math with variables
  5. **Edge Cases** -- empty stores, huge catalogs, multi-currency, partial failures
  6. **Dependencies** -- other systems, API scopes, webhook topics
  7. **Configuration** -- merchant-tunable values and their defaults
  8. **Acceptance Criteria** -- testable success conditions
- Every value with a default must state its rationale or the source it came from

# Testing Standards

## Test Evidence by Story Type

All stories must have appropriate test evidence before they can be marked Done:

| Story Type | Required Evidence | Location | Gate Level |
|---|---|---|---|
| **Logic** (calculations, plan gating, state machines) | Automated unit test — must pass | beside source in `apps/<app>/` | BLOCKING |
| **Integration** (API, webhooks, database) | Integration test against recorded fixtures | beside source in `apps/<app>/` | BLOCKING |
| **Admin UI** (Polaris routes, forms, empty states) | Interaction test OR documented walkthrough with screenshots | `production/apps/<app>/qa/evidence/` | ADVISORY |
| **Extension** (theme block, checkout) | Dev-store walkthrough on a real theme/checkout | `production/apps/<app>/qa/evidence/` | ADVISORY |
| **Config/Data** (API version bump, scopes) | Smoke check pass | `production/apps/<app>/qa/smoke-<date>.md` | ADVISORY |

## Automated Test Rules

- **Naming**: `<module>.test.ts` beside `<module>.ts`; test names read as
  `it('returns the tiered discount for a 3-item cart')`
- **Determinism**: Tests must produce the same result every run — no live
  network, no wall-clock assertions, no unseeded randomness
- **Isolation**: Each test sets up and tears down its own state; tests must not
  depend on execution order
- **No hardcoded data**: Fixtures come from factory functions or JSON files, not
  inline magic values (exception: boundary tests where the exact number is the
  point)
- **Independence**: Unit tests do not call the Admin API, a database, or the
  filesystem — inject clients and repositories
- **Recorded responses**: Integration tests replay captured Admin GraphQL
  responses for the pinned API version; refresh them deliberately when the
  version changes

## What NOT to Automate

- Polaris visual fidelity and layout polish (review with screenshots)
- Merchant-perceived responsiveness on a real store
- App Store listing review outcomes
- Full install and onboarding flows (covered by dev-store walkthroughs)

## CI/CD Rules

- Automated test suite runs on every push to main and every PR
- No merge if tests fail — tests are a blocking gate in CI
- Never disable or skip failing tests to make CI pass — fix the underlying issue
- Standard commands:
  - `npm run lint` — ESLint with the TypeScript ruleset
  - `npm run typecheck` — `tsc --noEmit`
  - `npm run test` — Vitest, CI mode with coverage
  - `npm run build` — production bundle for the app server
