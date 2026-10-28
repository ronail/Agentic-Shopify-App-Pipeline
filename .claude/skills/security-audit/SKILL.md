---
name: security-audit
description: Full security review of the Shopify app before release.
---

# /security-audit

Run a focused security review.

## Checklist

### Authentication & Sessions
- [ ] Official Shopify auth libraries used
- [ ] Access tokens never logged or exposed
- [ ] Session storage is secure

### Webhooks
- [ ] HMAC verification on every webhook
- [ ] Idempotent handlers
- [ ] Proper error handling and retries

### API Scopes
- [ ] Only necessary scopes requested
- [ ] Scopes documented

### Secrets & Config
- [ ] No secrets in client code
- [ ] `.env` properly ignored
- [ ] Production secrets managed securely

### Data Handling
- [ ] Merchant data minimized
- [ ] Deletion / GDPR flows considered

## Output
Produce a clear risk rating (Low / Medium / High) and list of blockers.
