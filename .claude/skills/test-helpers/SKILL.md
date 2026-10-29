---
name: test-helpers
description: "Generate test helper libraries for the project's test suite. Reads existing test patterns and produces tests/helpers/ with assertion utilities, factory functions, and request mocks tailored to the project's modules. Reduces boilerplate in new test files."
argument-hint: "[module-name | all | scaffold]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write
model: sonnet
---

# Test Helpers

Writing test cases is faster and more consistent when common setup, teardown,
and assertion patterns are abstracted into helpers. This skill generates a
`tests/helpers/` library tailored to the project's actual stack, language,
and modules — so every developer writes less boilerplate and more assertions.

**Output:** `tests/helpers/` directory with stack-appropriate helper files

**When to run:**
- After `/test-setup` scaffolds the framework (first time)
- When multiple test files repeat the same setup boilerplate
- When starting to write tests for a new module

---

## 1. Parse Arguments

**Modes:**
- `/test-helpers [module-name]` — generate helpers for a specific module
  (e.g., `/test-helpers billing`)
- `/test-helpers all` — generate helpers for all modules with test files
- `/test-helpers scaffold` — generate only the base helper library (no
  module-specific helpers); use this on first run
- No argument — run `scaffold` if no helpers exist, else `all`

---

## 2. Detect Stack and Language

Read `.claude/docs/technical-preferences.md` and extract:
- `Stack:` value
- `Language:` value
- `Framework:` from the Testing section

If the stack is not configured: "Stack not configured. Run `/start` (or author
`.claude/docs/technical-preferences.md`) first."

---

## 3. Load Existing Test Patterns

Scan the test directory for patterns already in use:

```
Glob pattern="tests/**/*.{test,spec}.*" (all test files)
```

For a representative sample (up to 5 files), read the test files and extract:
- Setup patterns (how `beforeEach` / fixtures / factories are written)
- Common assertion patterns (what is being asserted most often)
- Object creation patterns (how domain objects are constructed in tests)
- Mock/stub patterns (how HTTP, storage, and time are replaced)

This ensures generated helpers match the project's existing style, not a
generic template.

Also read:
- `docs/architecture/apps/[app]/requirements.yaml` — to know which modules and
  behaviours exist, and what bounds and edge cases need testing
- `docs/architecture/apps/[app]/control-manifest.md` — required and forbidden
  patterns the helpers must not violate

---

## 4. Generate Base Helpers

Generate one file per concern, not one monolith. Default layout for a
TypeScript project on Vitest:

### `tests/helpers/assertions.ts`

```ts
/**
 * Assertion utilities for [Project Name] tests.
 * Domain-specific helpers layered on top of the runner's expect().
 *
 * Usage:
 *   import { assertInRange, assertRejectsWithCode } from '../helpers/assertions';
 */

/** Assert a value is within the inclusive range [min, max].
 *  Use for any value with a bound stated in a requirement. */
export function assertInRange(
  value: number,
  min: number,
  max: number,
  label = 'value',
): void {
  if (!(value >= min && value <= max)) {
    throw new Error(
      `${label} (${value}) is outside expected range [${min}, ${max}]`,
    );
  }
}

/** Assert a promise rejects with an error carrying the expected code. */
export async function assertRejectsWithCode(
  fn: () => Promise<unknown>,
  code: string,
): Promise<void> {
  try {
    await fn();
  } catch (err) {
    const actual = (err as { code?: string }).code;
    if (actual !== code) {
      throw new Error(`Expected error code "${code}", received "${actual}"`);
    }
    return;
  }
  throw new Error(`Expected rejection with code "${code}", but it resolved`);
}
```

### `tests/helpers/factories.ts`

```ts
/**
 * Factory functions for constructing minimal test objects.
 * Every factory takes a partial override so tests state only what matters.
 *
 * Usage: const charge = makeCharge({ amount: 1200 });
 */

export function makeCharge(overrides: Partial<Charge> = {}): Charge {
  return {
    id: 'gid://shopify/AppSubscription/1',
    amount: 0,
    currency: 'USD',
    status: 'active',
    ...overrides,
  };
}
```

### `tests/helpers/request-mocks.ts`

```ts
/**
 * Recorded-response mocks for outbound HTTP.
 * Tests must never reach the network — register handlers here.
 */

import { http, HttpResponse } from 'msw';
import { setupServer } from 'msw/node';

export const server = setupServer();

/** GraphQL handler returning a single data payload. */
export function graphqlOk(data: unknown) {
  return http.post('https://*.myshopify.com/admin/api/*/graphql.json', () =>
    HttpResponse.json({ data }),
  );
}

/** GraphQL handler returning a top-level error list. */
export function graphqlError(message: string) {
  return http.post('https://*.myshopify.com/admin/api/*/graphql.json', () =>
    HttpResponse.json({ errors: [{ message }] }),
  );
}
```

### `tests/helpers/webhook.ts`

```ts
/** Build a signed webhook request for handler tests. */
export function makeWebhookRequest(
  topic: string,
  payload: unknown,
  secret: string,
): Request {
  const body = JSON.stringify(payload);
  const hmac = createHmac('sha256', secret).update(body, 'utf8').digest('base64');
  return new Request('https://example.test/webhooks', {
    method: 'POST',
    headers: { 'content-type': 'application/json', 'x-shopify-hmac-sha256': hmac, 'x-shopify-topic': topic },
    body,
  });
}
```

Adapt names and idioms to the language in use. The point is the shape:
**assertions**, **factories**, **transport mocks** — three files, no monolith.

---

## 5. Generate Module-Specific Helpers

For `[module-name]` or `all` modes, generate a helper per module.

Read the module's entries in `docs/architecture/apps/[app]/requirements.yaml` to extract:
- Domain types and their required fields
- Bounds, limits, and thresholds stated in acceptance criteria
- Common failure scenarios named in edge cases

Generate `tests/helpers/[module].factory.ts` with factory functions specific to
that module's objects, and a `[module].assertions.ts` only if the module has
bounds that appear in more than one test.

Example pattern for a `billing` module:

```ts
/**
 * Factory and assertion helpers for the billing module.
 * Generated by /test-helpers billing on [date].
 * Based on: docs/architecture/apps/[app]/requirements.yaml (REQ-BILL-*)
 */

export const AMOUNT_MIN = 0;
export const AMOUNT_MAX = 999_999; // requirement: capped at 9999.99 in minor units

/** Minimal subscription for charge-state tests. */
export function makeSubscription(overrides: Partial<Subscription> = {}): Subscription {
  return {
    id: 'sub_1',
    plan: 'basic',
    amount: 0,
    status: 'active',
    ...overrides,
  };
}

/** Assert a computed amount is inside the requirement's stated bounds. */
export function assertAmountInBounds(amount: number): void {
  assertInRange(amount, AMOUNT_MIN, AMOUNT_MAX, 'amount');
}
```

---

## 6. Write Output

Present a summary of what will be created:

```
## Test Helpers to Create

Base helpers (stack: [stack], runner: [runner]):
- tests/helpers/assertions.ts
- tests/helpers/factories.ts
- tests/helpers/request-mocks.ts
[stack-specific extras]

Module helpers ([mode]):
- tests/helpers/[module].factory.ts  ← from requirements.yaml ([REQ-prefix])
```

Ask: "May I write these helper files to `tests/helpers/`?"

**Never overwrite existing files.** If a file already exists, report:
"Skipping `[path]` — already exists. Remove the file manually if you want it
regenerated."

After writing: Verdict: **COMPLETE** — helper files created.

"Helper files created. To use them in a test:
- TypeScript: `import { assertInRange } from '../helpers/assertions';`
- Register the mock server in your setup file: `beforeAll(() => server.listen())`
  and `afterEach(() => server.resetHandlers())`"

---

## Collaborative Protocol

- **Never overwrite existing helpers** — they may contain hand-written
  customisations. Only generate new files that don't exist yet
- **Generated code is a starting point** — the generated factories use plain
  objects for simplicity; adapt to the real class or schema once the code exists
- **Helpers should reflect the requirements** — bounds and constants in helpers
  must trace to acceptance criteria in `requirements.yaml`, not invented values
- **Ask before writing** — always confirm before creating files in `tests/`

## Next Steps

- Run `/test-setup` if the test framework has not been scaffolded yet.
- Use `/dev-story` to implement stories — helpers reduce boilerplate in new test files.
- Run `/skill-test` to validate other skills that may need helper coverage.
