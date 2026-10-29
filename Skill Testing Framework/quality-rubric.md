# Skill Quality Rubric

Used by `/skill-test category [name|all]` to evaluate skills beyond structural compliance.
Each category defines 4–5 binary PASS/FAIL metrics specific to the skill's job.

A metric is PASS when the skill's written instructions clearly satisfy the criterion.
A metric is FAIL when the instructions are absent, ambiguous, or contradictory.
A metric is WARN when the instructions partially address the criterion.

Category membership is the spec directory under `skills/` — the same value the
`category:` field in `catalog.yaml` carries.

---

## Skill Categories

### `gate`

**Skills**: gate-check

Gate skills control an app's stage transitions. They must enforce record order and
never change state without an explicit approval.

| Metric | PASS criteria |
|---|---|
| **G1 — Gate ids validated** | Skill accepts only `gate-1-research`, `gate-2-prototype`, `gate-3-scope`, `gate-4-release`, `gate-5-update`; any other id is refused with the list of five |
| **G2 — Order and idempotency** | Skill refuses a gate whose predecessors are not recorded, and reports an already-recorded gate instead of re-approving it |
| **G3 — Evidence per criterion** | Every criterion is `PASS` / `FAIL` / `N/A` with a recorded evidence path — no bare assertions |
| **G4 — Verdict vocabulary** | Verdict is exactly one of READY / NOT READY / BLOCKED, and BLOCKED is reserved for defects in process state (unregistered app, out-of-order gate, open blocker) |
| **G5 — No unapproved state change** | Skill writes `apps/<app>/approvals.json`, `apps/<app>/status.md` and the app's `docs/registry/apps.json` entry only after an explicit approval, behind "May I write" |

---

### `review`

**Skills**: design-review, architecture-review, prototype-review

Review skills read a document, design or prototype and produce a structured verdict.
They are read-only during analysis and must not change the artifact under review.

| Metric | PASS criteria |
|---|---|
| **R1 — Read-only enforcement** | Skill does not modify the reviewed artifact without explicit user approval; any write (review log, findings file) is gated behind "May I write" |
| **R2 — Per-criterion coverage** | Skill evaluates an explicit, enumerated list of criteria (requirement coverage, ADR references, scopes, Polaris usage, prototype fidelity) — not a free-form opinion |
| **R3 — Correct verdict vocabulary** | Verdict is drawn from a fixed set stated in the skill, e.g. APPROVED / NEEDS REVISION (design), PASS / CONCERNS / FAIL (architecture), READY / NOT READY (prototype) |
| **R4 — No gates during analysis** | Skill does not spawn director gates while analysing; a post-analysis escalation is acceptable when the skill's stake justifies it |
| **R5 — Structured findings** | Output contains a per-criterion status table or checklist before the final verdict |

> `ux-review` lives in `authoring/` and is evaluated against these review metrics.

---

### `readiness`

**Skills**: story-readiness, story-done, app-store-checklist

Readiness skills validate that a unit is ready to enter or leave a stage. They must
produce multi-dimensional verdicts and respect the app's gate records.

| Metric | PASS criteria |
|---|---|
| **RD1 — Multi-dimensional check** | Skill checks ≥3 independent dimensions (requirement reference, ADR/platform notes, scope, acceptance criteria, test evidence, App Store requirements) and reports each separately |
| **RD2 — Three verdict levels** | Verdict hierarchy is clearly defined: READY/COMPLETE > NEEDS WORK/COMPLETE WITH NOTES > BLOCKED |
| **RD3 — BLOCKED requires external action** | BLOCKED is reserved for issues the author cannot fix alone (unapproved ADR, missing gate record, rejected submission criterion) |
| **RD4 — Gate record respected** | Skill reads `apps/<app>/approvals.json` and refuses to pass an item whose required gate is absent; it never writes the gate itself |
| **RD5 — Next-step handoff** | Skill surfaces the next READY story, or the next blocking criterion, from the active sprint or checklist |

> `app-store-checklist` (readiness) is evaluated against these metrics with
> **RD5** read as "names the next failing submission criterion".

---

### `authoring`

**Skills**: create-architecture, architecture-decision, ux-design, quick-design,
mmmvp-proposals, propose-updates, update-request

Authoring skills create or update design documents, proposals and requests
collaboratively. Full authoring skills use a section-by-section cycle; lightweight
skills use a single-draft pattern appropriate to their smaller scope.

| Metric | PASS criteria |
|---|---|
| **A1 — Section-by-section cycle** | Full authoring skills (create-architecture, ux-design) author one section at a time and present it for approval before the next. Lightweight skills (quick-design, architecture-decision, mmmvp-proposals, propose-updates, update-request) may draft the whole artifact then ask |
| **A2 — May-I-write per section** | Full authoring skills ask "May I write this to [filepath]?" before each section write. Lightweight skills ask once for the complete artifact |
| **A3 — Retrofit mode** | Skill detects an existing target file and offers to update named sections rather than overwriting it. New-file-only skills (`mmmvp-proposals`, `propose-updates`) are exempt |
| **A4 — Correct approver** | If the artifact feeds a gate (e.g. `gate-3-scope`: product-director with technical-director), the skill names the approver and does not self-approve |
| **A5 — Skeleton-first** | Full authoring skills write a file skeleton with all section headers before filling content, so an interrupted session keeps progress. Lightweight skills are exempt |

> **Full authoring skills** (must pass all 5): `create-architecture`, `ux-design`
> **Lightweight authoring skills** (A1, A2, A5 single-draft; A3 exempt where new-file-only):
> `quick-design`, `architecture-decision`, `mmmvp-proposals`, `propose-updates`, `update-request`

---

### `pipeline`

**Skills**: create-epics, create-stories, dev-story, create-control-manifest,
create-test-store, deploy-to-test-store, build-prototype, scaffold, release

Pipeline skills produce artifacts other skills consume. They must write files with the
correct schema, respect stage and priority ordering, and gate before writing.

| Metric | PASS criteria |
|---|---|
| **P1 — Correct output schema** | Each produced file follows the project template (EPIC.md, story frontmatter, `apps/<app>/status.md`, control manifest); the skill names the template path |
| **P2 — Stage/priority ordering** | Skills that produce epics or stories respect stage ordering and priority fields; skills that apply changes verify the upstream approval is recorded first |
| **P3 — May-I-write before each artifact** | Skill asks "May I write [artifact]?" before creating each output file, not batch-approving all files at once |
| **P4 — Requires the recorded approval** | In-scope gates (`PR-SCOPE`, `PR-EPIC`, `QL-STORY-READY`, `LP-CODE-REVIEW`, `PR-RELEASE`) run only when their approval is recorded; a missing one is flagged, not assumed |
| **P5 — Reads before writes** | Skill reads the relevant `request.md`, ADR, registry entry or manifest before producing artifacts, to stay aligned |

---

### `analysis`

**Skills**: code-review, consistency-check, scope-check, security-audit, perf-profile,
tech-debt, estimate, test-flakiness, test-evidence-review, research, update-research

Analysis skills scan the project and surface findings. They are read-only during the
scan and must ask before writing any file.

| Metric | PASS criteria |
|---|---|
| **AN1 — Read-only scan** | Analysis phase uses only Read/Glob/Grep (plus read-only Bash); no Write or Edit during the scan itself |
| **AN2 — Structured findings table** | Output includes a findings table or checklist (not prose only) with severity/priority and a file:line or evidence path per finding |
| **AN3 — No auto-write** | Any recommended file writes (tech-debt register, fix patches, registry correction) are gated behind "May I write" |
| **AN4 — No gates during analysis** | Analysis skills do not record or advance a gate; they produce findings for human review |

---

### `sprint`

**Skills**: sprint-plan, sprint-status, milestone-review, retrospective, changelog, patch-notes

Sprint skills read production state and produce reports or planning artifacts. They
must not silently change stage or commit work.

| Metric | PASS criteria |
|---|---|
| **SP1 — Reads production state first** | Skill reads `production/` (sprints, milestones, board) and/or the app registry before producing output |
| **SP2 — Release state respected** | Skills that speak about shipped versions read `apps/<app>/approvals.json` or the release record; none of them may claim a version shipped while `gate-4-release` is absent |
| **SP3 — Structured output** | Output uses a consistent structure (status table, velocity table, risk list, action items) rather than free prose |
| **SP4 — No auto-commit** | Skill never writes sprint files, release notes or tags without "May I write" |

---

### `utility`

**Skills**: start, onboard, adopt, help, brainstorm, bug-report, localize, qa-plan,
regression-suite, smoke-check, soak-test, test-setup, test-helpers, skill-test,
skill-improve, and every other skill whose spec sits in `skills/utility/`
(`feature-request`, `apply-updates`, `hotfix`, `kanban-status`, `launch-checklist`,
`release-checklist`, `prototype`, `reverse-document`, `project-stage-detect`, `bug-triage`)

Utility skills pass the 7 standard static checks. If they touch a gate, the gate id
and approver must also be correct.

| Metric | PASS criteria |
|---|---|
| **U1 — Passes all 7 static checks** | `/skill-test static [name]` returns COMPLIANT with 0 FAILs |
| **U2 — Gate/approver correct (if applicable)** | If the skill touches a gate, it uses a valid gate id and names the right approver from `.claude/docs/director-gates.md` |

---

## Agent Categories

Used to validate agent specs under `agents/`.

### `director`

**Agents**: product-director, technical-director, producer (group `directors`)

| Metric | PASS criteria |
|---|---|
| **D1 — Correct verdict vocabulary** | Returns APPROVE / CONCERNS / REJECT (or domain equivalent: READY / NOT READY / BLOCKED for the producer's gate role) |
| **D2 — Domain boundary respected** | Does not make binding decisions outside its declared domain |
| **D3 — Conflict escalation** | When two domains conflict, escalates to the correct parent (product-director for product/scope, technical-director for architecture/release) rather than unilaterally deciding |
| **D4 — Opus model tier** | Agent is assigned `model: opus` per `.claude/docs/coordination-rules.md` |

### `lead`

**Agents**: lead-engineer, ux-lead, api-lead, app-architect, growth-lead (group `leads`);
qa-lead (group `qa`)

| Metric | PASS criteria |
|---|---|
| **L1 — Domain verdict** | Returns a domain-specific verdict (e.g. FEASIBLE/INFEASIBLE for app-architect, PASS/FAIL for qa-lead, APPROVE/REQUEST CHANGES for lead-engineer) |
| **L2 — Escalates to shared parent** | Out-of-domain conflicts escalate to product-director (product/scope) or technical-director (architecture/release) |
| **L3 — Sonnet model tier** | Agent is assigned `model: sonnet` per `.claude/docs/coordination-rules.md` |

### `specialist`

**Agents**: graphql-specialist, webhooks-specialist, billing-specialist, auth-specialist,
app-bridge-specialist, liquid-specialist, checkout-specialist, tools-engineer,
polaris-specialist, performance-analyst, research-specialist, prototype-builder
(group `specialists`); security-specialist, qa-tester, accessibility-specialist
(group `qa`); release-manager, devops-engineer, analytics-engineer, localization-lead,
app-store-reviewer, test-store-manager, community-manager (group `operations`)

| Metric | PASS criteria |
|---|---|
| **S1 — Stays in domain** | Explicitly scopes itself to its declared Shopify surface (Admin GraphQL, webhooks, billing, auth, App Bridge, Liquid, checkout, App Store) and defers the rest |
| **S2 — No binding cross-domain decisions** | Does not unilaterally decide matters owned by another specialist (e.g. a Liquid specialist does not pin the API version) |
| **S3 — Defers correctly** | Out-of-domain requests are redirected to the correct agent by name, not refused silently |
