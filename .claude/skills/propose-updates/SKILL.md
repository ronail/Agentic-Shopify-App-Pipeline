---
name: propose-updates
description: "Turns observed pipeline friction into written proposals for changes to agents, skills, rules or hooks, with evidence and a risk note, parked for ratification. Use after a task that fought the framework, a repeated workaround, or a retro. Writes proposals only, never applies them."
argument-hint: "[area, e.g. 'skills' or 'gate-3-scope' or blank to scan recent work]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
model: haiku
---

# Propose Updates — Write It Down Before You Change It

## Purpose

Every pipeline accumulates friction: a skill that asks for a file nothing
creates, an agent that owns two overlapping things, a rule that fires on the
wrong file. The temptation is to patch it mid-task. This skill captures the fix
as a proposal instead, so the change can be reviewed against its evidence and
applied deliberately.

**Proposals only.** This skill never edits an agent, skill, rule, or hook.

## When to use

- A task had to work around the framework to finish.
- The same fix has been made twice by hand.
- A retro or a failed gate points at a process gap, not a code gap.
- Before any change to `.claude/agents/`, `.claude/skills/`, rules, or hooks.

## Inputs

| Path | Required | What you take from it |
|------|----------|-----------------------|
| Optional area argument | no | Narrows the scan to one skill, agent, or gate |
| `production/session-state/` | yes | What was actually worked on |
| `.claude/skills/*/SKILL.md` | yes | Current skill bodies and their stated paths |
| `.claude/agents/*.md` | yes | Ownership and tool grants |
| `docs/registry/apps.json` | optional | Whether a path referenced by a skill exists |

## Steps

1. **Name the friction as an observation, not a solution.** One sentence: "The
   `/release` flow asks for a file that no skill creates." Solutions come later;
   a proposal that starts with a solution hides its own evidence.
2. **Attach evidence.** The file path and line, the command output, or the
   session where it happened. A proposal with no evidence is an opinion, and
   opinions do not get ratified.
3. **Classify the fix**: `missing-file` (a skill assumes a path nothing
   produces), `ownership-overlap` (two agents claim one decision), `stale-path`
   (a referenced path no longer exists), `tool-grant` (an agent needs a tool it
   lacks), `wording` (instructions ambiguous enough to be misread),
   `dead-skill` (a skill nothing invokes).
4. **Propose the minimal change.** One target file, one edit shape. If the fix
   needs three files, the friction is probably misdiagnosed — say which part you
   are unsure about.
5. **State the blast radius.** Which agents and skills read the target, and what
   would break if the change is wrong. Anything touching a gate or an approval
   record is `high` risk and needs a named reviewer.
6. **State what you are not changing**, so the ratifier knows the boundary.
7. **Write the proposal** with a stable id, `P-<YYYYMMDD>-<n>`, status `open`.
8. **Ask before writing** if the proposals folder does not exist.

## Outputs

`production/proposals/<id>.md`, one file per proposal:

```markdown
# P-20261029-01 — <short title>
Status: open
Area: skills | agents | rules | hooks
Type: missing-file | ownership-overlap | stale-path | tool-grant | wording | dead-skill
Risk: low | medium | high

## Observation
<one sentence>

## Evidence
- <path:line> — <what it shows>

## Proposed change
- Target: <file>
- Change: <before → after, or the exact new text>

## Blast radius
<who reads this, what breaks if wrong>

## Out of scope
<what this proposal does not touch>
```

## Ownership

Owned by **producer**. Any agent or the user may raise friction; `producer`
writes it up and keeps the proposal list. `lead-engineer` ratifies and runs
`/apply-updates`; `technical-director` reviews anything marked `high` risk.

## Rules

- **Evidence or discard.** No cited path or output, no proposal.
- **One change per proposal.** Bundled changes cannot be ratified or reverted
  independently.
- **Never apply in the same run.** Writing the fix here defeats the review.
- **Naming the friction is success.** A proposal that gets rejected with a reason
  is still a better outcome than a silent workaround.
