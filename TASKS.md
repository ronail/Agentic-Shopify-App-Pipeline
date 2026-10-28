# Agentic Shopify App Pipeline – Task List

## Goal

Automatic **multi-app** pipeline that can develop, test, and release **multiple Shopify apps in the same repo at the same time**.

Each app is fully isolated (idea, research, prototype, epics/stories, test store, release) while sharing the same agents, skills, and hooks.

**Per-app Flow:**

1. User submits idea → tracked in `apps/<app-name>/idea.md` + `changes.md`
2. Research (Original idea **or** Competitor killer)
3. Ranked MMMVP proposals
4. Build prototype
5. User reviews / refines
6. Production goals defined
7. Full SDLC (Epics + Stories) in concurrent Kanban
8. Create Shopify Test Store → User tests
9. User approves → Actual release
10. Ongoing loop: re-research → propose updates → update app + test store → user approves

Multiple apps can be at different stages simultaneously.

---

## Acceptance Criteria

### Multi-app Support (Must Pass)
- [ ] All apps live under `apps/<app-name>/`
- [ ] Each app has its own `idea.md`, `changes.md`, epics, stories, status, and test store config
- [ ] Every skill accepts `--app <name>` (or auto-detects from context)
- [ ] `/start` can list all apps + their current stage
- [ ] `/kanban-status` can show one app or all apps
- [ ] Different apps can run research, development, and release cycles independently
- [ ] Shared agents/skills never mix data between apps

### Core Flow (per app)
- [ ] Idea tracking works per app
- [ ] Research supports Original Idea + Competitor Killer modes
- [ ] Ranked MMMVP proposals generated
- [ ] Prototype build + user review
- [ ] Epics + Stories created after production goals confirmed
- [ ] Concurrent Kanban development
- [ ] Test store creation & deployment per app
- [ ] Release blocked until explicit user approval
- [ ] Ongoing update loop works
- [ ] Human approval gates enforced at every critical transition

---

## Phase 0 – Multi-app Foundation

- [ ] Standard folder structure: `apps/<app-name>/`
- [ ] `apps/<app-name>/idea.md` template
- [ ] `apps/<app-name>/changes.md` template
- [ ] App registry file (e.g. `apps/registry.md` or `apps/status.json`) showing all apps + stage
- [ ] Convention: all skills require `--app <name>` or detect current app context
- [ ] Hook: `track-idea-changes.sh` (scoped per app)

---

## Phase 1 – Research & MMMVP (per app)

**Agents**
- [x] `product-director`
- [ ] `research-specialist`

**Skills**
- [x] `/start` → list apps / create new app / select app
- [x] `/research --app <name>` (Original + Competitor Killer)
- [ ] `/idea-validate --app <name>`
- [ ] `/mmmvp-proposals --app <name>`

---

## Phase 2 – Prototype (per app)

**Agents**
- [ ] `prototype-builder`

**Skills**
- [x] `/scaffold --app <name>` (creates `apps/<name>/`)
- [ ] `/build-prototype --app <name>`
- [ ] `/prototype-review --app <name>`

---

## Phase 3 – Production Planning & Concurrent SDLC (per app)

**Agents**
- [x] `technical-director`
- [ ] `app-architect`
- [ ] `api-lead`
- [ ] `qa-lead`

**Skills**
- [ ] `/create-epics --app <name>`
- [ ] `/create-stories --app <name>`
- [ ] `/dev-story --app <name>`
- [ ] `/kanban-status` (one app or `--all`)

---

## Phase 4 – Quality Gates (per app)

**Agents**
- [x] `security-specialist`
- [x] `app-store-reviewer`

**Skills**
- [x] `/security-audit --app <name>`
- [ ] `/code-review --app <name>`
- [ ] `/app-store-checklist --app <name>`

---

## Phase 5 – Test Store & Release (per app)

**Agents**
- [x] `release-manager`
- [ ] `test-store-manager`

**Skills**
- [ ] `/create-test-store --app <name>`
- [ ] `/deploy-to-test-store --app <name>`
- [ ] `/release --app <name>`
- [ ] `/hotfix --app <name>`
- [ ] `/changelog --app <name>`

---

## Phase 6 – Ongoing Update Loop (per app)

**Skills**
- [ ] `/update-research --app <name>`
- [ ] `/propose-updates --app <name>`
- [ ] `/apply-updates --app <name>`

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