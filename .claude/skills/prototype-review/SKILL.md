---
name: prototype-review
description: "Reviews a built prototype against the original request before any production build: flow fidelity, merchant language, empty and error states, and whether the demo actually proves the value. Produces a pass/fail set of findings and the gate-2-prototype recommendation."
argument-hint: "[app-slug]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
model: sonnet
---

# Prototype Review — Judge Before Build

## Purpose

The prototype exists to be rejected cheaply. This skill decides whether the flow
it shows is the flow the request asked for, whether a merchant would understand
it, and whether it earns the cost of a real build. Findings are specific and
file-anchored, not impressions.

Output feeds `gate-2-prototype`: `product-director` approves or sends it back on
the strength of these findings.

## When to use

- `/build-prototype` finished and the prototype has not been reviewed.
- A prototype was revised after a failed review — re-review the changed screens
  only, not the whole flow.
- Before any sprint is planned for the app.

## Inputs

| Path | Required | What you take from it |
|------|----------|-----------------------|
| `apps/<app>/prototype/` | yes | Every screen plus its `README.md` flow script |
| `request.md` | yes | What was actually asked for |
| `production/research/<app>/recommendation.md` | yes | The problem and the differentiation hook |
| `production/apps/<app>/mmmvp-proposals.md` | optional | The approved slice boundary |
| `apps/<app>/approvals.json` | yes | Where the gate record is written |

## Steps

1. **Open the prototype and walk the flow** exactly as the `README.md` script
   words it. Note every point where you had to guess what to click next — that is
   a finding, not a nitpick.
2. **Check fidelity to the request.** For each request line that names app
   behaviour, find the screen that demonstrates it. Missing demonstration is a
   `blocker` finding. Behaviour the prototype adds that the request does not ask
   for is a `scope-creep` finding.
3. **Check the merchant's language.** Read the copy aloud. Flag internal terms
   (table names, API nouns, pipeline words) that would appear on a merchant
   screen. Flag any label a merchant could not explain to a colleague.
4. **Check the states.** Empty, loading, error, permission-denied, and the
   zero-results case. Each missing state is a finding with the screen named.
5. **Check the value proof.** Does the prototype show, on one screen, what the
   merchant gets that they do not get today? If the reviewer has to infer it,
   the prototype fails its only job.
6. **Classify findings**: `blocker` (flow cannot be built as shown), `should-fix`
   (buildable but wrong), `note` (cosmetic or future). Cap `blocker` and
   `should-fix` at five combined — more than five means the flow needs a
   redesign, not a patch list.
7. **Give a verdict**: `pass`, `pass-with-fixes`, or `send-back`. State the one
   reason.
8. **Ask before writing.** Then write `production/apps/<app>/prototype-review.md`
   and, on `pass` or `pass-with-fixes`, propose — never silently perform — the
   `gate-2-prototype` update in `apps/<app>/approvals.json`.

## Outputs

`production/apps/<app>/prototype-review.md`:

- Flow walkthrough with the click-path you had to guess
- Findings table: id | severity | screen | what is wrong | what it should be
- Request coverage table: request line | demonstrating screen | covered?
- Verdict plus the single driving reason

`apps/<app>/approvals.json` — `gate-2-prototype` updated only with the user's
explicit approval, and only by the approving owner.

## Ownership

Owned by **ux-lead**. `polaris-specialist` reviews admin component and layout
choices; `accessibility-specialist` reviews contrast, focus order and label text;
`product-director` makes the gate call. Reviewers do not rewrite the prototype —
findings only.

## Rules

- **Review the request, not your taste.** A design you dislike that satisfies the
  request is a `note`, not a blocker.
- **Every finding names a screen and a file.** "Feels cluttered" is not a finding.
- **No gate self-approval.** The reviewer recommends; the owner approves.
- **Re-review scope.** After a revision, review the changed screens and the
  original blockers only.
