# Agentic Shopify App Pipeline – Task List

## Goal

Automatic multi-app pipeline that can run **multiple Shopify apps in the same repo at the same time**.

Each app has its own isolated idea tracking, research, prototype, SDLC, test store, and release cycle — while sharing the same agent/skill infrastructure.

**Per-app Flow:**

1. User submits idea for an app (tracked in `apps/<app-name>/idea.md` + `changes.md`)
2. Research → Original idea **or** Competitor killer
3. Generate ranked **MMMVP proposals**
4. Build prototype
5. User reviews / refines
6. Production goals defined
7. Full SDLC (Epics + Stories) in concurrent Kanban style
8. Create Shopify Test Store → User tests
9. User approves → Actual release
10. Ongoing loop (scheduled or manual): re-research → propose updates → update app + test store → user approves

Multiple apps can be at different stages simultaneously.

---

## Acceptance Criteria

The refactoring is complete only when all of these pass:

### Multi-app Support
- [ ] Repo can contain multiple independent apps under `apps/`
- [ ] Each app has its own `idea.md`, `changes.md`, epics, stories, and status
- [ ] Pipeline commands accept an `--app <name>` parameter (or detect context)
- [ ] Different apps can be at different stages at the same time
- [ ] Shared agents/skills work across all apps without conflict

### Core Flow (per app)
- [ ] Idea is tracked per app
- [ ] Research supports two modes: Original Idea and Competitor Killer
- [ ] System returns ranked MMMVP proposals
- [ ] User can select an MMMVP and trigger prototype
- [ ] Prototype can be reviewed and refined by user
- [ ] After production goals confirmed → Epics + Stories created
- [ ] Development runs concurrently (Kanban visible via `/kanban-status`)
- [ ] System can create and deploy to a Shopify Test Store per app
- [ ] Actual release is blocked until user explicitly approves
- [ ] Ongoing research + update loop works (manual + scheduled ready)
- [ ] All major transitions have enforced human approval gates

---

## Phase 0 – Multi-app Foundation & Idea Tracking

- [ ] Folder structure: `apps/<app-name>/`
- [ ] `apps/<app-name>/idea.md` template
- [ ] `apps/<app-name>/changes.md` template
- [ ] App registry (list of active apps + current stage)
- [ ] Hook: `track-idea-changes.sh` (scoped per app)

---

## Phase 1 – Research & MMMVP

**Agents**
- [x] `product-director`
- [ ] `research-specialist`

**Skills**
- [x] `/start` (supports selecting or creating an app)
- [x] `/research` (Original + Competitor Killer, scoped to app)
- [ ] `/idea-validate`
- [ ] `/mmmvp-proposals`

---

## Phase 2 – Prototype

**Agents**
- [ ] `prototype-builder`

**Skills**
- [x] `/scaffold` (creates new app folder)
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
- [ ] `/kanban-status` (can show one app or all apps)

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
| `session-start.sh` | Show all apps + current stages | ☐ |
| `track-idea-changes.sh` | Log changes per app | ☐ |
| `validate-shopify-toml.sh` | Validate config per app | ☐ |
| `security-scan.sh` | Catch secrets / unsafe code | ☐ |
| `app-store-gate.sh` | Block release if checklist fails | ☐ |

---

## Human Approval Gates (Required – per app)

1. MMMVP selection
2. Prototype → Production
3. Scope confirmation before full SDLC
4. Test Store → Live Release
5. Any future update proposal

---

*Last updated: 2026-10-28*