# Agentic Shopify App Pipeline – Task List

**Goal**: Convert the Agent-Harness structure into a fully automated research → development → release → review pipeline for Shopify apps. Built for solo founders.

---

## Phase 1 – Foundation

| # | Task | Status |
|---|------|--------|
| 1.1 | Repo created: `Agentic-Shopify-App-Pipeline` | ✅ Done |
| 1.2 | Add this TASKS.md | ✅ Done |
| 1.3 | Copy core structure from Agent-Harness-Game-Studios (`.claude/`, agents, skills skeleton) | ☐ |
| 1.4 | Update README.md with Shopify focus | ☐ |
| 1.5 | Create CLAUDE.md / AGENTS.md for Shopify context | ☐ |

---

## Phase 2 – Agent Hierarchy

### Directors (Opus-level)
- [ ] Product Director
- [ ] Technical Director
- [ ] Release Manager

### Leads (Sonnet-level)
- [ ] App Architect
- [ ] UX Lead
- [ ] API Lead
- [ ] QA Lead
- [ ] Growth Lead

### Specialists
- [ ] Liquid Specialist
- [ ] React Admin Specialist
- [ ] Polaris UI Specialist
- [ ] App Bridge Specialist
- [ ] GraphQL Specialist
- [ ] Webhooks Specialist
- [ ] Billing Specialist
- [ ] Auth & Sessions Specialist
- [ ] Performance Specialist
- [ ] Security Specialist
- [ ] App Store Review Specialist

---

## Phase 3 – Core Skills / Slash Commands

### Research & Discovery
- [ ] `/start` – Bootstrap + stage detection
- [ ] `/research` – Competitor + App Store research
- [ ] `/idea-validate` – Quick idea scoring

### Development
- [ ] `/scaffold` – Remix / Node / React Router app template
- [ ] `/create-epics`
- [ ] `/create-stories`
- [ ] `/dev-story`
- [ ] `/webhook-design`
- [ ] `/billing-setup`
- [ ] `/polaris-ui`
- [ ] `/app-bridge-review`

### Review & Quality
- [ ] `/code-review`
- [ ] `/security-audit`
- [ ] `/performance-check`
- [ ] `/app-store-checklist`

### Release
- [ ] `/release`
- [ ] `/hotfix`
- [ ] `/changelog`

---

## Phase 4 – Automation Hooks

| Hook | Trigger | Purpose |
|------|---------|---------|
| validate-shopify-toml | Pre-commit | Validate `shopify.app.toml` |
| validate-scopes | Pre-push | Check API scopes |
| security-scan | Post-edit | Detect secrets / unsafe patterns |
| app-store-gate | Pre-release | Run full checklist |
| session-start | Session open | Show current app stage |

---

## Phase 5 – Templates

- [ ] App PRD template
- [ ] Webhook design doc
- [ ] Billing plan matrix
- [ ] App Store listing template
- [ ] Security review checklist
- [ ] Release notes template
- [ ] Privacy policy / data handling notes

---

## Phase 6 – End-to-End Pipeline

```
Research → Validate Idea → Scaffold → Epics/Stories → Dev → Code Review → Security → App Store Checklist → Release → Monitor
```

---

## Next Immediate Actions

1. Copy and adapt core agent/skill structure
2. Write first 5 high-value agents (Product Director, App Architect, Security, App Store Review, Release Manager)
3. Implement `/start` and `/scaffold` skills

---

*Last updated: 2026-10-28*