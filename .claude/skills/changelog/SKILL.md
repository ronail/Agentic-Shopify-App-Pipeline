---
name: changelog
description: "Use when recording what shipped in an app release. Builds a Keep-a-Changelog entry from commits scoped to apps/<app>/, completed stories, and sprint records, picks the SemVer bump, and prepends it to apps/<app>/CHANGELOG.md."
argument-hint: "[app] [version | --unreleased]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write
model: haiku
---

# Changelog

Maintains the per-app changelog at `apps/<app>/CHANGELOG.md` in Keep a Changelog
format with Semantic Versioning. This is the **engineering record**: it names
requirement IDs, story files, and commit ranges, and it is the source
`/patch-notes` translates for merchants.

One changelog per app. Never write a repository-wide changelog — each app ships on its
own cadence.

---

## Phase 1: Parse Arguments and Check Git

- `app` — slug from `docs/registry/apps.json`; default to the app named in `request.md`
- `version` — target version (for example `1.4.0`); `--unreleased` (default) writes into
  the `## [Unreleased]` section instead of cutting a version

Verify git is available: `git rev-parse --is-inside-work-tree`. If that fails, say so
and stop — a changelog without a commit range is guesswork.

---

## Phase 2: Gather Changes

Read only this app's history:

```bash
git tag --list --sort=-v:refname | head -10
git log --oneline <last-tag>..HEAD -- apps/<app>/
git log --format="%h %s" -50 -- apps/<app>/
```

Then load context:

- `apps/<app>/CHANGELOG.md` — existing entries, the newest released version, and the
  `## [Unreleased]` block
- Sprint records in `production/apps/<app>/sprints/` — planned scope and the reasons
  behind changes
- Completed stories in `production/epics/**/story-*.md` whose header names this app —
  pull story IDs, requirement IDs, and titles
- `apps/<app>/status.md` — anything deliberately deferred

Commits touching another app's directory are out of scope; do not fold them in.

---

## Phase 3: Categorize

Map every change into exactly one Keep a Changelog section:

| Section | What belongs here |
|---------|-------------------|
| **Added** | New merchant-facing capability, new surface, new scope-backed feature |
| **Changed** | Behaviour change to an existing feature, UI change, dependency or API version bump |
| **Deprecated** | Still working, scheduled for removal, with the removal version |
| **Removed** | Feature or surface deleted in this release |
| **Fixed** | Bug fix — name the broken behaviour |
| **Security** | Vulnerability fix, token handling change, permission tightening |

Internal-only work (refactors, test changes, CI) does not get a public line. Record it
under that release's `### Internal` block with the commit range, so the record is
complete without polluting the merchant-visible sections.

Commits with a story or requirement reference (`story-NNN`, `REQ-<AREA>-NNN`, `#123`)
are classified confidently. Commits without any reference go under `### Internal` with
their hash and are counted as `Commits without a reference: [N]`.

---

## Phase 4: Choose the Version Bump

SemVer, decided from the entries, not from the author's mood:

- **MAJOR** — a merchant must change behaviour or re-authorise: scope change requiring
  reinstall, removed feature, billing model change, extension relocation
- **MINOR** — new capability, backward compatible
- **PATCH** — fixes and internals only

Record the reasoning in the release header:
`Version: 1.4.0 (MINOR — new bundle scheduling; no merchant action required)`.

---

## Phase 5: Generate the Entry

````markdown
## [1.4.0] - 2026-10-29
Version bump: MINOR — new capability, no merchant action required

### Added
- Scheduled bundle start and end dates (`REQ-BUNDLE-004`) — story-021-schedule.md

### Changed
- Admin API pinned to [version]; install and webhook flows re-verified (story-024-api-bump.md)

### Deprecated
- Legacy CSV import is deprecated and will be removed in 2.0.0

### Removed
- Nothing removed in this release

### Fixed
- Duplicate order tags when a webhook was delivered twice (`REQ-WHK-002`) — story-019-idempotency.md

### Security
- Access tokens are now encrypted at rest; no plaintext tokens remain in logs

### Internal
- Range: `a1b2c3d..e4f5g6h` (18 commits, 3 without a reference)
- Refactor: split the discount service from the route layer — no behaviour change
````

For `--unreleased`, produce the same section bodies under `## [Unreleased]` with no date
and no version bump line; the bump is decided when the version is cut.

---

## Phase 6: Review Before Writing

Check the entry against these rules and fix it first:

- Every user-visible change appears exactly once
- Fixes name the broken behaviour, not the internal cause
- Requirement and story IDs are present for anything traceable
- Removals and deprecations state the version they take effect in
- No entry describes work that did not ship in this range
- If the history is noisy (reverts, fixups, merges), tell the story once instead of
  listing every commit

---

## Phase 7: Write

Ask:

> "May I update `apps/<app>/CHANGELOG.md`?
> [A] Yes, prepend this entry (recommended)
> [B] Show the full file after the change first
> [C] No — I'll copy it manually"

Rules for the write:

- **Released entries are immutable.** Never edit a section above the new one; a
  correction ships as a new version.
- Prepend the new entry immediately below the file header; newest first.
- `## [Unreleased]` always stays at the top, empty after a version is cut.
- Keep the file header intact:

```markdown
# Changelog — [app]

All notable changes to this app. Format follows Keep a Changelog; versions follow
Semantic Versioning. Merchant-facing notes are generated from these entries by
`/patch-notes`.
```

Verdict after a write: **CHANGELOG WRITTEN** — `apps/<app>/CHANGELOG.md` updated.
If the user declines: **COMPLETE** — entry generated, not saved.

---

## Phase 8: Next Steps

- `/patch-notes [app] [version]` — merchant-facing notes, translated from this entry
- `/release-checklist [app] --version [version]` — submission readiness for the version
- `/release [app] [version]` — publish, once both of the above pass

---

## Guidelines

- The changelog is read by engineers and by `/patch-notes`; write for both
- One app, one file. Never merge two apps' histories to save a write
- Commit hashes stay in `### Internal`; they never appear in a public section
- If a change cannot be described without internal jargon, it probably is not
  merchant-visible — move it to `### Internal`
- Version numbers are decisions, not labels: state the bump rationale in the header
