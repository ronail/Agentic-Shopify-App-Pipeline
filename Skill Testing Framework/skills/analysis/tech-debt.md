# Skill Test Spec: /tech-debt

> **Category**: analysis  
> **Priority**: medium  
> **Spec written**: 2026-10-29

## Skill Summary

Maintain one app's tech-debt register in docs/architecture/apps/<app>/tech-debt.md: capture entries with evidence, price the interest per sprint, rank by merchant risk, and stop the list from becoming a graveyard. Use at sprint review, before release, and when a shortcut is taken.

- **Invocation**: `/tech-debt` [app: <slug>] [scan | add | rank | paydown] [--sprint]
- **Owner**: `technical-director`
- **Write access**: yes (`Read, Glob, Grep, Bash, Write, Edit, AskUserQuestion, request_user_input, clarify`) — every write needs explicit approval
- **Terminal state**: artifact produced (no verdict token by design)

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 7 `##` sections: “1. Entry Shape”, “2. Scan — Where Debt Actually Hides”, “3. Rank — Price the Interest”, “4. Report / Update”, “5. Paydown Discipline”…)
- [ ] N/A — artifact-producing skill: no verdict keyword by design; success is the artifact existing with its required sections
- [ ] Write approval gate present — the skill requires “Ask before the first write and before any bulk edit: "May I update the tech debt register at…” before writing
- [ ] Next-step handoff section present at end — **GAP**: no explicit next-step section

---

## Director Gate Checks

N/A — this skill produces evidence or artifacts that feed a gate but never records one. It must not write gate approvals or change an app's `stage`.

- **Full mode**: review depth routed through `technical-director`; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — 1. Entry Shape — No entry without evidence.

**Fixture** (assumed project state):
- `docs/architecture/apps/<app>/tech-debt.md`
- `path/to/file.ts:120`
- `apps/order-tags/src/db/orders.ts:88`
- `docs/registry/apps.json` resolves the app slug

**Input:** `/tech-debt` [app: <slug>] [scan | add | rank | paydown] [--sprint]

**Expected behavior**:
1. 1. Entry Shape — No entry without evidence.
2. 2. Scan — Where Debt Actually Hides — Webhook handlers that parse before verifying, or verify per-route with a
3. 3. Rank — Price the Interest — Do not invent decimals.
4. 4. Report / Update — Verification of a paid item is a test, a check, or a cited diff — not "cleaned
5. 5. Paydown Discipline

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output in the skill’s own structure
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Append and update entries; never delete one. Paid entries…

**Fixture**:
- The skill's unconditional rule is violated: Append and update entries; never delete one. Paid entries keep their row and move status.
- No write has been approved

**Expected behavior**:
1. The violated precondition is detected before any finding is produced.
2. The documented blocked/failure state is reported, naming the missing artifact or record.
3. The skill stops and writes nothing.

**Assertions**:
- [ ] Skill reports the block explicitly instead of producing a partial recommendation
- [ ] The message names the specific path or record that failed, not a generic error
- [ ] Skill stops early and does not produce output that pretends the work succeeded
- [ ] No files written without user approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Mode Variant — `--sprint` changes the depth of the run

**Fixture**:
- Standard project state for `/tech-debt`
- Invocation adds `--sprint`

**Expected behavior**:
1. `--sprint` is parsed before any work and the resulting mode is stated in the output header.
2. Check depth widens or narrows consistently with the flag — never silently ignored.
3. Output differs from Case 1 only in the documented way.

**Assertions**:
- [ ] Flag honoured: the run's depth matches what the flag documents
- [ ] Invalid flag values are rejected instead of silently defaulting
- [ ] Mode recorded in the output header so the run is reproducible

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Edge Case — Append and update entries; never delete one. Paid entries…

**Fixture**:
- Boundary condition from the skill's own rules: Append and update entries; never delete one. Paid entries keep their row and move status.

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
- A run that reaches the terminal state
- Review mode: full / lean / solo

**Expected behavior**:
1. No director gate is spawned and no gate approval is written.
2. The handoff names the next skill/agent explicitly (owning agent: `technical-director`).
3. In solo mode the skill still refuses to mark work approved on its own authority.

**Assertions**:
- [ ] In full mode: no gate recorded, and no stage advanced, without an explicit approval in the transcript
- [ ] In lean mode: identical behaviour — no silent auto-advance
- [ ] In solo mode: no director gates spawn and no gate entry is written
- [ ] A CONCERNS or FAIL verdict is never auto-advanced past

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses the skill's documented approval gate before writes: “Ask before the first write and before any bulk edit: "May I update the tech debt register at…”
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (6 numbered steps, 4 rules, 0 declared inputs, 7 `##` sections).
- The body states no verdict keyword; terminal state must be read from the Output section. Verify the static assertion above before running the cases — it is a real finding, not a formatting artefact.
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
