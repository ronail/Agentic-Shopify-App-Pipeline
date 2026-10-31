# Skill Test Spec: /app-page-materials

> **Category**: authoring
> **Priority**: high
> **Spec written**: 2026-10-31

## Skill Summary

Authors the Shopify App Store listing page materials for an app: identity, listing copy, screenshots, app icon, promotional video, pricing presentation, permissions and scopes, and data-handling disclosure. Produces a completed `app-store-listing.md` that `/app-store-checklist` verifies before `/release`.

- **Invocation**: `/app-page-materials` [app-slug]
- **Owner**: no `agent:` frontmatter — runs in the calling context, owned operationally by `app-store-reviewer`
- **Write access**: yes (`Read, Glob, Grep, Write, Edit`) — every write needs explicit approval
- **Terminal state**: listing written with `Verdict: complete` in the Submission Record, or `BLOCKED` when the release checklist is not READY
- **Gates referenced**: `gate-4-release`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has “Phase 1: Parse Arguments”, “Phase 2: Gather Context”, “Phase 3: Author the Listing”, “Phase 4: Write”, “Next Steps”)
- [ ] At least one verdict keyword present (`Verdict: complete` / `BLOCKED`)
- [ ] Write approval gate present — the skill asks “May I write this to `production/apps/<app>/app-store-listing.md`?” before writing
- [ ] Next-step handoff section present at end
- [ ] References the template path `.claude/docs/templates/app-store-listing.md`

---

## Director Gate Checks

This skill works against the approval record and names `gate-4-release`.

- It must read `apps/<app>/approvals.json` and `apps/<app>/status.md` before claiming any gate state.
- It never records a gate or advances an app's `stage`; it authors the artifact the gate verifies.

- **Full mode**: no director fan-out driven by this skill; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — every listing claim must be evidence-backed, never invented

---

## Test Cases

### Case 1: Happy Path — author a complete listing

**Fixture** (assumed project state):
- `apps/<app>/README.md` — the merchant value proposition the listing must match
- `apps/<app>/shopify.app.toml` — pinned `api_version`, `access_scopes`, pricing configuration
- `docs/architecture/apps/<app>/requirements.yaml` — requirement IDs backing each claim
- `docs/architecture/apps/<app>/control-manifest.md` — stored data and surface behaviour
- `production/apps/<app>/release-checklist-<version>.md` — verdict `READY`
- `docs/architecture/apps/<app>/ADR-*.md` — billing and data-handling decisions

**Input:** `/app-page-materials` [app-slug]

**Expected behavior**:
1. Parse the app slug; resolve it from `docs/registry/apps.json`, not by guessing.
2. Confirm `release-checklist` is READY; if not, stop with `BLOCKED`.
3. Fill every template field: identity, listing copy, media (icon + 3 screenshots + optional video), pricing table, permissions/scopes, data handling, review notes.
4. Cross-check: every `access_scopes` entry appears in the scopes table; every plan matches billing config; every screenshot caption names a reachable screen.
5. Write to `production/apps/<app>/app-store-listing.md` with `Verdict: complete` in the Submission Record, after approval.

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before authoring; a missing one is reported, not assumed
- [ ] Produces the documented output (`production/apps/<app>/app-store-listing.md`)
- [ ] Every scope in `shopify.app.toml` appears in the listing's Permissions & Scopes table
- [ ] Every screenshot caption names a screen a merchant actually reaches
- [ ] Terminal state is the skill's own token (`Verdict: complete`), not free prose

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — release checklist not READY

**Fixture**:
- `production/apps/<app>/release-checklist-<version>.md` is `NOT READY` or absent
- No write has been approved

**Expected behavior**:
1. The violated precondition is detected before any listing content is authored.
2. Verdict `BLOCKED` is reported, naming `/release-checklist` as the missing prerequisite.
3. The skill stops and writes nothing.

**Assertions**:
- [ ] Verdict is `BLOCKED`, never a softened “ready with notes”
- [ ] The message names the specific path or record that failed, not a generic error
- [ ] Skill stops early and writes no listing file
- [ ] No files written without user approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Invocation Variant — argument supplied vs. resolved from disk

**Fixture**:
- Standard project state for this skill
- Invocation omits the argument (`/app-page-materials`)

**Expected behavior**:
1. The target is resolved from `request.md` or `production/apps/<app>/session-state/active.md`, never guessed from the app name.
2. If the target is ambiguous, the skill asks instead of picking.

**Assertions**:
- [ ] No argument → target resolved from disk state and stated in the output
- [ ] Ambiguous target → question asked; no writes, no silent default

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Edge Case — listing claims a feature the app does not ship

**Fixture**:
- Standard project state, but the authored copy names a feature absent from `shopify.app.toml` and the built code

**Expected behavior**:
1. The skill applies its documented rule: the listing must describe what the app ships today.
2. The unsupported claim is surfaced to the user with the requirement/scope that is missing.

**Assertions**:
- [ ] Unsupported claim is removed or flagged, not written through
- [ ] Price table matches billing config exactly (mismatch rejected)
- [ ] Output states the resolution so a later reader can reproduce it

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Director Gate — approval boundary

**Fixture**:
- A run that reaches `Verdict: complete`
- Review mode: full / lean / solo

**Expected behavior**:
1. Gate-relevant evidence is reported for `gate-4-release`; the skill writes no gate record.
2. Handoff names the owning gate: `/app-page-materials` → listing → `/app-store-checklist` → `gate-check`.
3. A blocking gap is reported with an owner, not as advice.

**Assertions**:
- [ ] In full mode: no gate recorded, and no stage advanced, without an explicit approval in the transcript
- [ ] In lean mode: identical behaviour — no silent auto-advance
- [ ] In solo mode: no director gates spawn
- [ ] A BLOCKED verdict is never auto-advanced past

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses the skill's documented approval gate before writes: “May I write this to `production/apps/<app>/app-store-listing.md`?”
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (4 phases, 4 rules, 8 declared inputs, 5 `##` sections).
- Anything depending on live Shopify behaviour (screenshot fidelity on the shipped build, billing price parity, scope grants) needs a run against a real dev store — document fixtures cannot prove it.
