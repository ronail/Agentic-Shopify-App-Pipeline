---
name: update-request
description: "Amends request.md without losing prior intent: bumps the version, writes the change, and appends a dated entry to request-history.md so superseded asks stay readable. Use when scope, success criteria, or the app list changes after the request was written."
argument-hint: "[what changed, e.g. 'add order-tags app' or 'drop multi-currency']"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
model: sonnet
---

# Update Request — Amend Without Amnesia

## Purpose

`request.md` is the single statement of what the pipeline is building. Editing
it in place silently rewrites history: a later reader cannot tell whether a
feature was never wanted or was dropped on purpose. This skill makes one
change, bumps the version, and records why — so intent survives.

## When to use

- Scope, success criteria, non-goals, or the app list in `request.md` changes.
- A gate decision (`gate-3-scope`, `gate-5-update`) changes what an app must do.
- Research killed or deferred an app that the request still lists.
- Someone asks to "just tweak the request" — that is this skill, always.

## Inputs

| Path | Required | What you take from it |
|------|----------|-----------------------|
| `request.md` | yes | Current text, current `Version:` line |
| `request-history.md` | yes | Append target; create with a header only if absent |
| `docs/registry/apps.json` | yes | Whether an app slug in the change exists |
| `apps/<app>/approvals.json` | conditional | If the app already has gate approvals |
| `production/apps/<app>/mmmvp-proposals.md` | optional | The scope decision behind the change |

## Steps

1. **State the change in one sentence**, in past tense and outcome form: "Added
   the `order-tags` app to scope" or "Removed multi-currency from success
   criteria". If you cannot write that sentence, the change is not defined yet —
   ask.
2. **Find the exact target lines** with Grep before editing. Name the section
   (`Goal`, `Success criteria`, `Non-goals`, `Apps in scope`, `Gates`) and quote
   the current text. Never rewrite a whole file to change one bullet.
3. **Check the blast radius.** If the change touches an app that already has a
   non-pending gate in `apps/<app>/approvals.json`, flag it: an approved gate
   was approved against a different request. That needs `product-director`'s
   explicit re-approval, not a quiet edit.
4. **Draft the diff.** Show the before and after for each touched line, plus the
   new `Version:` value. Version format is `v<major>` for a scope change and
   `v<major>.<minor>` for a clarification that changes no scope.
5. **Ask for approval** on the full changeset — both files, one approval.
6. **Apply the edit** to `request.md`: update `Version:`, `Last updated:`
   (today, `YYYY-MM-DD`), and only the lines the change requires.
7. **Append to `request-history.md`**, never replace. One dated entry:

   ```
   ## v<N> — <YYYY-MM-DD>
   Changed: <the one-sentence change>
   Sections: <section names touched>
   Reason: <why, and which gate or decision drove it>
   Superseded: <the old text, quoted>
   Approved by: <user / role>
   ```
8. **Keep the registry in step.** If the change adds, removes, or renames an app,
   update `docs/registry/apps.json` in the same changeset — a slug in the
   request that is missing from the registry is a broken reference. Renaming a
   slug means moving `apps/<slug>/` too; refuse the rename if the app has
   approved gates and escalate instead.

## Outputs

- `request.md` — amended, version bumped, date updated
- `request-history.md` — one appended dated entry, prior entries untouched
- `docs/registry/apps.json` — only when the app list changed

## Ownership

Owned by **product-director**. `producer` is consulted when the change affects
in-flight sprints; `app-architect` when it affects an app's surfaces.

## Rules

- **Append, never delete, in `request-history.md`.** History is evidence.
- **One change per run.** Two unrelated edits in one entry make the history
  unreadable and un-bisectable.
- **Never edit an approval to match a new request.** Approvals are records, not
  settings. Re-approval is a gate run, not a file edit.
- **Non-goals are load-bearing.** If the change adds something previously listed
  as a non-goal, remove the non-goal in the same edit and say so in the history.

Template: `.claude/docs/templates/master-request.md` — the structure `request.md` must hold before a change is proposed.
Template: `.claude/docs/templates/request-history.md` — the append-only entry format every history edit follows.
