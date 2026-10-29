---
name: project-stage-detect
description: "Detect each Shopify app's pipeline stage from the registry, its status.md, gate approvals, and the artefacts actually present on disk — then name the single next action per app. Read-only. Use when the stage is unclear, after a merge, or at the start of a session you did not begin."
argument-hint: "[app: <slug>] [--verbose]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash
model: sonnet
agent: producer
---

# Project Stage Detect

Answers one question per app: **where is this app in the pipeline, and what is
the next action?** No writes, no fixes, no opinions about design quality.

**Stage ladder** (each stage ends at a gate):

| Stage | Gate that closes it | Ends when |
|-------|--------------------|-----------|
| `research` | `gate-1-research` | the merchant problem, market evidence and API feasibility are approved |
| `architecture` | — (reviewed, not gated) | ADRs and requirements exist for the researched surface |
| `prototype` | `gate-2-prototype` | a store-facing prototype exists under `apps/<app>/prototype/` and has been reviewed |
| `scope` | `gate-3-scope` | scope is frozen against `request.md`; stories are estimable |
| `build` | — (in progress) | sprints deliver against the frozen scope |
| `release` | `gate-4-release` | App Store submission package, security and perf evidence complete |
| `update` | `gate-5-update` | a researched update is planned and approved |

An app can be *between* stages — gate passed, next stage's artefacts not started.
Report that as `stage: prototype, state: not started`.

---

## 1. Read the Record

1. `docs/registry/apps.json` — the app list, each app's `stage`,
   `last_approved_gate`, `created`, `purpose`. This is the claimed truth.
2. `apps/<app>/status.md` — `Stage:`, `Last approved gate:`, `Blockers:`.
3. `apps/<app>/approvals.json` — the actual approvals, keyed by gate id.
4. `apps/<app>/README.md` — purpose, for a sanity check against the registry.

Never skip step 3. `status.md` and the registry are declarations; `approvals.json`
is the record. When they disagree, say so and treat the *lowest* evidence as the
stage — an unrecorded gate is not an approved gate (`gate-check` has the
authority to add it, this skill does not).

---

## 2. Inspect the Artefacts

Presence is evidence; absence is the finding.

| Signal | Path | Indicates |
|--------|------|-----------|
| App scaffold | `apps/<app>/shopify.app.toml`, `package.json` | implementation started |
| Requirements | `docs/architecture/apps/<app>/requirements.yaml` | requirements captured |
| ADRs | `docs/architecture/apps/<app>/adr-*.md` or `ADR-*.md` | architecture decisions recorded |
| Control manifest | `docs/architecture/apps/<app>/control-manifest.md` | programmer rules published |
| Prototype | `apps/<app>/prototype/` with more than `.gitkeep` | prototype built |
| Application source | `apps/<app>/` route/app modules beyond config | build underway |
| Tests | any `*.test.ts(x)` beside source in `apps/<app>/` or `src/` | test coverage exists |
| Sprints | files in `production/apps/<app>/sprints/` beyond `.gitkeep` | sprint activity |
| Milestones | files in `production/apps/<app>/milestones/` beyond `.gitkeep` | milestone work |
| Session state | files in `production/apps/<app>/session-state/` | recent work in flight |
| Release evidence | security audit, perf profile, regression report in milestones/ | release preparation |
| Store listing | App Store checklist artefacts | submission prep |

Enumerate with `find`/`Glob`, then count real files (ignore `.gitkeep`). Report
counts, not adjectives: "3 ADRs, 0 stories" beats "architecture mostly done".

---

## 3. Reconcile

For each app, derive three values and show the disagreement if any:

- **claimed** — registry `stage` + `last_approved_gate`
- **declared** — `status.md`
- **evidenced** — the lowest stage whose required artefacts are actually present
  and whose gate is actually in `approvals.json`

Then classify the state:

| State | Meaning |
|-------|---------|
| `aligned` | claimed == declared == evidenced |
| `claim ahead of evidence` | a gate is claimed but not in `approvals.json`, or stage artefacts are missing |
| `evidence ahead of claim` | work exists (e.g. ADRs, prototype) but no gate was recorded |
| `stale` | `session-state` is old and no sprint/milestone activity since |
| `blocked` | `status.md` lists a blocker; name it and the owner if recorded |

Do not decide which is right — name the divergence and hand the reconciliation
to `producer`. Claiming a stage that the record does not support is a
`consistency-check` critical.

---

## 4. Report

```markdown
# Project Stage Detect

> Date: <date> | Commit: <sha> | Apps: <n>

## Portfolio

| App | Claimed stage | Last gate (record) | State | Blockers | Next action |
|-----|---------------|--------------------|-------|----------|-------------|
| my-app | research | gate-1-research | aligned | none | research the pricing surface, then write ADRs — `/gate-check gate-2-prototype my-app` is not reachable until a prototype exists |
| other-app | research | gate-1-research | claim ahead of evidence | none | ... |

## Per-app detail — <app>

- Registry: stage `research`, last gate `gate-1-research`, created 2026-10-29
- status.md: stage `research`, last gate `gate-1-research`, blockers `none`
- approvals.json: `gate-1-research` approved 2026-10-29 by product-director
- Artefacts: requirements.yaml — no | ADRs — 0 | control manifest — no |
  prototype — empty | source — no | tests — 0 | sprints — 0 | milestones — 0
- Divergence: none
- **Next action:** <one command or one piece of work, with the skill that does it>

## Portfolio gaps
- Apps with a gate claimed but not recorded: <list>
- Apps with work but no gate: <list>
- Apps untouched for longer than a sprint: <list>

## Recommended sequence
1. <app> — <action> (`/<skill>`)
2. ...
```

`--verbose` adds the full artefact inventory per app instead of the summary
line. Ask nothing, write nothing.

---

## 5. Next-Action Rules

Pick exactly one, in this priority order:

1. **Blocked** → resolve the blocker; name the owner.
2. **No scaffold and research stage** → continue research
   (`/research` for the app's problem space), then the research gate.
3. **Research approved, no ADRs** → `/architecture-decision` for the approved
   surface; then `/create-control-manifest`.
4. **ADRs accepted, prototype empty** → `/build-prototype` (or `/prototype` for a
   throwaway spike), then `/prototype-review`.
5. **Prototype reviewed, scope not frozen** → `/scope-check`, then
   `/gate-check gate-3-scope`.
6. **Scope frozen, build stage with no sprint** → `/sprint-plan`.
7. **Sprint in flight with ready stories** → `/dev-story <path>`; then
   `/code-review`, `/story-done`.
8. **Build complete, release evidence missing** → `/regression-suite --full`,
   `/security-audit`, `/perf-profile`, then `/gate-check gate-4-release`.
9. **All gates through release, update requested** → `/update-research`, then
   `/gate-check gate-5-update`.

Never recommend a gate whose input artefacts do not exist. Recommending
`/gate-check gate-2-prototype` for an app with an empty prototype directory
wastes a review cycle and teaches the team to ignore gate recommendations.

---

## Boundary

- Read-only. If reconciliation requires a write, hand it to `gate-check`
  (gate records), `producer` (status/registry), or `consistency-check` (drift
  report).
- Do not judge whether an app *should* advance. That is `product-director`.
