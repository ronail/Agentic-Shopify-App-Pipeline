# ADR-0002: Godot Test Framework (gdUnit4) Version Control Policy

## Status

Proposed

## Date

2026-09-21

## Last Verified

2026-09-21

## Decision Makers

technical-director (primary), godot-specialist (research & recommendation)

## Summary

Determines whether the `addons/gdUnit4` testing-framework directory is committed to git or gitignored. Decision: **commit `addons/gdUnit4` directly to the repository; do not gitignore it.** This matches the project's existing "clone-and-run" VCS philosophy established in ADR-0001, where build/test-critical resources (`.uid`, `.import` files) are committed so a fresh clone can run immediately.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core |
| **Knowledge Risk** | LOW — addon VCS policy is engine-agnostic and unchanged since Godot 4.0 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/architecture/ADR-godot-uid-vcs-policy.md`, `.claude/docs/coding-standards.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None — this is a VCS policy, not an engine API decision |

> **Note**: Knowledge Risk is LOW. This decision does not depend on post-cutoff engine APIs.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Godot `.uid` File Version Control Policy) — both follow the same "clone-and-run" principle |
| **Enables** | Godot test framework setup (`/test-setup` skill), headless gdUnit4 CI gate |
| **Blocks** | None |

## Context

### Problem Statement

The project needs a VCS policy for third-party Godot addons that are required for
development workflows but are not part of the shipped game code. Specifically, the
gdUnit4 unit-testing framework will be installed into `addons/gdUnit4/`. Two
approaches exist: (A) commit the addon directly to the repository, or (B) manage it
as a git submodule and gitignore the `addons/gdUnit4/` path. A decision is needed
to establish the project-wide convention.

### Current State

The repository has no Godot project or `addons/` directory yet. This ADR establishes
the policy for when a Godot project is added. The existing `.gitignore` and
`docs/architecture/ADR-godot-uid-vcs-policy.md` already commit `.uid` and `.import`
files — the stated philosophy is "commit everything needed to build/test so a fresh
clone works immediately."

### Constraints

- **CI**: The coding standard declares the CI command
  `godot --headless --script tests/gdunit4_runner.gd`, which requires
  `addons/gdUnit4/` to be present on disk at that path. This is a plain script
  invocation, not the separate `gdunit4-action` GitHub Action (which auto-installs
  the plugin).
- **Engine version**: Godot 4.6 (pinned, January 2026).
- **Contributor experience**: The project's ADRs and `.gitignore` prioritize
  clone-and-run simplicity (per Toxe, Godot core developer).
- **Decision authority**: ADR-0001 names `technical-director` as the decision
  maker for VCS policy; committing a third-party framework is a dependency
  decision requiring sign-off.

### Requirements

- A fresh clone must be able to run `godot --headless --script tests/gdunit4_runner.gd` without additional setup steps.
- All contributors (including those on Windows) must get a working test environment from a standard `git clone` with no submodule initialization.
- The VCS policy must be consistent with ADR-0001's "commit everything needed to build" philosophy.
- Version updates to the testing framework must follow the existing commit-based workflow (conventional commits, reviewed PRs).

## Decision

Commit `addons/gdUnit4/` directly to the repository. Do not add `addons/gdUnit4/` to
`.gitignore`.

### Rationale

1. **Consistency with ADR-0001**: The project already commits `.uid` and `.import`
   files — build-critical resources that make a clone immediately functional.
   gdUnit4 is equally build-critical for the CI test gate.

2. **CI command requires in-tree presence**: The declared CI command
   `godot --headless --script tests/gdunit4_runner.gd` invokes Godot's built-in
   script runner against resources under `res://`. It does **not** use the
   separate `MikeSchulze/gdunit4-action` GitHub Action (which auto-installs the
   plugin). Therefore the addon must exist at `addons/gdUnit4/` after a plain
   `git clone`.

3. **Godot core developer endorsement**: Toxe (Godot engine contributor) states:
   "You want other developers to be able to clone your repository and immediately
   run your project without any further hassle. Therefore add everything that is
   important to your repository." Submodule-based approaches are explicitly called
   "just complicate things."

4. **Official Godot VCS guidance**: The Godot documentation's "Files to exclude
   from VCS" section lists only `.godot/`, `*.translation`, and
   `export_presets.cfg`. `addons/` is not in the exclusion list.

### Trade-offs Accepted

- gdUnit4's source code (~1,500+ files) becomes part of the repository's git
  history, increasing clone size and history depth.
- Version updates to gdUnit4 are managed via conventional-commit PRs (not via
  independent submodule version bumps).
- This is consistent with how the project already handles `.uid` and `.import`
  files.

## Alternatives Considered

### Alternative 1: Git submodule with symlink hook (maintainer's recommended guide)

- **Description**: Add gdUnit4 as a git submodule at `.gdUnit4/`, create a
  post-checkout hook that symlinks `.gdUnit4/addons/gdUnit4` to
  `addons/gdUnit4`, and gitignore both paths. CI uses the separate
  `gdunit4-action` which auto-installs the plugin.
- **Pros**: Clean repo history; independent version management; maintainer's
  preferred approach.
- **Cons**: Breaks clone-and-run (requires `git submodule update --init`); symlink
  hooks are fragile on Windows and don't work in CI; the project's CI command
  (`--script tests/gdunit4_runner.gd`) does not use the `gdunit4-action`, so the
  auto-install benefit is not realized without CI migration; significant complexity
  for a framework repo with no multi-project version-pinning need.
- **Rejection Reason**: Directly conflicts with the project's clone-and-run
  philosophy, the declared CI command, and cross-platform contributor experience.

### Alternative 2: Git submodule directly at addons/gdUnit4 (no symlink)

- **Description**: `git submodule add https://github.com/MikeSchulze/gdUnit4
  addons/gdUnit4`, gitignore the path. Simpler than Alternative 1 (no symlinks).
- **Pros**: Independent version management; no symlink fragility.
- **Cons**: Still requires `git submodule update --init` on every clone, breaking
  clone-and-run; adds contributor workflow complexity for marginal benefit on a
  framework repo.
- **Rejection Reason**: Unnecessary complexity given the project's philosophy and
  single-repo needs.

### Alternative 3: Gitignore and install via AssetLib on each clone

- **Description**: Add `addons/gdUnit4/` to `.gitignore`; contributors manually
  install via the Godot Asset Library.
- **Cons**: Non-deterministic (depends on which AssetLib version is selected);
  manual step on every clone; breaks CI (headless Godot has no AssetLib UI);
  violates reproducibility.
- **Rejection Reason**: Fails the core reproducibility and CI requirements.

## Consequences

### Positive

- Fresh clones work immediately: `godot --headless --script tests/gdunit4_runner.gd` succeeds with no setup.
- Consistent with ADR-0001's VCS philosophy — no special knowledge needed by contributors.
- No submodule/symlink fragility on Windows or in CI.
- CI configuration is trivial — no extra plugin-install step.

### Negative

- gdUnit4 source code (~1,500+ files) lives in the project's git history, increasing repo size and history depth.
- Version updates to gdUnit4 require a reviewed PR (same as any code change) rather than an independent submodule bump.

### Neutral

- The policy is identical whether the Godot project is a game project or the framework's own test harness — consistency is maintained.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Repo bloat from committing third-party code | LOW | LOW | gdUnit4 is pure GDScript + small data files; impact is limited to history size, not runtime |
| Version-lock coupling | MEDIUM | LOW | Updates managed via conventional-commit PRs; version pinned in `addons/gdUnit4/plugin.cfg` |
| Contributors accidentally modify committed addon files | LOW | LOW | Code review catches unintended changes to `addons/gdUnit4/` |

## Performance Implications

N/A — this is a VCS policy decision with no runtime performance impact.

## Migration Plan

This ADR applies to new Godot projects added under this framework. No existing
`addons/gdUnit4/` directory exists to migrate.

If a project currently uses a submodule-based gdUnit4 setup and wants to switch
to the direct-commit approach:

1. Deinit the submodule: `git submodule deinit -f addons/gdUnit4`
2. Remove the submodule entry from `.gitmodules` and `.git/config`
3. Remove `.git/modules/addons/gdUnit4`
4. Commit the submodule removal
5. Re-add gdUnit4 as a regular addon directory (via AssetLib or manual copy)
6. Run the full test suite to verify the CI command works

**Rollback plan**: If the direct-commit approach proves problematic, revert to
the submodule approach by gitignoring `addons/gdUnit4/` and adding it as a
submodule.

## Validation Criteria

- [ ] `.gitignore` does not contain `addons/gdUnit4/` or any entry that would exclude the gdUnit4 addon
- [ ] A fresh `git clone` of a Godot project using this framework allows `godot --headless --script tests/gdunit4_runner.gd` to succeed without any additional setup
- [ ] The `/test-setup` skill does not generate a `.gitignore` entry that excludes `addons/gdUnit4/`
- [ ] This ADR is referenced from `coding-standards.md` and the `/test-setup` skill spec

## GDD Requirements Addressed

Foundational — no GDD requirement. Enables: Godot test framework scaffolding
(`/test-setup` skill) and the headless gdUnit4 CI gate described in
`docs/architecture/ADR-godot-uid-vcs-policy.md`.

## Related

- [ADR-0001: Godot `.uid` File Version Control Policy](ADR-godot-uid-vcs-policy.md) — establishes the same clone-and-run VCS philosophy
- [coding-standards.md](../../.claude/docs/coding-standards.md) — references the headless gdUnit4 CI command
- [test-setup skill spec](../AHGS Skill Testing Framework/skills/utility/test-setup.md) — scaffolds the GdUnit4 runner config
- [gdUnit4 Discussion #651: Using GdUnit4 as a Git submodule](https://github.com/godot-gdunit-labs/gdUnit4/discussions/651) — maintainer's recommended submodule approach (not adopted)
- [Godot VCS best practices](https://docs.godotengine.org/en/stable/tutorials/best_practices/version_control_systems.html) — official docs on files to exclude from VCS