---
name: kanban-status
description: "Renders the pipeline board across every app from docs/registry/apps.json and production/apps/<app>/: stage, gate state, open sprints, and what is blocked. Read-only. Use when asking where an app stands, what is in flight, or what to work on next."
argument-hint: "[app-slug, or blank for all apps]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
model: haiku
---

# Kanban Status — Where Every App Stands

## Purpose

One view of the pipeline: every app, its stage, its gate state, and the single
thing blocking it. Sourced from files on disk, never from memory of the last
conversation.

**Read-only.** This skill writes nothing and changes no status.

## When to use

- "Where are we?" / "What's in flight?" / "What should I work on next?"
- Before planning a sprint — the board is the input.
- After a gate run, to confirm the record actually landed.

## Inputs

| Path | Required | What you take from it |
|------|----------|-----------------------|
| `docs/registry/apps.json` | yes | Slug, name, stage, last approved gate |
| `apps/<app>/approvals.json` | yes | Per-gate status, date, approver |
| `apps/<app>/status.md` | optional | `Stage:` and `Last Updated:` |
| `production/apps/<app>/sprints/` | optional | Newest sprint file and its status lines |
| `production/apps/<app>/session-state/` | optional | Last active task |
| `production/research/<app>/` | optional | Whether research exists |

## Steps

1. **Read `docs/registry/apps.json`.** If it does not parse, report the parse
   error and stop — every number below would be wrong.
2. **For each app**, collect:
   - `stage` from the registry; `last_approved_gate` from the registry
   - the five gate statuses from `apps/<app>/approvals.json`
   - whether `apps/<app>/` exists, and whether `apps/<app>/prototype/` has more
     than a `.gitkeep`
   - the newest file in `production/apps/<app>/sprints/` and any
     `Status:` / `IN PROGRESS` / `BLOCKED` markers in it
   - the last line of `production/apps/<app>/session-state/` if present
3. **Check registry against disk.** An app in the registry with no `apps/<app>/`
   directory is a `missing-scaffold` flag. An `apps/<app>/` directory not in the
   registry is an `unregistered` flag. Report both — they are the two ways the
   board lies.
4. **Derive the blocking step** for each app: the first gate that is not
   `approved`, mapped to its skill — `gate-1-research` → `/research`,
   `gate-2-prototype` → `/build-prototype`, `gate-3-scope` →
   `/mmmvp-proposals`, `gate-4-release` → `/release`, `gate-5-update` →
   `/update-research`.
5. **Render the board** using the format below. Group by stage, newest activity
   last. Do not print an app twice.
6. **Give one recommendation** — the single highest-value next action, and say
   why it outranks the others.

## Output

```markdown
## Pipeline Board — <date>

| App | Stage | Gates (1-5) | Blocked on | Next action |
|-----|-------|-------------|------------|-------------|
| discount-bundles | research | ✓ - - - - | gate-2-prototype | /build-prototype |
| order-tags | research | ✓ - - - - | (none) | /research |

### Flags
- (missing-scaffold / unregistered / stale gate entries, or "none")

### Recommendation
<one action, one sentence of why>
```

Gate column notation: `✓` approved, `~` in review, `-` not started, `!` blocked.

## Ownership

Owned by **producer**. Read-only for everyone else; any agent may run it.

## Rules

- **Disk over recollection.** If the file says `research` and the conversation
  said `release`, the file wins.
- **Flag, do not fix.** A broken registry entry is reported with the path; the
  fix belongs to whoever owns that file.
- **No invented dates.** A gate with `date: null` shows as not started.
- **One recommendation.** A list of six priorities is not a board.

Template: `.claude/docs/templates/kanban-card.md` — the card schema every board entry is read from.
