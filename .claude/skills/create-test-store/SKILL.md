---
name: create-test-store
description: "Provisions a development and test store for a Shopify app: development store, test products and orders, the app install with scopes, and the credentials record the deploy path reads. Use before the first deploy, or when an app needs a clean store to test against."
argument-hint: "[app-slug]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
model: haiku
---

# Create Test Store — A Store to Build Against

## Purpose

An app that has never been installed on a real store has never been tested. This
skill stands up a development store with the fixtures the app needs, installs the
app on it with the right scopes, and records where the credentials live — without
ever writing a secret into the repository.

**Never handle secrets in chat.** Credentials are recorded as a location
reference; the values stay in the environment or the credential store.

## When to use

- An app has an approved prototype and needs a real install to build against.
- `apps/<app>/` has no test-store record yet.
- A test store was corrupted by a bad migration and must be replaced.

## Inputs

| Path | Required | What you take from it |
|------|----------|-----------------------|
| `apps/<app>/README.md` | yes | The app and its surface |
| `apps/<app>/approvals.json` | yes | Confirms the app is scoped |
| `docs/shopify-api-reference/` | yes | Scope names and API version to pin |
| `apps/<app>/shopify.app.toml` | optional | Existing app config to reuse |
| `production/apps/<app>/session-state/` | yes | Where the store record goes |

## Steps

1. **Confirm the app is scoped.** `gate-3-scope` approved in
   `apps/<app>/approvals.json`. If not, stop and say which gate is missing.
2. **Create the development store** in the partner dashboard, named for the app
   and the environment: `<app>-dev`. Use a development store, not a trial store —
   trial stores expire and cannot install unpublished apps.
3. **Seed the fixtures.** Create the data the app's flow needs: at least 10
   products across two collections, one product with variants, one with no
   inventory, and two orders in different states. Fixtures must include an empty
   collection and a zero-result search — the states that break in production.
4. **Install the app** on the store with exactly the scopes in the approved
   scope list. Do not grant extra scopes "for convenience"; the store should
   reproduce what a merchant grants.
5. **Record the credentials by reference**, not by value, in
   `production/apps/<app>/session-state/test-store.md`:

   - store domain
   - environment variable or credential-store path holding the admin token
   - the pinned API version
   - install date and the app version installed
   - what the fixtures contain
6. **Verify the install** by making one read call through the app's own client
   and confirming the scopes actually granted match the list requested. A scope
   granted by the dashboard and a scope granted by the install flow are not the
   same thing.
7. **Report** the store domain, the surface that is now testable, and the next
   step: `/deploy-to-test-store <app>`.

## Outputs

- `production/apps/<app>/session-state/test-store.md` — the store record
- Fixture data on the store itself (products, collections, orders)
- No changes under `apps/<app>/` unless `shopify.app.toml` needs the client id

## Ownership

Owned by **test-store-manager**. `devops-engineer` supplies the environment
variable names and the secret storage convention; `qa-lead` specifies which
fixtures the test plan needs; `auth-specialist` confirms the install flow.

## Rules

- **No secrets in files, ever.** Record the variable name, never the token.
- **Fixtures are reproducible.** Write down how they were created so a
  replacement store can be rebuilt from the record.
- **One store per app per environment.** Reuse before creating; orphan stores
  cost money and confuse the deploy target.
- **Do not install production builds on test stores** without labelling the
  version in the record.
