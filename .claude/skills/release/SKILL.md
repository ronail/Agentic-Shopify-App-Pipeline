---
name: release
description: "Cuts a versioned release of a Shopify app for App Store submission: verifies the readiness gate, freezes the version, writes release notes and the rollback plan, tags the build, and records the gate-4-release approval. Use when an app is ready to submit or a fix must ship as a new version."
argument-hint: "<app-slug> <version>"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
model: sonnet
---

# Release — Cut the Version That Ships

## Purpose

A release is a promise: this build, this version, these notes, this rollback.
This skill assembles that promise, checks it against the readiness gate, and
records the approval — so a merchant-facing defect can always be traced to a
build that someone signed for.

`/release` does not submit to the App Store on its own. It produces the release
and the submission package; filing the submission is a separate, confirmed step.

## When to use

- An app is ready for its first App Store submission.
- A defect fix must ship as a patch version.
- A config or scope change requires a new reviewed version.

## Inputs

| Path | Required | What you take from it |
|------|----------|-----------------------|
| `<app-slug> <version>` | yes | Semantic version; never reuse a published one |
| `production/apps/<app>/app-store-checklist.md` | yes | The readiness verdict |
| `apps/<app>/approvals.json` | yes | `gate-2-prototype`, `gate-3-scope` states |
| `production/apps/<app>/session-state/deploy-log.md` | yes | Proof the build ran on a real store |
| `production/apps/<app>/sprints/` | optional | What shipped, for the notes |
| `apps/<app>/README.md` | yes | The promise the notes must match |

## Steps

1. **Gate check, before anything else.** All of these must hold:
   `app-store-checklist.md` verdict is `ready` with zero fails; `gate-2-prototype`
   and `gate-3-scope` are `approved`; the deploy log has a green test-store
   deploy at this commit. Any gap → stop, name the gap, do not continue.
2. **Fix the version.** Semantic: `MAJOR.MINOR.PATCH`. A scope addition or a
   breaking behaviour change is `MAJOR` or `MINOR`, a fix is `PATCH`. Confirm the
   version is not already tagged; reject a reused tag.
3. **Assemble the diff.** What changed since the last release, from the commit
   range and the sprint records — merchant-visible changes first, internal
   changes second.
4. **Write the release notes** in merchant language: what they can now do, what
   was fixed, what changed in behaviour they should know about. No internal
   identifiers, no table names, no ticket numbers as the headline.
5. **Write the rollback plan**: the previous version, how to re-deploy it, what
   app-side data the new version wrote that the old one must tolerate, and who
   decides to roll back.
6. **Tag the build** and confirm the tag points at the exact verified commit.
   A tag on a different commit voids the readiness check.
7. **Write the release record** and ask for the `gate-4-release` approval.
   Only the owner updates `apps/<app>/approvals.json`, and only after an explicit
   yes.
8. **Produce the submission package**: listing copy, screenshots, pricing, the
   support URL, and the version. Confirm the price in the package matches the
   price in the app's billing code.
9. **Report**: version, commit, gate state, the submission package location, and
   the one risk you would watch in the first week after approval.

## Outputs

`production/apps/<app>/releases/<version>.md`:

- Version, commit, date, owner
- Readiness evidence (checklist verdict, gate states, deploy entry)
- Release notes (merchant-facing)
- Rollback plan
- Submission package contents and locations

Plus: a release tag on the verified commit, and `gate-4-release` in
`apps/<app>/approvals.json` once approved.

## Ownership

Owned by **release-manager**. `app-store-reviewer` supplies the readiness
verdict, `qa-lead` confirms the test run passed, `devops-engineer` owns the tag
and rollback mechanics, `product-director` owns the gate approval.

## Rules

- **No gate, no release.** Skipping step 1 is the whole failure mode this skill
  exists to prevent.
- **Never reuse a version.** Republishing a version leaves merchants unable to
  tell builds apart.
- **Rollback before ship.** Written, with a named decision owner.
- **Notes in merchant language.** "Fixed an issue where bundles were not applied
  on checkout" beats "refactored the discount resolver".

Template: `.claude/docs/templates/pricing-plan.md` — the billing plan record the release packages.
