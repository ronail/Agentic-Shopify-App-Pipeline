# Agentic Shopify App Pipeline – Task List

## Goal

Automatic pipeline driven by **one single master request** (updatable + fully tracked).

From that one request the system can generate and run **multiple Shopify apps** in parallel through the full lifecycle.

**Flow:**

1. Master request recorded (can be updated later, all changes tracked)
2. Research (Original idea **or** Competitor killer) against current master request
3. Ranked MMMVP proposals → User selects which become apps
4. For each selected app:
   - Build prototype → User reviews / refines
   - Production goals defined
   - Full SDLC (Epics + Stories) in concurrent Kanban
   - Create Shopify Test Store → User tests
   - User approves → Actual release
5. Ongoing loop: re-research against current master request → propose updates → update app(s) + test store(s) → user approves

---

## Acceptance Criteria

### Master Request
- [ ] Exactly one master request
- [ ] Can be updated at any time
- [ ] Every update is tracked with history
- [ ] All research/update loops use the current version

### Multi-app from One Request
- [ ] One master request can produce multiple apps
- [ ] Apps run in parallel with isolated state
- [ ] `/start` shows master request + all apps and their stages

### Pipeline
- [ ] Research supports Original + Competitor Killer
- [ ] Ranked MMMVP proposals
- [ ] Prototype + user review
- [ ] Epics + Stories + concurrent Kanban
- [ ] Test store per app
- [ ] Release only after explicit user approval
- [ ] Ongoing update loop works
- [ ] Human approval gates enforced per app

---

## Workflow Guideline

```
Master Request (request.md + history)
        ↓
Research (Original | Competitor Killer)
        ↓
MMMVP Proposals → User selects apps
        ↓
┌─────────────────────────────┐
│  For each selected app:     │
│  Prototype → Review         │
│  → Production Goals         │
│  → Epics + Stories (Kanban) │
│  → Test Store               │
│  → User Approval → Release  │
└─────────────────────────────┘
        ↓
Ongoing: Update master request or re-research → Propose updates → Apply (with approval)
```

---

## Phase 0 – Master Request & Foundation

- [ ] `request.md` (current master request)
- [ ] `request-history.md` (full tracked changelog)
- [ ] `apps/<app-name>/` structure
- [ ] Per-app: `status.md`
- [ ] App registry / dashboard data
- [ ] `/update-request` skill (mandatory reason + auto-track)

---

## Phase 1 – Research & MMMVP

**Agents**
- [x] `product-director`
- [ ] `research-specialist`

**Skills**
- [x] `/start` (dashboard: master request + all apps)
- [x] `/research`
- [ ] `/mmmvp-proposals`
- [ ] `/update-request`

---

## Phase 2 – Prototype

**Agents**
- [ ] `prototype-builder`

**Skills**
- [x] `/scaffold --app <name>`
- [ ] `/build-prototype --app <name>`
- [ ] `/prototype-review --app <name>`

---

## Phase 3 – SDLC (Concurrent Kanban)

**Agents**
- [x] `technical-director`
- [ ] `app-architect`

**Skills**
- [ ] `/create-epics --app <name>`
- [ ] `/create-stories --app <name>`
- [ ] `/dev-story --app <name>`
- [ ] `/kanban-status` (one app or `--all`)

---

## Phase 4 – Quality & Release

**Agents**
- [x] `security-specialist`
- [x] `app-store-reviewer`
- [x] `release-manager`
- [ ] `test-store-manager`

**Skills**
- [x] `/security-audit --app <name>`
- [ ] `/app-store-checklist --app <name>`
- [ ] `/create-test-store --app <name>`
- [ ] `/deploy-to-test-store --app <name>`
- [ ] `/release --app <name>`

---

## Phase 5 – Ongoing Update Loop

**Skills**
- [ ] `/update-research` (against current master request)
- [ ] `/propose-updates`
- [ ] `/apply-updates --app <name>`

---

## Hooks (Minimal)

| Hook | Purpose | Status |
|------|---------|--------|
| `session-start.sh` | Show master request + all apps & stages | ☐ |
| `track-request-changes.sh` | Enforce tracking on master request updates | ☐ |
| `app-store-gate.sh` | Block release if checklist fails | ☐ |

---

## Human Approval Gates (per app)

1. MMMVP selection (which become apps)
2. Prototype → Production
3. Scope confirmation before full SDLC
4. Test Store → Live Release
5. Any update proposal

---

## Removed / Deferred (Not needed for core pipeline)

- Low-level specialists (Liquid, Polaris, App Bridge, GraphQL, Webhooks, Billing, Auth, Performance)
- Extra skills (`/webhook-design`, `/billing-setup`, `/polaris-ui`, `/code-review`, `/hotfix`, etc.)
- Growth / UX leads
- Most validation hooks

These can be added later if needed.

---

*Last updated: 2026-10-28*