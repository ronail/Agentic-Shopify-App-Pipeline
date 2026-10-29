---
name: consistency-check
description: "Detect drift between the app registry, app directories, status files, gate approvals, architecture docs, and pinned Shopify API versions. Read-only audit with a drift table and a recommended owner per mismatch. Run after any structural change, and before gate-4-release."
argument-hint: "[app: <slug> | all] [--fix-plan]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, request_user_input, clarify
model: sonnet
agent: technical-director
---

# Consistency Check

The pipeline's integrity rests on a handful of files agreeing with each other.
When they drift, agents act on lies: a gate that was never approved, an app
that exists in the registry but not on disk, an ADR pinning an API version the
app does not run.

**This skill is read-only.** It reports drift and names the owner; it does not
"helpfully" rewrite files.

**Output:** conversation report. With `--report`, write to
`production/session-state/consistency-<date>.md` (per-session, never a shared
accumulating log).

---

## 1. Sources of Truth

| Fact | Authoritative source | Mirrors that must agree |
|------|----------------------|-------------------------|
| Which apps exist | `docs/registry/apps.json` | `apps/<app>/` dirs, `production/apps/<app>/` dirs |
| App stage | `apps/<app>/status.md` | registry `stage`, registry `last_approved_gate` |
| Gate approval | `apps/<app>/approvals.json` | status.md `Last approved gate`, registry `last_approved_gate` |
| App purpose | registry `purpose` | `apps/<app>/README.md` first paragraph |
| Pinned API version | `apps/<app>/shopify.app.toml` | ADR `Shopify API Surface`, `docs/shopify-api-reference/<version>/` existence |
| Scopes | `shopify.app.toml` | ADR Shopify API Surface, OAuth/session code paths |
| Webhook topics | `shopify.app.toml` | route handlers, ADR Shopify API Surface |
| Requirements | `docs/architecture/apps/<app>/requirements.yaml` | ADR "App Requirements Addressed", stories |
| Architecture decisions | `docs/architecture/apps/<app>/` ADRs | `docs/registry/architecture.yaml` stances |
| Request scope | `request.md` | `request-history.md`, `apps/<app>/request-history.md` |

Read `docs/registry/apps.json` first. Every other check is expressed relative to
it — an app missing from the registry is invisible to the whole pipeline, which
is the most damaging drift of all.

---

## 2. Checks

### C1 — Registry ↔ directories
- For each registry entry: `apps/<slug>/` exists, contains `README.md`,
  `status.md`, `approvals.json`.
- For each `apps/<app>/` directory: an entry exists in the registry. A directory
  with no entry is **critical** — no gate can ever be recorded for it.
- For each registry entry: `production/apps/<slug>/` exists with `sprints/`,
  `milestones/`, `session-state/`.
- Orphan directories under `production/apps/` with no registry entry → critical.
- Registry entries are append-only: check git history for deleted or reordered
  entries (`git log -p -- docs/registry/apps.json`). A deleted entry is a
  finding even if the current file looks fine.

### C2 — Stage and gates agree
- Parse `gate-N-*` keys from `approvals.json` and compare with `status.md`
  `Last approved gate` and the registry's `last_approved_gate`.
- Gate sequence must be monotonic: you cannot hold `gate-3-scope` without
  `gate-1-research` and `gate-2-prototype`. A gap is **critical** — later gates
  were approved against unapproved foundations.
- Valid ids only: `gate-1-research`, `gate-2-prototype`, `gate-3-scope`,
  `gate-4-release`, `gate-5-update`. Anything else is a typo finding.
- Each gate entry carries `id`, `timestamp`, `approver`; a missing approver means
  the approval is unattributable — treat as not approved.
- Stage string in `status.md` must be a known stage name
  (`research`, `architecture`, `prototype`, `scope`, `build`, `release`,
  `update`) and must be consistent with the last approved gate (an app whose
  last gate is `gate-3-scope` is in `build`, not `research`).

### C3 — Cross-doc: API version and surfaces
- Extract the API version from `apps/<app>/shopify.app.toml`.
- Find every ADR in `docs/architecture/apps/<app>/` and read its *Shopify API
  Surface* section. Versions must match the toml. A mismatch is **high**: the
  ADR is the document stories are built against.
- `docs/shopify-api-reference/<version>/` must exist and be readable. A pinned
  version with no snapshot means agents will invent field names — high.
- Scopes: set-compare `scopes` in toml against the scopes listed in the ADR and
  the scopes actually referenced by code paths. Extra scope in toml = medium
  (over-permissioned); scope used in code but absent from toml = high (the call
  will fail at runtime for every merchant).
- Webhook topics: set-compare toml subscriptions against handler routes. A
  subscribed topic with no handler = high (silent delivery failures after
  Shopify's retry window); a handler for an unsubscribed topic = medium (dead
  code or a config omission).

### C4 — Requirements and stories
- Every requirement id in `docs/architecture/apps/<app>/requirements.yaml` that
  is claimed by an ADR exists in the registry (no renumbering drift).
- Requirement ids referenced by sprint/story files under
  `production/apps/<app>/sprints/` resolve. A dangling id means the story was
  written against a deleted requirement.
- Requirement ids are unique, stable, and match `REQ-<AREA>-<NNN>`. Detect
  duplicates and gaps introduced by renumbering.

### C5 — App-local docs
- `apps/<app>/README.md` purpose line matches registry `purpose`.
- `apps/<app>/request-history.md` exists and its latest entry is not older than
  the last change to `request.md` that names this app.
- `design/` and `src/` shared assets are not duplicated inside an app directory
  (isolation contract: shared assets live at the top level).

### C6 — Pipeline artefacts
- Sprint files under `production/apps/<app>/sprints/` reference stories that
  exist, and the sprint id sequence has no gaps.
- Source code does not live under `production/apps/<app>/`. A source file there
  is a **high** isolation breach — it will not be built or tested.
- No app directory contains another app's slug in an import path. Cross-app
  imports are an isolation breach by definition.

---

## 3. Report Format

```markdown
# Consistency Check — <scope>

> Date: <date> | Commit: <sha> | Apps checked: <n>

## Summary
| Check | Findings | Worst severity |
|-------|----------|----------------|
| C1 registry ↔ dirs | | |
| C2 stage ↔ gates | | |
| C3 API version & surfaces | | |
| C4 requirements & stories | | |
| C5 app-local docs | | |
| C6 pipeline artefacts | | |

## Findings

| ID | Check | Severity | App | Expected | Actual | Owner | Fix |
|----|-------|----------|-----|----------|--------|-------|-----|
| CONS-001 | C2 | critical | order-tags | gates 1,2,3 present | gate-3 without gate-2 | producer | record or remove gate-3 |

## Verified clean
<list the checks that found nothing — absence of evidence matters>

## Verdict: CONSISTENT / DRIFT DETECTED (n critical, n high)
```

Severity definitions:
- **critical** — the pipeline's own record is wrong (missing registry entry,
  gate gap, stage contradiction). Any agent acting on it will do the wrong work.
- **high** — a document contradicts code/config in a way that produces broken
  calls or unhandled deliveries.
- **medium** — over-permission, dead config, or a mirror that is stale but not
  yet misleading.
- **low** — naming, ordering, cosmetic.

---

## 4. After the Report

- Do not fix silently. Route each finding:
  registry/status/approvals → `producer` (or `product-director` when a gate
  record is in question)
  API version, scopes, webhook topics → `api-lead` with `app-bridge-specialist`
  or `webhooks-specialist` as applicable
  requirements and ADR linkage → `app-architect`
  source under `production/` or cross-app imports → `lead-engineer`
  request/prototype drift → `scope-check` next
- Critical findings block `/gate-check` for the affected app until resolved.
- If `--fix-plan` was passed, append an ordered remediation plan grouped by
  owner, smallest safe change first, with the check ids it closes.
