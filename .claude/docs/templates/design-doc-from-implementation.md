# [System Name] — Design Document

> **App**: `apps/<app>` · **Source**: reverse-documented from the implementation
> **Code**: [primary file paths]
> **Date**: [YYYY-MM-DD]

---

## 1. Overview

- **Purpose**: [What this system does for the merchant, one paragraph]
- **Owner**: [agent/role]
- **Trigger points**: [Where it runs — admin request, webhook, cron]
- **Externally visible behaviour**: [What the merchant or Shopify sees]

---

## 2. Detailed Design

### 2.1 Core Behaviour

[The mechanism, described so a new engineer could change it safely. Cover the
happy path and the boundaries between modules.]

### 2.2 Rules and Formulas

| Rule | Where implemented | Notes |
|------|-------------------|-------|
| [e.g. retry backoff = min(2^attempt × 30s, 6h)] | [file:function] | [Why this shape] |
| [e.g. GraphQL cost budget per shop = 1000 points] | [file] | [Matches API limits] |

### 2.3 State and Data

| Entity | Stored where | Key fields | Retention |
|--------|--------------|------------|-----------|
| [e.g. SyncRecord] | [DB table] | [shop, order_id, status, attempts] | [90 days] |

### 2.4 Integration Points

| Integration | Direction | Contract | Failure behaviour |
|-------------|-----------|----------|-------------------|
| Admin GraphQL API | outbound | [queries used] | Retry with backoff, surface banner |
| Webhook ingress | inbound | [topics] | Verify HMAC, enqueue, 200 fast |
| Billing API | outbound | [mutations] | Fail closed, log, alert |

---

## 3. Edge Cases

| Case | Current handling | Correct? | Ticket |
|------|------------------|----------|--------|
| [Order with no line items] | [Behaviour] | [Y/N] | [#] |
| [Webhook delivered twice] | [Idempotency key] | Y | |
| [Shop uninstalls mid-job] | [Job aborts on 401] | Y | |
| [Scope revoked after install] | [Banner + re-auth] | [?] | |

---

## 4. Dependencies

| Dependency | Type | Version / pin | Risk |
|------------|------|---------------|------|
| Admin API | external | [YYYY-MM] | Version deprecation |
| App Bridge | external | [version] | Breaking upgrade |
| Polaris | external | [version] | Component deprecation |
| [internal module] | internal | — | Shared with other apps via `src/` |

---

## 5. Limits and Tuning

| Parameter | Current value | Range considered | Effect of changing |
|-----------|---------------|------------------|--------------------|
| [Batch size] | [N] | [a-c] | Larger = fewer requests, more cost per request |
| [Retry attempts] | [N] | [a-c] | More attempts = later delivery, higher queue depth |
| [Cache TTL] | [Ns] | | Longer = staler admin reads |

[Note any value that is load-bearing: changing it alters merchant-visible behaviour.]

---

## 6. Acceptance Criteria

- [ ] Behaviour matches §2 for the happy path, verified by test [name]
- [ ] All §3 edge cases have a test or a documented manual check
- [ ] Failure of each §2.4 integration degrades gracefully (no 500 to the merchant)
- [ ] Limits in §5 documented in the technical design or ADR that set them

---

## 7. Open Questions and Follow-Up Work

### Questions Needing User Decision

| # | Question | Owner | Impact if unanswered |
|---|----------|-------|----------------------|
| 1 | [Question] | [Who] | [What stalls] |

### Flagged Follow-Up Work

- [ ] [Task] — [reason it was deferred] — [ticket]

---

## 8. Version History

| Version | Date | Change | Author |
|---------|------|--------|--------|
| 1.0 | [Date] | Initial reverse-documented design | [agent] |
