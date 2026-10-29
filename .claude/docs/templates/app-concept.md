# App Concept: [App Name]

> **App**: `apps/<app>` · **Date**: [YYYY-MM-DD] · **Stage**: concept (pre-prototype)
> **Produced by**: `/research` · **Feeds**: `app-prd.md`, `pitch-document.md`

## One Sentence

[What it does, for whom, and the outcome — no adjectives.]

## The Merchant

| Field | Value |
|-------|-------|
| Segment | [e.g. 200-2,000 orders/month, in-house fulfilment] |
| Store setup | [Plan tier, markets, locations, apps already installed] |
| Who uses it | [Owner / ops manager / developer] |
| Frequency of use | [Daily / weekly / when something breaks] |
| Technical comfort | [Low / medium / high] |

## Job To Be Done

> When [situation], I want to [motivation], so I can [expected outcome].

[Write it as the merchant would say it, then annotate: what triggers the job, what
they do today, what "good" looks like.]

## The Gap

| What exists | What it does | What it misses |
|-------------|--------------|----------------|
| [App 1] | [Capability] | [The gap] |
| [Shopify native feature] | [Capability] | [The gap] |
| [Spreadsheet / manual] | [Free but slow] | [The gap] |

**Our wedge**: [The one thing we do that none of the above does — and why that
matters enough to install.]

## Evidence

- **Competitor signals**: [ratings, review complaints, pricing, install counts] —
  link the research note `docs/research/<app>-research.md`
- **Merchant signals**: [interviews, community threads, support forums]
- **Platform signals**: [API capabilities or deprecations that make this possible now]

## Shopify Feasibility

| Question | Answer |
|----------|--------|
| Can the Admin API do it? | [Yes / with limits — name the query or mutation] |
| Scopes needed | [list] |
| Protected customer data? | [Yes/No — if yes, the review burden] |
| Webhooks needed | [topics] |
| Extension needed? | [None / admin action / checkout / POS] |
| Rate-limit exposure | [Bulk operations needed? Estimated cost per run] |
| Anything Shopify forbids? | [Policy check — e.g. no circumventing checkout] |

## Value Proposition

- **For** [merchant segment]
- **Who** [has this problem]
- **Our app** [does this]
- **Unlike** [alternative]
- **We** [the differentiator]

## Business Viability

| Field | Value |
|-------|-------|
| Pricing hypothesis | [$X/month per plan] |
| Comparable pricing | [What competitors charge] |
| Install-to-pay assumption | [% trial → paid] |
| Support burden | [Self-serve / email / white-glove] |
| Kill criteria | [What evidence would make us stop] |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Platform dependency | [H/M/L] | [H/M/L] | [API version pin + fallback] |
| Incumbent ships it | [H/M/L] | High | [Ship narrow and deep] |
| Scope creep | High | High | [MMMVP proposal freeze] |

## Recommendation

- [ ] **PROCEED to prototype** — hypothesis to test: [statement]
- [ ] **PROCEED to PRD** — no prototype needed because [reason]
- [ ] **HOLD** — missing evidence: [what]
- [ ] **KILL** — reason: [what]

## Open Questions

| # | Question | Owner | Needed by |
|---|----------|-------|-----------|
| 1 | [Question] | [Who] | [Date] |
