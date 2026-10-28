# Agentic Shopify App Pipeline – Task List

## Goal

Automatic pipeline that turns a user idea into a live Shopify app with human approval at every critical stage.

**Flow:**

1. User submits idea (tracked in `idea.md` + `changes.md`)
2. Research → Original idea **or** Competitor killer
3. Generate ranked **MMMVP proposals**
4. Build prototype
5. User reviews / refines
6. Production goals defined
7. Full SDLC (Epics + Stories) in concurrent Kanban style
8. Create Shopify Test Store → User tests
9. User approves → Actual release
10. Ongoing loop (scheduled or manual): re-research → propose updates → update app + test store → user approves

---

## Acceptance Criteria

The refactoring is complete only when all of these pass:

- [ ] Idea is tracked in `idea.md` / `changes.md`
- [ ] Research supports two modes: Original Idea and Competitor Killer
- [ ] System returns ranked MMMVP proposals
- [ ] User can select an MMMVP and trigger prototype
- [ ] Prototype can be reviewed and refined by user
- [ ] After production goals confirmed → Epics + Stories created
- [ ] Development runs concurrently (Kanban visible via `/kanban-status`)
- [ ] System can create and deploy to a Shopify Test Store
- [ ] Actual release is blocked until user explicitly approves
- [ ] Ongoing research + update loop works (manual + scheduled ready)
- [ ] All major transitions have enforced human approval gates

---

## Phase 0 – Idea Tracking

- [ ] `idea.md` template (master idea + key decisions)
- [ ] `changes.md` template (refinement history)
- [ ] Hook: `track-idea-changes.sh`

---

## Phase 1 – Research & MMMVP

**Agents**
- [x] `product-director`
- [ ] `research-specialist`

**Skills**
- [x] `/start`
- [x] `/research` (Original + Competitor Killer)
- [ ] `/idea-validate`
- [ ] `/mmmvp-proposals`

---

## Phase 2 – Prototype

**Agents**
- [ ] `prototype-builder`

**Skills**
- [x] `/scaffold`
- [ ] `/build-prototype`
- [ ] `/prototype-review`

---

## Phase 3 – Production Planning & Concurrent SDLC

**Agents**
- [x] `technical-director`
- [ ] `app-architect`
- [ ] `api-lead`
- [ ] `qa-lead`

**Skills**
- [ ] `/create-epics`
- [ ] `/create-stories`
- [ ] `/dev-story`
- [ ] `/kanban-status`

---

## Phase 4 – Quality Gates

**Agents**
- [x] `security-specialist`
- [x] `app-store-reviewer`

**Skills**
- [x] `/security-audit`
- [ ] `/code-review`
- [ ] `/app-store-checklist`

---

## Phase 5 – Test Store & Release

**Agents**
- [x] `release-manager`
- [ ] `test-store-manager`

**Skills**
- [ ] `/create-test-store`
- [ ] `/deploy-to-test-store`
- [ ] `/release`
- [ ] `/hotfix`
- [ ] `/changelog`

---

## Phase 6 – Ongoing Update Loop

**Skills**
- [ ] `/update-research`
- [ ] `/propose-updates`
- [ ] `/apply-updates`

---

## Supporting (Later)

- Remaining specialists (Liquid, Polaris, App Bridge, GraphQL, Webhooks, Billing, Auth, Performance)
- Extra skills (`/webhook-design`, `/billing-setup`, `/polaris-ui`, etc.)
- Growth & UX leads

---

## Hooks

| Hook | Purpose | Status |
|------|---------|--------|
| `session-start.sh` | Show current stage | ☐ |
| `track-idea-changes.sh` | Log changes to idea | ☐ |
| `validate-shopify-toml.sh` | Validate config | ☐ |
| `security-scan.sh` | Catch secrets / unsafe code | ☐ |
| `app-store-gate.sh` | Block release if checklist fails | ☐ |

---

## Human Approval Gates (Required)

1. MMMVP selection
2. Prototype → Production
3. Scope confirmation before full SDLC
4. Test Store → Live Release
5. Any future update proposal

---

*Last updated: 2026-10-28*