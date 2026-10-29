# Skill Test Spec: /research

> **Category**: analysis  
> **Priority**: high  
> **Spec written**: 2026-10-29

## Skill Summary

Market research for a Shopify app: validates the merchant problem, maps competitors and their pricing and review complaints, and writes a build/kill recommendation under production/research/<app>/. Use before gate-1-research, when a new app slug has no research folder, or when the merchant problem needs evidence instead of opinion.

- **Invocation**: `/research` <app-slug> [original|competitor-killer]
- **Owner**: no `agent:` frontmatter — runs in the calling context
- **Write access**: yes (`Read, Glob, Grep, Write, Edit, Bash`) — every write needs explicit approval
- **Terminal state**: verdict token `build / defer / kill`
- **Gates referenced**: `gate-1-research`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 7 `##` sections: “Purpose”, “When to use”, “Inputs”, “Steps”, “Outputs”…)
- [ ] At least one verdict keyword present (`build` is the terminal state)
- [ ] Write approval gate present — the skill requires “Ask before writing if the target folder does not exist yet, since this creates `production/research/<app>/`.” before writing
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

This skill works against the approval record and names `gate-1-research`.

- It must read `apps/<app>/approvals.json` and `apps/<app>/status.md` before claiming any gate state.
- It never records a gate or advances an app's `stage`; it produces evidence the gate reads.

- **Full mode**: no director fan-out driven by this skill; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — Resolve the slug. Read docs/registry/apps.json and take the slug…

**Fixture** (assumed project state):
- request.md — Goal, success criteria, the app's stated purpose
- docs/registry/apps.json — Canonical slug, stage, last approved gate
- present but optional: request-history.md, production/research/<app>/

**Input:** `/research` <app-slug> [original|competitor-killer]

**Expected behavior**:
1. **Resolve the slug.** Read `docs/registry/apps.json` and take the `slug` field. Do not invent a slug from the app name; directory names are slugs.
2. **Pick the mode.** `original` (default) means find the gap and own it. `competitor-killer` means name the incumbent and the specific complaint you will fix. If the argument is missing, ask — the two modes produce different recommendations.
3. **State the problem in merchant language.** One paragraph: what a merchant does today, what it costs them (minutes per order, support tickets, refunds, lost conversion). No feature talk in this section.
4. **Search the Shopify App Store** for the problem keywords and record for each listing: name, rating, review count, pricing tiers, install count band, and the recurring complaint in the 1-3 star reviews. Complaints are the useful signal — a five-star listing…
5. **Search outside listings** for the same problem (help-center threads, merchant forums, published pricing pages). Note where merchants describe a workaround — a workaround is an unserved need.

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output (`research.md`)
- [ ] Terminal state is the skill's own token (`build`), not free prose
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Cite or cut. Any claim in research.md that has no entry in…

**Fixture**:
- The skill's unconditional rule is violated: **Cite or cut.** Any claim in `research.md` that has no entry in `sources.md` is removed, not softened.
- No write has been approved

**Expected behavior**:
1. The violated precondition is detected before any finding is produced.
2. The documented blocked/failure state is reported, naming the missing artifact or record.
3. The skill stops and writes nothing.

**Assertions**:
- [ ] Verdict is `build` (or the documented failure token), never a softened "ready with notes"
- [ ] The message names the specific path or record that failed, not a generic error
- [ ] Skill stops early and does not produce output that pretends the work succeeded
- [ ] No files written without user approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Invocation Variant — argument supplied vs. resolved from disk

**Fixture**:
- Standard project state for this skill
- Invocation omits the argument (`/research`)

**Expected behavior**:
1. The target is resolved from registry/state files, never guessed from the app name.
2. If the target is ambiguous, the skill asks instead of picking.

**Assertions**:
- [ ] No argument → target resolved from disk state and stated in the output
- [ ] Ambiguous target → question asked; no writes, no silent default

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Edge Case — Never overwrite an earlier research file. Add a dated…

**Fixture**:
- Boundary condition from the skill's own rules: **Never overwrite** an earlier research file. Add a dated section.

**Expected behavior**:
1. The skill applies its documented rule instead of overwriting or repeating work.
2. The conflict is surfaced to the user with what was found and what the skill did.

**Assertions**:
- [ ] Prior state is either preserved or explicitly superseded with a reason — never silently rewritten
- [ ] Edge case handled without crash or silent failure
- [ ] Output states the resolution so a later reader can reproduce it

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Director Gate — approval boundary

**Fixture**:
- A run that reaches the terminal state `build`
- Review mode: full / lean / solo

**Expected behavior**:
1. Gate-relevant evidence is reported for `gate-1-research`; the skill writes no gate record.
2. Handoff names the owning gate: `/research` → evidence → `gate-check`.
3. A failing criterion is reported as a blocking failure with an owner, not as advice.

**Assertions**:
- [ ] In full mode: no gate recorded, and no stage advanced, without an explicit approval in the transcript
- [ ] In lean mode: identical behaviour — no silent auto-advance
- [ ] In solo mode: no director gates spawn
- [ ] A CONCERNS or FAIL verdict is never auto-advanced past

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses the skill's documented approval gate before writes: “Ask before writing if the target folder does not exist yet, since this creates `production/research/<app>/`.”
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (9 numbered steps, 4 rules, 5 declared inputs, 7 `##` sections).
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
