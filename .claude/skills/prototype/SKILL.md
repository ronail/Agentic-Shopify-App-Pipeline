---
name: prototype
description: "Build a throwaway prototype of an app's merchant-facing flow under apps/<app>/prototype/ — real Polaris screens, mock data, no tests, no coverage requirement, and structurally unimportable by production code. Timeboxed to answer one question. Promote via build-prototype, review via prototype-review."
argument-hint: "[app: <slug>] [question: <what the prototype must answer>] [--timebox 2h|4h|1d]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, AskUserQuestion, request_user_input, clarify
model: sonnet
agent: prototype-builder
---

# Prototype

A prototype exists to answer a question cheaply — does this flow make sense to a
merchant, is this the right data shape, is this screen readable at 40 rows.
Anything that survives into production is a bonus, not the goal.

**Hard rules:**
1. Everything lives under `apps/<app>/prototype/`. Nothing outside it.
2. **Production code must not import from the prototype.** No route, module, or
   shared file under `apps/<app>/` or `src/` may reference
   `apps/<app>/prototype/`. If the prototype needs a helper, copy it — do not
   make production depend on throwaway code.
3. No test requirement, no coverage floor, no doc-comment requirement. Speed is
   the point.
4. Timebox is declared up front and enforced. Hitting the timebox with an
   unfinished prototype is a valid, reportable outcome.

**Output:** code under `apps/<app>/prototype/` plus a short `README.md` in that
directory stating the question, what was built, and what it proved.

---

## 1. State the Question

A prototype without a question is a half-built app. Before writing code, write
down one sentence:

> "This prototype must answer: *can a merchant understand and create a
> percentage bundle discount in under 60 seconds without documentation?*"

If the requester cannot state the question, ask. Common valid questions:
- Is this data shape sufficient to render the screen the merchant needs?
- Does this flow survive the empty / error / 500-row states?
- Is this interaction obvious without explanatory copy?
- Does the Polaris component actually support what the design assumes?

Invalid questions for a prototype: "build the app", "make it production ready",
"wire up billing". Those are not questions, and they are not throwaway.

---

## 2. Read the Constraints

- `apps/<app>/status.md` — the stage. A prototype is normally built between
  research and the `gate-2-prototype` review.
- `apps/<app>/README.md` and the research notes — the merchant problem.
- `docs/architecture/apps/<app>/requirements.yaml` if it exists — the
  requirement the prototype is exploring.
- `.claude/docs/technical-preferences.md` — stack (React, Polaris, TypeScript),
  naming conventions, forbidden patterns. Even throwaway code should not model
  a forbidden pattern, because someone will copy it.
- `.claude/docs/directory-structure.md` — confirm nothing belongs outside
  `apps/<app>/prototype/`.

---

## 3. Choose the Smallest Viable Build

| Question type | Build |
|---------------|-------|
| Flow / comprehension | Static Polaris screens with hardcoded data and click-through navigation |
| Data shape | A typed mock dataset that mirrors the real Admin API object shape, rendered in the real component |
| Interaction | One screen, fully interactive, local state only, no server |
| Layout/scale | The screen with generated rows at realistic volume (e.g. 500 variants) |
| Copy/structure | Screen with representative copy and the empty/error states |

Deliberately omit:
- auth, session handling, billing, webhooks,
- database, migrations, real Admin API calls,
- tests, CI wiring, error tracking.

If the question genuinely requires real store data, say so — that is a
`build-prototype` (against a dev store) rather than a throwaway, and it needs
the app's real auth path.

**Mock data rules:**
- Mirror the shape of the pinned Admin API objects, so a later port does not
  discover a field-name surprise. Read
  `docs/shopify-api-reference/<version>/` for the real shape.
- Use realistic merchant values: real-looking product titles, prices with a
  currency, multi-currency where relevant, long strings that will break a
  layout.
- Include the ugly cases: no results, one result, 500 results, a failed load.

---

## 4. Build

- TypeScript, React, Polaris — same stack as production, so the prototype's
  verdict transfers.
- File names and component names follow the project's conventions. Copying a
  component into production later should be a move, not a rename.
- Keep it runnable without the Shopify tunnel: if the prototype needs a dev
  server, add a `README.md` line with the exact command, and keep any local
  script inside the prototype directory.
- Do not add dependencies at the repo root for a prototype. If a chart library
  is needed, note it as a finding for `technical-director` rather than
  installing it into the shared manifest.
- Log decisions as comments in the prototype README, not in production docs. A
  prototype's findings belong in the review, not in a permanent architecture doc
  until they are accepted.

---

## 5. Stop at the Timebox

Default `2h`. If the question is not answered at the timebox, report:

- what was built,
- what the question was,
- what blocked the answer,
- the smallest next step that would answer it.

That is a successful prototype run — a cheap negative answer is a good outcome.

---

## 6. Protect Production

After building, verify the isolation:

```bash
# nothing outside the prototype directory references it
grep -rn "prototype/" apps/<app> --include=*.ts --include=*.tsx | grep -v "^apps/<app>/prototype/"
```

Expected: no matches. Any match is a breach — remove the import before reporting
done. Also confirm:
- [ ] no production file imports from the prototype,
- [ ] the prototype is not wired into the app's route manifest or build entry,
- [ ] no repo-level config was changed to make the prototype build,
- [ ] the prototype does not write to the app's database or dev store.

---

## 7. Report and Hand Off

```markdown
# Prototype — <app>

> Date: <date> | Timebox: <n> | Author: prototype-builder

## Question
<one sentence>

## What was built
<files under apps/<app>/prototype/ — screens, states covered>

## What it proved
<direct answer to the question, with the observation that supports it>

## What it did not prove
<explicit — e.g. "no real API latency; no permission model">

## Production implications
<components worth promoting, data-shape changes needed, Polaris limits hit>

## Isolation check
- Imports from production code: none
- Route manifest touched: no
- Shared dependencies added: none

## Recommend: promote / iterate / abandon
```

Then:
- Promote → `/build-prototype` (builds the real thing on a dev store) and
  `/prototype-review` for the merchant-facing judgement.
- Iterate → say what changes, keep the same timebox.
- Abandon → leave the directory and the README; the negative result is the
  record.

Ask before writing; for prototype code, a single approval for the planned files
under `apps/<app>/prototype/` is enough — do not interrupt for each file.
