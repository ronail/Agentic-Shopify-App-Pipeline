---
name: deploy-to-test-store
description: "Deploys a build of a Shopify app to its test store: pins the version, applies pending migrations, releases the app extension and config, updates the install, and verifies the deployed version on the store. Use when a build needs to be exercised on a real store."
argument-hint: "<app-slug> [version-tag]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
model: sonnet
---

# Deploy to Test Store — Ship It Somewhere Real

## Purpose

Local code and a real store disagree more often than anyone expects: extension
registration, config shape, granted scopes, webhook delivery, cache behaviour.
This skill puts a specific, named build on the test store and proves the store is
running that build — not a previous one.

## When to use

- A build is ready to be exercised by `qa-tester` on a store.
- QA found a defect and a fix needs re-deploying to the same store.
- An extension or app config changed and the install must be refreshed.

## Inputs

| Path | Required | What you take from it |
|------|----------|-----------------------|
| `<app-slug>` + optional version tag | yes | What to deploy; default is the current commit |
| `production/apps/<app>/session-state/test-store.md` | yes | Store domain, credential reference, pinned API version |
| `apps/<app>/` | yes | The built app, extension and config |
| `apps/<app>/shopify.app.toml` | yes | Extension and scope declarations to push |
| `production/apps/<app>/sprints/` | optional | Which stories this deploy is meant to unblock |

## Steps

1. **Remove ambiguity about the build.** Record the exact commit and, if given,
   the version tag. "Latest" is not a deployable identity — write the commit
   hash down in the deploy record.
2. **Confirm the test store record exists** at
   `production/apps/<app>/session-state/test-store.md`. If it does not, stop and
   run `/create-test-store <app>` first.
3. **Check the config diff** — scopes, extension registrations, webhook topics,
   redirect URLs. Any added scope means the merchant must re-consent, so the
   deploy must be followed by a reinstall step. Call this out before deploying.
4. **Apply pending migrations** to the app's own data store against the test
   environment, after taking a snapshot. A migration applied to the wrong
   environment is the most expensive mistake in this skill.
5. **Deploy** the app and release the extension and config. If the deploy tool
   reports a warning, treat it as a failure until proven otherwise — report the
   warning text verbatim.
6. **Reinstall or re-consent** if scopes changed; otherwise confirm the existing
   install still resolves. Confirm the app loads in the admin on the test store.
7. **Verify the running version** — hit one endpoint or screen that changed in
   this build and confirm the new behaviour is present. "Deploy succeeded" from a
   tool is not proof; observed behaviour is.
8. **Record the deploy** in `production/apps/<app>/session-state/deploy-log.md`,
   appended, one entry per deploy: date, commit, version tag, store, what
   changed, scopes added, verification result, rollback point.
9. **Report** the deploy result, the verification evidence, and the rollback
   command.

## Outputs

- The deployed build on the test store
- `production/apps/<app>/session-state/deploy-log.md` — one appended entry
- Optionally a `shopify.app.toml` change, only if the deploy required it

## Ownership

Owned jointly by **test-store-manager** (store state, install and consent) and
**devops-engineer** (build, migrations, deploy mechanics, rollback). `qa-lead`
consumes the deploy to start the test run; `release-manager` requires a green
test-store deploy before `gate-4-release`.

## Rules

- **Named build or nothing.** Every deploy record carries a commit hash.
- **Snapshot before migrating.** No migration runs on a store without a restore
  point.
- **Warnings are failures** until someone writes down why they are not.
- **Rollback path stated in the same message as the deploy result.** A deploy
  report without a rollback command is incomplete.
- **Test store only.** This skill never targets a production or merchant store;
  that is `/release`.
