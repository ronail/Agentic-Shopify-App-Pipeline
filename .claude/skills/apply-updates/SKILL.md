---
name: apply-updates
description: "Applies ratified update proposals to agents, skills, rules or hooks: verifies approval, applies the minimal diff, updates references in the affected files, and records what changed. Use only after a proposal is ratified; never for unratified ideas."
argument-hint: "[proposal-id, e.g. P-20261029-01, or blank to list open proposals]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
model: sonnet
---

# Apply Updates — Land the Ratified Change

## Purpose

A ratified proposal becomes a framework change here, and only here. The change is
applied as the minimal diff the proposal described, references are kept
consistent, and the record says who ratified it — so a later reader can tell why
a skill reads the way it does.

## When to use

- A proposal under `production/proposals/` has `Status: ratified`.
- A retro decision was made and needs to reach the files it names.
- Never for an idea that has not been written down and ratified.

## Inputs

| Path | Required | What you take from it |
|------|----------|-----------------------|
| `[proposal-id]` | yes | Which proposal to apply |
| `production/proposals/<id>.md` | yes | The exact change, target, and risk |
| The target file(s) | yes | Current content; the proposal's "before" must still match |
| `.claude/skills/*/SKILL.md` | conditional | Only when the proposal names a skill |
| `.claude/agents/*.md` | conditional | Only when the proposal names an agent |

## Steps

1. **Confirm ratification.** The proposal file must show `Status: ratified`
   plus a ratifier name and date. No ratification → stop, and say which field is
   missing. A verbal go-ahead quoted in chat is not enough for a `high` risk
   proposal.
2. **Re-read the proposal and the target file.** If the "before" text in the
   proposal no longer matches the file, the proposal is stale — stop and send it
   back for a refresh. Applying a stale diff is how two changes silently
   collide.
3. **Check for overlap.** Glob the area for another `open` or `ratified`
   proposal touching the same target. Two pending changes to one file must be
   applied in a known order, or one is deferred.
4. **Apply the minimal diff.** Only the lines the proposal names. Do not tidy
   adjacent wording, do not reformat, do not take the opportunity to fix
   something else you noticed — write a new proposal for that instead.
5. **Update references.** If the change renames a path, a skill name, an agent,
   or a frontmatter field, Grep the whole of `.claude/` and `docs/` for the old
   value and confirm every reference is either updated or deliberately left.
   Report any reference you left and why.
6. **Validate the target.** For a skill: frontmatter has `name`, `description`,
   `model`, and the description still starts with its trigger. For an agent: the
   frontmatter still has `name`, `description`, `tools`, `model`. Report the
   fields you checked.
7. **Mark the proposal applied** — set `Status: applied`, add the date and the
   files touched. Never rewrite the proposal's observation or evidence.
8. **Report** the diff summary, the references updated, and anything the change
   left inconsistent that needs its own proposal.

## Outputs

- The diff applied to the named target file(s)
- `production/proposals/<id>.md` — status set to `applied` with date and files
- A short change summary in the response

## Ownership

Owned by **lead-engineer**. `producer` supplies the ratified proposal and the
record; `technical-director` must have ratified anything marked `high` risk.
Owners of the target area review the diff before it lands.

## Rules

- **Ratified only.** No proposal, no edit — including "obviously correct" fixes.
- **Minimal diff.** Scope creep inside an update makes the change un-reviewable
  and un-revertable.
- **No silent renames.** Every reference to a renamed thing is found or
  explicitly left with a reason.
- **One proposal per run.** Batch application hides which change broke what.
- **Never touch an approval record** in `apps/<app>/approvals.json` — that is a
  gate, not documentation.
