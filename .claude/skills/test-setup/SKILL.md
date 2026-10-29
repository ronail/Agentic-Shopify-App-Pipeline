---
name: test-setup
description: "Scaffold the test framework and CI/CD pipeline for the project's stack. Creates the tests/ directory structure, test runner configuration, and GitHub Actions workflow. Run once during Technical Setup phase before the first sprint begins."
argument-hint: "[force]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write
model: sonnet
---

# Test Setup

This skill scaffolds the automated testing infrastructure for the project.
It detects the configured stack, generates the appropriate test runner
configuration, creates the standard directory layout, and wires up CI/CD
so tests run on every push.

Run this once during the Technical Setup phase, before any implementation
begins. A test framework installed at sprint start costs 30 minutes.
A test framework installed at sprint four costs 3 sprints.

**Output:** `tests/` directory structure + `.github/workflows/tests.yml`

---

## Phase 1: Detect Stack and Existing State

1. **Read stack config**:
   - Read `.claude/docs/technical-preferences.md` and extract the `Stack:` and
     `Language:` values.
   - If the stack is not configured (`[TO BE CONFIGURED]`), stop:
     "Stack not configured. Run `/start` first, then re-run `/test-setup`."

2. **Check for existing test infrastructure**:
   - Glob `tests/` — does the directory exist?
   - Glob `tests/unit/` and `tests/integration/` — do subdirectories exist?
   - Glob `.github/workflows/` — does a CI workflow file exist?
   - Glob `vitest.config.*`, `jest.config.*`, `playwright.config.*` — which runner,
     if any, is already configured?

3. **Report findings**:
   - "Stack: [stack]. Test directory: [found / not found]. CI workflow: [found / not found]."
   - If everything already exists AND `force` argument was not passed:
     "Test infrastructure appears to be in place. Re-run with `/test-setup force`
     to regenerate. Proceeding will not overwrite existing test files."

If the `force` argument is passed, skip the "already exists" early-exit and
proceed — but still do not overwrite files that already exist at a given path.
Only create files that are missing.

---

## Phase 2: Present Plan

Based on the stack detected and the existing state, present a plan:

```
## Test Setup Plan — [Stack]

I will create the following (skipping any that already exist):

tests/
  unit/           — Isolated unit tests for rules, validation, and calculations
  integration/    — Cross-module tests and API/webhook round-trips
  smoke/          — Critical path test list (15-minute manual gate)
  evidence/       — Screenshot and manual test sign-off records
  helpers/        — Assertion utilities, factories, request mocks
  fixtures/       — Recorded payloads and seed data
  setup.ts        — Global setup (mock server lifecycle, fake timers)
  README.md       — Test framework documentation

vitest.config.ts  — Runner configuration and coverage thresholds
.github/workflows/tests.yml  — CI: run tests on every push to main

Estimated time: ~5 minutes to create all files.
```

Ask: "May I create these files? I will not overwrite any test files that
already exist at these paths."

Do not proceed without approval.

---

## Phase 3: Create Directory Structure

After approval, create the following files.

### `tests/README.md`

```markdown
# Test Infrastructure

**Stack**: [stack and version]
**Test Framework**: [runner and version]
**CI**: `.github/workflows/tests.yml`
**Setup date**: [date]

## Directory Layout

```
tests/
  unit/           # Isolated unit tests (rules, validation, calculations)
  integration/    # Cross-module tests and API/webhook round-trips
  smoke/          # Critical path test list for /smoke-check gate
  evidence/       # Screenshot logs and manual test sign-off records
  helpers/        # Assertions, factories, request mocks
  fixtures/       # Recorded payloads and seed data
```

## Running Tests

```bash
npm test              # full suite
npm run test:unit     # unit only
npm run test:watch    # watch mode during development
```

## Test Naming

- **Files**: `[module]_[feature].test.[ext]`
- **Cases**: `[scenario] — [expected result]`
- **Example**: `billing_charge.test.ts` → `it('rejects a charge above the plan limit')`

## Story Type → Test Evidence

| Story Type | Required Evidence | Location |
|---|---|---|
| Logic | Automated unit test — must pass | `tests/unit/[module]/` |
| Integration | Integration test OR recorded manual verification | `tests/integration/[module]/` |
| UX/Visual | Screenshot + design sign-off | `production/qa/evidence/` |
| UI | Manual walkthrough OR interaction test | `production/qa/evidence/` |
| Config/Data | Smoke check pass | `production/qa/smoke-*.md` |

## CI

Tests run automatically on every push to `main` and on every pull request.
A failed test suite blocks merging.
```

### `vitest.config.ts`

```ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    setupFiles: ['./tests/setup.ts'],
    include: ['tests/**/*.test.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov'],
      exclude: ['tests/**', '**/*.config.*'],
    },
  },
});
```

### `tests/setup.ts`

```ts
// Global test setup — runs before every test file.
// Keep this file small: per-test fixtures belong in tests/helpers/.

import { afterAll, afterEach, beforeAll } from 'vitest';

// Example: register the mock HTTP server created by /test-helpers, if present.
// import { server } from './helpers/request-mocks';
// beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
// afterEach(() => server.resetHandlers());
// afterAll(() => server.close());

afterEach(() => {
  // Reset environment between tests so order cannot change results.
  // e.g. vi.useRealTimers();
});
```

### Placeholder directories

Create `tests/unit/.gitkeep`, `tests/integration/.gitkeep`,
`tests/evidence/.gitkeep`, and `tests/fixtures/.gitkeep` so the layout is
committed before the first test exists.

If the project uses a different language or runner (Python/pytest, Go, Ruby),
generate the equivalent configuration for that runner and keep the same
directory semantics.

---

## Phase 4: Create CI/CD Workflow

If `.github/workflows/tests.yml` does not exist, create it. When a workflow file
already exists, read it and add the missing test job instead of overwriting.

```yaml
name: Automated Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    name: Test
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Node
        uses: actions/setup-node@v4
        with:
          node-version: '[version from .claude/docs/technical-preferences.md]'
          cache: npm

      - name: Install dependencies
        run: npm ci

      - name: Type check
        run: npm run typecheck --if-present

      - name: Run tests
        run: npx vitest run --reporter=default --reporter=junit --outputFile=test-results/junit.xml

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: test-results/
```

Add a `typecheck` script to `package.json` if one does not exist. Keep the test
job independent of any deploy job so a deploy failure never masks a test failure.

---

## Phase 5: Create Smoke Test Seed

Create `tests/smoke/critical-paths.md`:

```markdown
# Smoke Test: Critical Paths

**Purpose**: Run these 10-15 checks in under 15 minutes before any QA hand-off.
**Run via**: `/smoke-check` (which reads this file)
**Update**: Add new entries when new core modules are implemented.

## Core Stability (always run)

1. The app installs and completes the OAuth handshake without error
2. The embedded admin surface loads without a blank screen or console error
3. Navigation between the app's primary screens does not 500

## Core Flow (update per sprint)

<!-- Add the primary flow for each sprint here as it is implemented -->
<!-- Example: "Merchant can create a bundle and it appears in the storefront" -->
4. [Primary flow — update when the first core module is implemented]

## Data Integrity

5. A webhook is received, verified, and processed without duplicate records
6. Re-running a job is idempotent — no duplicate rows, no double charges

## Performance

7. The primary list view renders within the budget in
   `docs/architecture/apps/[app]/control-manifest.md`
8. No unbounded query — no request exceeds the documented cost ceiling
```

---

## Phase 6: Post-Setup Summary

After writing all files, report:

```
Test infrastructure created for [stack].

Files created:
- tests/README.md
- tests/setup.ts
- tests/unit/ (directory)
- tests/integration/ (directory)
- tests/smoke/critical-paths.md
- tests/evidence/ (directory)
- vitest.config.ts
- .github/workflows/tests.yml

Next steps:
1. Install the runner: npm install -D vitest @vitest/coverage-v8
2. Write your first test: create tests/unit/[first-module]/[module]_feature.test.ts
3. Run `/test-helpers scaffold` to generate assertions and factories
4. Run `/qa-plan sprint` before your first sprint to classify stories and set
   test evidence requirements
5. `/smoke-check` before every QA hand-off

Gate note: /gate-check Technical Setup → Pre-Production now requires:
- tests/ directory with unit/ and integration/ subdirectories
- .github/workflows/tests.yml
- At least one example test file
Run /test-setup and write one example test before advancing.

Verdict: **COMPLETE** — test framework scaffolded and CI/CD wired up.
```

---

## Collaborative Protocol

- **Never overwrite existing test files** — only create files that are missing.
  If a runner config exists, leave it as-is.
- **Always ask before creating files** — Phase 2 requires explicit approval.
- **Stack detection is non-negotiable** — if the stack is not configured, stop and
  redirect to `/start`. Do not guess.
- **`force` flag skips the "already exists" early-exit but never overwrites.**
  It means "create any missing files even if the directory already exists."
- For CI changes, keep the test job independent of deploy jobs and grant the
  workflow only the permissions it needs (`contents: read` unless a step pushes).
