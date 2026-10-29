# Skill Test Spec: /create-control-manifest

> **Category**: pipeline  
> **Priority**: high  
> **Spec written**: 2026-10-29

## Skill Summary

Use after an app's ADRs are accepted. Produces that app's flat programmer rules sheet — what you must do, must never do, and the guardrail limits, per layer (admin UI, app server, webhooks, extensions, data) — extracted from Accepted ADRs, technical preferences, and the pinned Shopify API snapshot.

- **Invocation**: `/create-control-manifest` [app] [update]
- **Owner**: `technical-director`
- **Write access**: yes (`Read, Glob, Grep, Write, Task, AskUserQuestion, request_user_input, clarify`) — every write needs explicit approval
- **Terminal state**: verdict token `BLOCKED / CONCERNS / COMPLETE`

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 8 `##` sections: “1. Load Inputs”, “2. Extract Rules from Each ADR”, “3. Add Global Rules”, “4. Present the Rule Summary Before Writing”, “4b. Director Gate”…)
- [ ] At least one verdict keyword present (`BLOCKED` is the terminal state)
- [ ] Write approval gate present — the skill requires “4. Present the Rule Summary Before Writing” before writing
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

N/A — this skill produces evidence or artifacts that feed a gate but never records one. It must not write gate approvals or change an app's `stage`.

- **Full mode**: review depth routed through `technical-director`; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — Load silently — read every input before presenting anything.

**Fixture** (assumed project state):
- `docs/architecture/apps/<app>/control-manifest.md`
- `/architecture-review <app>`
- `.claude/rules/`
- `docs/registry/apps.json` resolves the app slug

**Input:** `/create-control-manifest` [app] [update]

**Expected behavior**:
1. **Load silently** — read every input before presenting anything.
2. **Show the summary first** — counts per layer before writing.
3. **Ask before writing** — confirm before creating or overwriting. On write: Verdict **COMPLETE**. On decline: Verdict **BLOCKED** — user declined write.
4. **Source every rule** — a rule with no ADR, rule file, or preference behind it does not go in.
5. **No interpretation** — extract rules as written; do not paraphrase in a way that changes meaning.

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output in the skill’s own structure
- [ ] Terminal state is the skill's own token (`BLOCKED`), not free prose
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — [A] yes — run the director review and write [B] add rules…

**Fixture**:
- Precondition violated: `[A]` yes — run the director review and write `[B]` add rules — I have more to include `[C]` remove rules — some extracted rules should be dropped `[D]` stop — I need to review the ADRs first
- No write has been approved

**Expected behavior**:
1. The violated precondition is detected before any finding is produced.
2. The documented blocked/failure state is reported, naming the missing artifact or record.
3. The skill stops and writes nothing.

**Assertions**:
- [ ] Verdict is `BLOCKED` (or the documented failure token), never a softened "ready with notes"
- [ ] The message names the specific path or record that failed, not a generic error
- [ ] Skill stops early and does not produce output that pretends the work succeeded
- [ ] No files written without user approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Invocation Variant — argument supplied vs. resolved from disk

**Fixture**:
- Standard project state for this skill
- Invocation omits the argument (`/create-control-manifest`)

**Expected behavior**:
1. The target is resolved from registry/state files, never guessed from the app name.
2. If the target is ambiguous, the skill asks instead of picking.

**Assertions**:
- [ ] No argument → target resolved from disk state and stated in the output
- [ ] Ambiguous target → question asked; no writes, no silent default

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Edge Case — Every mandated approach: session-token auth on every admin…

**Fixture**:
- Boundary condition from the skill's own rules: Every mandated approach: session-token auth on every admin request, server-side Admin GraphQL calls, shop-scoped queries, idempotent webhook handlers

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
- A run that reaches the terminal state `BLOCKED`
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

- [ ] Uses the skill's documented approval gate before writes: “4. Present the Rule Summary Before Writing”
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (5 numbered steps, 9 rules, 0 declared inputs, 8 `##` sections).
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
