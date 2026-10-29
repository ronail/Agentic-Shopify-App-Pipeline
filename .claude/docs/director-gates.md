# Director Gates

Gate definitions for the Shopify app pipeline. Skills reference gate ids from
this file instead of embedding prompts inline — one place to change a gate.

Two families live here:

- **Approval gates** (`gate-1-research` … `gate-5-update`) — they close a
  pipeline phase and are recorded in `apps/<app>/approvals.json`. These are the
  only ids `approval-gate.sh` and `gate-check` recognise.
- **Review gates** (`LP-CODE-REVIEW`, `QL-STORY-READY`, …) — per-skill quality
  checks. They return a verdict to the calling skill and are not persisted as
  phase approvals.

Handoff graph and phase model: `agent-coordination-map.md`. Review passes:
`review-workflow.md`.

---

## Review modes

Resolve the mode once per skill run, before any gate spawn:

1. `--review [full|lean|solo]` on the skill call, else
2. `production/review-mode.txt` (one word), else
3. `lean`.

| Mode | What runs |
|---|---|
| `full` | every review gate plus the phase-gate panel |
| `lean` | phase-gate panel only — **default** |
| `solo` | no director gates; each skip is noted `[GATE-ID] skipped — Solo mode` |

Solo and lean never skip security review, accessibility review, or the App Store
checklist. Those are release evidence, not director opinions.

---

## Invocation pattern

```
# Resolve the mode first, then:
Spawn `[agent]` via Task:
- Gate: [GATE-ID] (see .claude/docs/director-gates.md)
- Context: the fields listed under that gate
- Await the verdict before proceeding.
```

For a panel at one phase boundary, resolve the mode for each gate, then issue
all Task calls before awaiting any result. Collect every verdict, then apply the
strictest.

---

## Verdict format

| Verdict | Meaning | Default action |
|---|---|---|
| **APPROVE / READY** | no blocking issue | continue |
| **CONCERNS [list]** | real issues, not blocking | surface to the user: revise / accept / discuss |
| **REJECT / NOT READY [blockers]** | blocking | stop; name the owner and the evidence required |

**Escalation**: with a parallel panel, one NOT READY overrides every READY.

---

## Recording an approval gate

After explicit human approval, `gate-check` writes three things and nothing else:

```json
{
  "gate-4-release": {
    "id": "gate-4-release",
    "timestamp": "2026-11-02T09:14:00Z",
    "approver": "release-manager",
    "commit": "<sha>",
    "evidence": ["production/apps/<app>/app-store-checklist.md"],
    "waived": []
  }
}
```

1. `apps/<app>/approvals.json` — the record above. Missing `id`, `timestamp`, or
   `approver` means **not approved**.
2. `apps/<app>/status.md` — `Stage:` and `Last approved gate:`.
3. `docs/registry/apps.json` — only that app's `stage` and `last_approved_gate`.

Order is enforced: `gate-3-scope` with no `gate-2-prototype` is BLOCKED, not
NOT READY. An already-recorded gate is reported and left alone — re-approving
corrupts the record.

Review-gate verdicts are recorded in the document under review:

```markdown
> **Review (LP-CODE-REVIEW)**: APPROVED 2026-11-02 / CONCERNS (accepted) / REVISED
```

---

## The five approval gates

### gate-1-research — is this worth building?

| Field | Value |
|---|---|
| **Fires** | end of phase 1, before architecture |
| **Owner** (assembles evidence) | `research-specialist` |
| **Required approver** | `product-director` |
| **Unlocks** | `advance-phase <app> research` |

**Required evidence**
- `request.md` states the merchant problem, the segment, and the non-goals.
- Research brief under `production/research/<app>/`: competitors, pricing,
  review complaints, wedge.
- The Admin API surface is named (objects, mutations, scopes) and exists in the
  pinned version under `docs/shopify-api-reference/<version>/`.
- Documented limits checked: rate limits, protected customer data, checkout
  restrictions.
- App Store policy risk named: protected data, checkout extensibility, billing
  model restrictions.
- Rough effort/complexity estimate.
- UX specs reviewed: `apps/<app>/design/ux/*.md` pass `ux-review`.
- `apps/<app>/status.md` says stage `research`.

**Blocks advancement**: no named API surface, "the API can do it" with no
operation cited, unassessed policy risk, missing estimate, UX specs that fail
Polaris/App Bridge/accessibility review, or research that recommends kill.

**Approver prompt**: "Is this worth building now? Judge the evidence, not the
enthusiasm: is the merchant problem specific and evidenced, does the named API
surface support the approach at the pinned version, and is the policy risk
acceptable? Return APPROVE, CONCERNS [list], or REJECT [reasons]."

---

### gate-2-prototype — does the merchant flow hold up?

| Field | Value |
|---|---|
| **Fires** | end of phase 2, before scope is cut |
| **Owner** | `prototype-builder` |
| **Required approver** | `technical-director` |
| **Unlocks** | `advance-phase <app> prototype` |

**Required evidence**
- `apps/<app>/prototype/` holds a runnable prototype (not just `.gitkeep`).
- `prototype/README.md` names the question it answered and the result.
- `prototype-review` findings exist with a merchant-facing verdict.
- Production isolation: no production file imports the prototype.
- Requirements proved by the prototype captured in
  `docs/architecture/apps/<app>/requirements.yaml`.
- Decision recorded: promote, iterate, or abandon.
- ADRs `Accepted`; `control-manifest.md` present and date-stamped.
- Performance budgets set by `performance-analyst`; a preview deploy exists.

**Blocks advancement**: a prototype that answers no stated question, production
import of prototype code, missing decision, ADRs still `Proposed`, no budgets,
no environment to test in.

**Approver prompt**: "Does this prototype settle the question it was built for?
Check that the question was falsifiable, that the result is written down, that
prototype code is isolated from production, and that the architecture it implies
is one we can build. Return APPROVE, CONCERNS [list], or REJECT [blockers]."

---

### gate-3-scope — is the scope frozen and estimable?

| Field | Value |
|---|---|
| **Fires** | end of phase 3, before build |
| **Owner** | `producer`, with `app-architect` for the artifact set |
| **Required approver** | `product-director` with `technical-director` |
| **Unlocks** | `advance-phase <app> scope` |

**Required evidence**
- `requirements.yaml` covers the approved surface with stable `REQ-*` ids.
- ADRs for decisions that constrain other work, status `Accepted`.
- `control-manifest.md` exists and is date-stamped.
- Scope statement frozen in writing; `/scope-check` run against `request.md`
  with no unresolved creep.
- Every story has an acceptance criterion a test can assert.
- Out-of-scope list explicit.
- Sprint plan written: owners, estimates, dependencies.
- Translation effort and App Store submission requirements scoped as stories.

**Blocks advancement**: stories that cannot be estimated, missing out-of-scope
list, unresolved creep, unowned submission blockers, or work that silently
assumes an unapproved API surface.

**Approver prompt**: "Is this scope frozen and buildable as written? Check for
requirements without `REQ-*` ids, stories with no assertable acceptance
criterion, creep against `request.md`, and work that assumes an unapproved
surface. Return APPROVE, CONCERNS [list], or REJECT [blockers]."

---

### gate-4-release — may this ship?

| Field | Value |
|---|---|
| **Fires** | end of phase 4, before submission |
| **Owner** | `release-manager` |
| **Required approver** | `release-manager` with `technical-director` |
| **Unlocks** | `/release <app>`, `advance-phase <app> release` |

All evidence must be on **the commit being released**.

**Required evidence**
- `/regression-suite --full` PASS, or PASS WITH QUARANTINE with owners and no
  billing or signature test quarantined.
- `/smoke-check --after-deploy` PASS on the test store, same commit.
- `/security-audit` complete, no open Critical or High.
- `/perf-profile` inside budget on the primary merchant path, or a
  `technical-director` waiver recorded.
- Billing verified end to end in test mode (subscribe, upgrade, downgrade,
  cancel); entitlement enforced server-side.
- Compliance webhooks implemented: `customers/data_request`, `customers/redact`,
  `shop/redact`.
- Scopes minimal and justified; API version pinned and supported.
- App Store checklist complete: listing copy, screenshots, privacy policy,
  support contact, pricing, reviewer test instructions.
- Deploy, rollback, and migration plan recorded; migrations reversible.
- `apps/<app>/shopify.app.toml` has no dev tunnel URL and no test-only flag.
- Accessibility review clear of WCAG 2.1 AA blockers; shipped locales render.

**Blocks advancement**: any FAIL in
`production/apps/<app>/app-store-checklist.md` (enforced by
`app-store-gate.sh`), an open security Critical/High, a quarantined billing or
signature test, unverified compliance webhooks, or evidence from another commit.

**Approver prompt**: "May this commit ship? Verify each evidence item is on this
commit and that the App Store checklist is fully PASS. Treat a missing
compliance webhook, an unverified signature path, or a server-side entitlement
gap as a hard reject. Return APPROVE, CONCERNS [list], or REJECT [blockers]."

---

### gate-5-update — may this update ship?

| Field | Value |
|---|---|
| **Fires** | before any update is applied to a shipped app |
| **Owner** | `release-manager` |
| **Required approver** | `product-director` |
| **Unlocks** | `/apply-updates <app>`, `/propose-updates <app>`, `advance-phase <app> update` |

**Required evidence**
- The update is in `request.md` with an entry in `request-history.md` (and the
  app-local history if present).
- `/update-research` delta exists: platform changes, deprecations, competitor
  moves, merchant impact.
- Impact on shipped behaviour assessed; regression scope defined.
- Migration and back-compat plan for existing installs, including stored data.
- Rollback path for merchants who upgrade.
- No silent pricing or scope change.
- Predecessor gates intact; `approvals.json` not rewritten.

**Blocks advancement**: an update with no request entry, a pricing or scope
change buried in a "fix", a migration with no reverse path, or a deprecation
that forces a version move with no plan.

**Approver prompt**: "Is this update worth disturbing shipped merchants for?
Check that it is requested and recorded, that the deprecation or competitor
driver is real, that existing installs migrate without data loss or forced
re-authorisation, and that pricing and scopes are unchanged. Return APPROVE,
CONCERNS [list], or REJECT [blockers]."

---

## Review gates (per-skill)

These never touch `approvals.json`; each returns a verdict to the caller.

| Gate | Agent | Fires in | Context to pass | Blocking |
|---|---|---|---|---|
| **LP-CODE-REVIEW** | `lead-engineer` | `story-done`, `code-review` | diff, touched files, story acceptance criteria, `.claude/docs/coding-standards.md` | yes |
| **SEC-REVIEW** | `security-specialist` | auth/token/webhook/data changes; `security-audit` | changed paths, scope list, session and webhook handling, data retention | yes |
| **UX-REVIEW** | `ux-lead` | `ux-design`, `ux-review` | flow spec, screen inventory, states, copy | yes |
| **A11Y-REVIEW** | `accessibility-specialist` | admin UI changes | screens, keyboard/focus paths, contrast, motion | yes for AA blockers |
| **QL-STORY-READY** | `qa-lead` | `create-stories`, `story-readiness` | story file, acceptance criteria, dependencies, test approach | yes |
| **QL-TEST-COVERAGE** | `qa-lead` | `story-done` | story, tests written, evidence paths, risk level | yes |
| **PR-EPIC** | `producer` | `create-epics` | epic set, module boundaries, dependencies, sequencing | advisory |
| **PR-SPRINT** | `producer` | `sprint-plan` | sprint goal, story set, estimates, capacity, risks | advisory |
| **TD-ARCHITECTURE** | `technical-director` | `create-control-manifest`, `architecture-review` | ADR set, `requirements.yaml`, control manifest, pinned API version | yes |
| **AS-CHECKLIST** | `app-store-reviewer` | `app-store-checklist` | `shopify.app.toml`, billing implementation, listing draft, last readiness report | yes (release) |

Standard for all of them: judge the artifact, cite the requirement or coding
standard each finding violates, name an owner per finding, return a verdict.

---

## Phase-gate panel

At a phase boundary in `full` mode, spawn the panel at once and apply the
strictest verdict:

| Gate | Agent | Question |
|---|---|---|
| **PD-PHASE-GATE** | `product-director` | does this still serve the merchant problem in `request.md`? |
| **TD-PHASE-GATE** | `technical-director` | is the architecture still sound at the pinned API version? |
| **PR-PHASE-GATE** | `producer` | is the plan deliverable with the capacity and dependencies we have? |
| **QL-PHASE-GATE** | `qa-lead` | is the quality evidence sufficient to enter the next phase? |
| **AD-PHASE-GATE** | `app-architect` | do the ADRs, requirements, and control manifest still describe the system? |

`lean` mode runs this panel only. Skills that still reference `CD-PHASE-GATE`
should read `PD-PHASE-GATE` — there is no creative director in this pipeline.

---

## Skill → gate map

| Skill | Gate |
|---|---|
| `research` | feeds `gate-1-research` |
| `update-research` | feeds `gate-5-update` |
| `ux-design`, `ux-review` | `UX-REVIEW`, then `A11Y-REVIEW` |
| `build-prototype`, `prototype-review` | feeds `gate-2-prototype` |
| `create-architecture`, `architecture-review`, `create-control-manifest` | `TD-ARCHITECTURE` |
| `create-epics` | `PR-EPIC` |
| `create-stories`, `story-readiness` | `QL-STORY-READY` |
| `sprint-plan` | `PR-SPRINT` |
| `dev-story`, `story-done` | `LP-CODE-REVIEW`, `QL-TEST-COVERAGE` |
| `code-review` | `LP-CODE-REVIEW` |
| `security-audit` | `SEC-REVIEW` |
| `app-store-checklist` | `AS-CHECKLIST`, then `gate-4-release` |
| `release` | `gate-4-release` |
| `apply-updates`, `propose-updates` | `gate-5-update` |
| `gate-check` | any of the five approval gates |

---

## Enforcement

- `approval-gate.sh` blocks `/release`, `/apply-updates`, and `advance-phase`
  unless the required gate id is recorded with both a timestamp and an approver.
- `app-store-gate.sh` blocks release when the checklist is missing, has no
  `Verdict:` line starting with `ready`, contains a `FAIL` row, or has an
  unticked box.
- Exit `2` stops the action. There is no "proceed anyway" flag short of a waiver
  recorded in the gate entry by the named approver.

## Adding a gate

Approval gates are a closed set of five; a sixth requires a decision record and
changes to `gate-check` and `approval-gate.sh` together. Review gates:
`[PREFIX]-[SLUG]` using `PD- TD- PR- LP- QL- SEC- UX- AS-`, defined with
trigger, context, prompt, and verdicts, then referenced by id only.
