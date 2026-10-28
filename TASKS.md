# Agentic Shopify App Pipeline – Task List

**Goal**: Convert the Agent-Harness structure into a fully automated research → development → release → review pipeline for Shopify apps. Built for solo founders.

---

## Phase 1 – Foundation

| # | Task | Status |
|---|------|--------|
| 1.1 | Repo created: `Agentic-Shopify-App-Pipeline` | ✅ Done |
| 1.2 | Add this TASKS.md | ✅ Done |
| 1.3 | Create CLAUDE.md | ✅ Done |
| 1.4 | Update README.md with Shopify focus | ☐ |
| 1.5 | Create AGENTS.md overview | ☐ |

---

## Phase 2 – Agents (Generate)

### Directors
- [x] `product-director`
- [x] `technical-director`
- [x] `release-manager`

### Leads
- [ ] `app-architect`
- [ ] `ux-lead`
- [ ] `api-lead`
- [ ] `qa-lead`
- [ ] `growth-lead`

### Specialists
- [x] `security-specialist`
- [x] `app-store-reviewer`
- [ ] `liquid-specialist`
- [ ] `react-admin-specialist`
- [ ] `polaris-specialist`
- [ ] `app-bridge-specialist`
- [ ] `graphql-specialist`
- [ ] `webhooks-specialist`
- [ ] `billing-specialist`
- [ ] `auth-specialist`
- [ ] `performance-specialist`

---

## Phase 3 – Skills (Generate)

### Research & Discovery
- [x] `/start`
- [x] `/research`
- [ ] `/idea-validate`

### Development
- [x] `/scaffold`
- [ ] `/create-epics`
- [ ] `/create-stories`
- [ ] `/dev-story`
- [ ] `/webhook-design`
- [ ] `/billing-setup`
- [ ] `/polaris-ui`
- [ ] `/app-bridge-review`

### Review & Quality
- [x] `/security-audit`
- [ ] `/code-review`
- [ ] `/performance-check`
- [ ] `/app-store-checklist`

### Release
- [ ] `/release`
- [ ] `/hotfix`
- [ ] `/changelog`

---

## Phase 4 – Hooks (Generate)

| Hook | Trigger | Status |
|------|---------|--------|
| `session-start.sh` | Session open | ☐ |
| `validate-shopify-toml.sh` | Pre-commit | ☐ |
| `validate-scopes.sh` | Pre-push | ☐ |
| `security-scan.sh` | Post-edit | ☐ |
| `app-store-gate.sh` | Pre-release | ☐ |

---

## Phase 5 – Templates

- [ ] App PRD template
- [ ] Webhook design doc
- [ ] Billing plan matrix
- [ ] App Store listing template
- [ ] Security review checklist
- [ ] Release notes template

---

## Phase 6 – Pipeline Flow

```
Research → Validate Idea → Scaffold → Epics/Stories → Dev → Code Review → Security → App Store Checklist → Release → Monitor
```

---

## Next Immediate Actions

1. Finish remaining high-value agents (app-architect, api-lead, billing-specialist, webhooks-specialist)
2. Finish core skills (`/app-store-checklist`, `/create-epics`, `/dev-story`, `/release`)
3. Create basic hooks
4. Update README

---

*Last updated: 2026-10-28*