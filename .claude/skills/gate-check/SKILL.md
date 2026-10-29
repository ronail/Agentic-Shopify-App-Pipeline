---
name: gate-check
description: "Check a pipeline gate (gate-1-research, gate-2-prototype, gate-3-scope, gate-4-release, gate-5-update) against one app's approvals.json and the evidence on disk. Reports READY / NOT READY / BLOCKED, and only on explicit approval records the gate and updates the app's stage."
argument-hint: "<gate-id> <app> [--force-reason <text>]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, AskUserQuestion, request_user_input, clarify
model: sonnet
agent: producer
---

# Gate Check

Gates are the only place the pipeline allows state to change. Everything before
a gate is work; the gate is the decision.

**Valid gate ids, verbatim** (they are keys in `apps/<app>/approvals.json`):

| Gate | Closes the stage | Approver |
|------|------------------|----------|
| `gate-1-research` | research | `product-director` |
| `gate-2-prototype` | prototype | `technical-director` |
| `gate-3-scope` | scope | `product-director` with `technical-director` |
| `gate-4-release` | release | `release-manager` with `technical-director` |
| `gate-5-update` | update | `product-director` |

Any other id is a typo — refuse and list the five.

**Output:** conversation verdict. On approval, two writes (see §5):
`apps/<app>/approvals.json` and `apps/<app>/status.md`, plus the `stage`/
`last_approved_gate` fields of that app's entry in `docs/registry/apps.json`.

---

## 1. Preconditions — Check Before Judging

1. Resolve the app from `docs/registry/apps.json`. Not found → **BLOCKED**,
   "app is not registered; no gate can be recorded for it".
2. Read `apps/<app>/approvals.json` and `apps/<app>/status.md`.
3. Verify order: every earlier gate must already be recorded.
   `gate-3-scope` with no `gate-2-prototype` → **BLOCKED**, not "not ready".
4. Idempotency: if this gate is already recorded, report when and by whom, and
   stop. Re-approving corrupts the record.
5. Read `apps/<app>/status.md` blockers — an open blocker is **BLOCKED** unless
   the approver explicitly waives it in writing.

Report stage drift first: if `status.md`, the registry, and `approvals.json`
disagree, that is a `consistency-check` finding and the gate cannot proceed on a
contradicted record.

---

## 2. Criteria Per Gate

Every criterion is `PASS` (evidence path recorded), `FAIL` (missing or
contradicted), or `N/A` (does not apply — with a reason). No bare assertions.

### gate-1-research — is this worth building?
- [ ] `request.md` states the merchant problem and who has it.
- [ ] Research notes exist for this app and name the specific Admin API surface
      needed (operations, objects, scopes) — not "the API can do it".
- [ ] Feasibility is evidenced against the pinned version in
      `docs/shopify-api-reference/<version>/`: the needed mutations/queries
      exist, required scopes are available, and no documented limit blocks the
      approach (rate limits, protected customer data, checkout restrictions).
- [ ] App Store policy risk named: does this need protected customer data,
      checkout extensibility, or a billing model Shopify restricts?
- [ ] A rough effort/complexity estimate exists.
- [ ] `apps/<app>/status.md` reflects stage `research`.

### gate-2-prototype — does the merchant flow hold up?
- [ ] `apps/<app>/prototype/` contains a runnable prototype (beyond `.gitkeep`).
- [ ] The prototype answers a stated question; its README names the question and
      the result.
- [ ] `prototype-review` findings exist, with the merchant-facing verdict.
- [ ] Production isolation holds: no production file imports the prototype.
- [ ] Requirements captured in `docs/architecture/apps/<app>/requirements.yaml`
      for what the prototype proved.
- [ ] Decision recorded: promote, iterate, or abandon.

### gate-3-scope — is the scope frozen and estimable?
- [ ] `requirements.yaml` covers the approved surface with stable `REQ-*` ids.
- [ ] ADRs exist for decisions that constrain other work, status `Accepted`.
- [ ] `control-manifest.md` exists and is date-stamped.
- [ ] Scope statement is frozen in writing; `/scope-check` has run against
      `request.md` with no unresolved creep.
- [ ] Stories are estimable: each has an acceptance criterion a test can assert.
- [ ] Out-of-scope list is explicit.

### gate-4-release — may this ship?
All of these must be strong evidence **on the commit being released**:
- [ ] `/regression-suite --full` PASS (or PASS WITH QUARANTINE with owners and
      no billing/signature test quarantined).
- [ ] `/smoke-check --after-deploy` PASS on the test store, same commit.
- [ ] `/security-audit` complete, no open Critical or High finding.
- [ ] `/perf-profile` within budget on the primary merchant path, or a
      `technical-director` waiver recorded.
- [ ] Billing verified end to end in test mode (subscribe, upgrade, downgrade,
      cancel), and entitlement enforced server-side.
- [ ] Compliance webhooks implemented: `customers/data_request`,
      `customers/redact`, `shop/redact`.
- [ ] Scopes minimal and justified; API version pinned and supported.
- [ ] App Store checklist complete: listing copy, screenshots, privacy policy,
      support contact, pricing, test instructions for reviewers.
- [ ] Deploy, rollback, and migration plan recorded; migrations reversible.
- [ ] `apps/<app>/shopify.app.toml` production config has no dev tunnel URL, no
      test-only flag.

### gate-5-update — may this update ship?
- [ ] The update request is in `request.md` with an entry in
      `request-history.md` (and the app-local history if present).
- [ ] `/update-research` findings exist: API changes, deprecations, merchant
      impact.
- [ ] Impact on shipped behaviour assessed; regression scope defined.
- [ ] Migration/back-compat plan for existing installs, including stored data.
- [ ] Rollback path for merchants who upgrade.
- [ ] The update does not silently change pricing or scopes.

---

## 3. Verdict

```markdown
# Gate Check — <gate-id> / <app>

> Date: <date> | Commit: <sha> | Requested by: <agent/human>

## Preconditions
| Check | Result |
|-------|--------|
| App registered | |
| Prior gates recorded | |
| Gate not already approved | |
| Blockers | |

## Criteria
| # | Criterion | Result | Evidence |
|---|-----------|--------|----------|
| 1 | | PASS/FAIL/N/A | path or number |

## Summary
- PASS: <n> | FAIL: <n> | N/A: <n>
- Blocking failures: <list>

## Verdict: READY / NOT READY / BLOCKED
```

- **READY** — every criterion PASS or justified N/A, prior gates present.
- **NOT READY** — a criterion fails but the record is sound; name the owner and
  the evidence needed.
- **BLOCKED** — the record itself is wrong (unregistered app, gate gap, open
  blocker, contradicted stage). Fix the record first.

Never soften NOT READY into "ready with notes". A gate is binary.

---

## 4. Waivers

A waiver is allowed only for a specific criterion, with:
- the criterion id,
- the reason, in writing, from the approver named for that gate,
- the compensating control,
- an expiry (date or next gate).

Record it as `waived: { criterion, reason, by, on, expires }` in the gate entry.
A waiver for a security Critical finding, an unsigned webhook path, or a
cross-tenant data issue is never granted by this skill — refuse and escalate.

---

## 5. Recording the Gate (only after explicit approval)

Ask, verbatim: *"Gate <gate-id> for <app> is READY. May I record this approval
and advance the app's stage?"*

On approval, three edits, nothing else:

1. **`apps/<app>/approvals.json`** — append a key:

```json
{
  "<gate-id>": {
    "id": "<gate-id>",
    "timestamp": "<ISO-8601 UTC>",
    "approver": "<approver agent>",
    "commit": "<sha>",
    "evidence": ["production/apps/<app>/milestones/perf-<date>.md", "..."],
    "waived": []
  }
}
```

2. **`apps/<app>/status.md`** — set `Stage:` to the next stage and
   `Last approved gate:` to this gate; clear a blocker only if the gate resolved
   it.

3. **`docs/registry/apps.json`** — update **only** the `stage` and
   `last_approved_gate` fields of this app's own entry. Never add, remove,
   reorder, or rewrite other entries; the registry is append-only apart from
   those two live fields.

Stage after each gate:
| Gate approved | Stage becomes |
|---------------|---------------|
| `gate-1-research` | `architecture` |
| `gate-2-prototype` | `scope` |
| `gate-3-scope` | `build` |
| `gate-4-release` | `update` (app is live; further work is an update) |

`release` is a declared stage, not a gate: an app moves from `build` to `release`
in `status.md` when build work is complete and release evidence is being
assembled. Only `gate-4-release` changes the stage again, to `update`.
| `gate-5-update` | `update` (stays; next update cycle) |

Then confirm with a re-read of the three files and show the diff. If any edit
fails, revert the others — a half-recorded gate is worse than none.

---

## Rules

- Check-only by default. No writes without the explicit approval step.
- Never approve a gate for an app you have not read the evidence for.
- Never accept "the tests pass" without a report path and a commit.
- Evidence from a different commit than the one being released is stale — say so
  and re-run the relevant check.
- One app per invocation. Bulk approval of gates across apps is not a thing this
  pipeline does.
