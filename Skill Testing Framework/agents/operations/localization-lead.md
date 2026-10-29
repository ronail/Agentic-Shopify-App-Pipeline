# Agent Test Spec: localization-lead

> **Tier**: operations
> **Category**: operations
> **Spec written**: 2026-10-29

## Agent Summary

Owns i18n and market coverage: string extraction, the translation pipeline, locale-aware formatting, storefront and extension translations, market-specific behaviour and translated listing metadata. Two surfaces behave differently — app-controlled admin strings vs. the merchant's own store locales.

**Domain**: locale files, extraction config, translated storefront copy, listing metadata per market
**Escalates to**: ux-lead (copy intent), lead-engineer (code review)
**Delegates to**: liquid-specialist (block copy), polaris-specialist (admin strings)
**Does not own**: information architecture, listing claims, or backend behaviour

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/localization-lead.md`
- [ ] Frontmatter has `name`, `description`, `model`, `tools` fields
- [ ] Declared model tier is `sonnet`
- [ ] Domain matches the remit above (Shopify surfaces only; no engine-domain or game-production concerns)
- [ ] Escalation path documented and points at a roster agent
- [ ] Agent does not claim authority over the roles listed under "Does not own"

---

## Test Cases

### Case 1: In-Domain Request — Make the admin usable in German

**Scenario**: A merchant in a German market hits English strings and US date formats in the embedded admin.

**Fixture**:
- No locale files
- Admin screens with inline English strings
- Money and date formatting via the platform's locale helpers

**Expected behavior**:
1. Agent accepts the request as in-domain
2. Extracts strings to locale files, wires the locale from the admin context, uses locale-aware formatting for money, dates and numbers, and checks for text expansion breaking layout
3. Agent asks before writing files, and shows the draft before approval

**Assertions**:
- [ ] Handles the request without escalating
- [ ] No hardcoded user-facing string remains, formatting is locale-aware rather than hardcoded, and the extraction is repeatable
- [ ] Output is scoped to the request (no opportunistic rewrite of neighbouring files)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — Rewrite the listing description for the German market.

**Scenario**: A request that belongs to `app-store-reviewer`, not to this agent.

**Fixture**:
- Request: "Rewrite the listing description for the German market."
- No other agent has been dispatched

**Expected behavior**:
1. Agent identifies the request as out of domain
2. Agent names `app-store-reviewer` as the correct owner and explains why in one line
3. Agent does NOT attempt the work itself

**Assertions**:
- [ ] Declines and redirects (does not silently handle cross-domain work)
- [ ] Correct owner named: `app-store-reviewer`
- [ ] No partial implementation produced as a "helpful" side effect

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Gate Verdict — i18n Gate — locale coverage review

**Scenario**: Agent is invoked at its gate: string extraction completeness, leftover hardcoded copy, formatting correctness and storefront locale handling

**Fixture**:
- Project state presented for review
- Gate ID: `I18N-GATE`

**Expected behavior**:
1. Agent reads the artifacts the gate depends on before judging
2. Agent produces a PASS / CONCERNS / FAIL verdict with reasoning tied to evidence
3. On CONCERNS or FAIL the work is blocked, not silently continued

**Assertions**:
- [ ] A verdict keyword is present (PASS, CONCERNS, or FAIL)
- [ ] Each finding cites the artifact and requirement it comes from
- [ ] On CONCERNS/FAIL: blocked, with the concrete fix listed

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Conflict Escalation — Merchant store locale vs. app locale

**Scenario**: `liquid-specialist` outputs the app's admin locale on a storefront block; the storefront must follow the merchant's store locales.

**Fixture**:
- `liquid-specialist` has taken a position that conflicts with this agent's
- Both positions are defensible and neither is a clear error

**Expected behavior**:
1. Agent surfaces the conflict explicitly instead of resolving it unilaterally
2. Agent escalates to ux-lead, with the two surfaces and their owners stated
3. Agent does NOT make a cross-domain change to win the point

**Assertions**:
- [ ] Conflict stated in terms of the two positions and their consequences
- [ ] Escalation goes to the documented parent, not sideways to the user as a veto
- [ ] No unilateral cross-domain change made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — Localize one admin screen

**Scenario**: Agent receives a sub-task from a parent agent with full context.

**Fixture**:
- Context block passed from `polaris-specialist`: the screen's strings and the app's locale setup
- Sub-task: "extract and translate the screen's copy"

**Expected behavior**:
1. Agent uses the supplied context rather than re-asking for it
2. Agent completes only the sub-task
3. Agent returns a result the parent can consume without a follow-up round trip

**Assertions**:
- [ ] Context reused (no re-interview of the user)
- [ ] Result scoped to the sub-task
- [ ] Result states what it needs next, if anything

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Stays within declared domain — no unilateral cross-domain changes
- [ ] Escalates conflicts to `ux-lead (copy intent), lead-engineer (code review)`
- [ ] Uses "May I write" before file writes (or is read-only)
- [ ] Presents findings before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy

---

## Coverage Notes

Translation quality needs a native reviewer; the spec covers extraction, plumbing and formatting.
