# ADR: Godot `.uid` File Version Control Policy

**Status**: Accepted
**Date**: 2026-09-17
**Decision Maker**: technical-director

## Decision

All `*.uid` files are committed to git alongside their source `.gd`/`.tres`/`.tscn` assets, the same as `.import` files.

## Context

Godot 4.4+ generates a `.uid` file next to every script/resource to give it a stable, path-independent UID reference (`uid://...`), used by other resources and scenes to reference it without breaking on file moves/renames.

## Rationale

UIDs are the authoritative identity behind `uid://` references embedded in committed scenes and resources. If `.uid` files were gitignored, each clone would regenerate fresh UIDs that would not match the `uid://` strings already committed in `.tscn`/`.tres` files, producing broken references, spurious re-resolution diffs, and non-reproducible CI builds — unacceptable given the project's headless gdUnit4 CI gate (see [coding-standards.md](../../.claude/docs/coding-standards.md)). Committing `.uid` files is the official Godot 4.4+ guidance, and they are small, deterministic, and rarely change.

## Consequences

- Contributors must stage `.uid` files together with new assets; a deleted-but-not-staged `.uid` file is a reviewable error.
- Merge conflicts in `.uid` files are resolved by keeping the pre-existing UID, never the newly generated one.
- `.gitignore` must never list `*.uid`.

## Alternatives Considered

- **Gitignore `.uid` files**: rejected — causes UID drift between clones and breaks `uid://` references committed in scenes/resources, and produces non-reproducible CI builds.
