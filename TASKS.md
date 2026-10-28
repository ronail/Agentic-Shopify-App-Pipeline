# Agentic Shopify App Pipeline – Task List

## Goal

Automatic **multi-app pipeline** that can run the full lifecycle of **multiple Shopify apps at the same time** — not just multiple codebases, but parallel research, prototyping, development, testing, release, and update cycles.

Each app is a first-class citizen in the pipeline with its own:
- Idea & decision tracking
- Research & MMMVP history
- Prototype
- Epics / Stories / Kanban
- Test store
- Release state
- Ongoing update loop

All apps share the same agents, skills, and hooks. The pipeline itself is multi-tenant.

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

Multiple apps can be at completely different stages at the same time.

---

## Acceptance Criteria

### Multi-app Pipeline Support (Must Pass)
- [ ] Pipeline can manage multiple apps simultaneously across all stages
- [ ] Every app has fully isolated state: idea, research, MMMVPs, prototype, epics/stories, test store, release status
- [ ] `/start` shows a dashboard of **all apps** and their current pipeline stage
- [ ] All skills accept `--app <name>` (or auto-detect context)
- [ ] `/kanban-status` supports single app or `--all`
- [ ] Research, prototype, SDLC, test store, and release can run for different apps in parallel without interference
- [ ] Approval gates are enforced **per app**
- [ ] Shared agents/skills never leak data or decisions between apps

### Core Flow (per app)
- [ ] Idea tracking works
- [ ] Research supports Original Idea + Competitor Killer
- [ ] Ranked MMMVP proposals generated
- [ ] Prototype build + user review
- [ ] Epics + Stories created after production goals confirmed
- [ ] Concurrent Kanban development
- [ ] Test store creation & deployment
- [ ] Release blocked until explicit user approval
- [ ] Ongoing update loop works

---

## Phase 0 – Multi-app Pipeline Foundation

- [ ] Folder structure: `apps/<app-name>/` (code + all pipeline artifacts)
- [ ] Per-app files: `idea.md`, `changes.md`, `status.md` (or equivalent)
- [ ] Central app registry / dashboard (used by `/start` and `/kanban-status`)
- [ ] Convention: every skill is app-scoped (`--app <name>` or context detection)
- [ ] Hook: `track-idea-changes.sh` (per app)
- [ ] Session start shows multi-app pipeline overview

---

## Phase 1 – Research & MMMVP (per app)

**Agents**
- [x] `product-director`
- [ ] `research-specialist`

**Skills**
- [x] `/start` → multi-app dashboard + create/select app
- [x] `/research --app <name>` (Original + Competitor Killer)
- [ ] `/idea-validate --app <name>`
- [ ] `/mmmvp-proposals --app <name>`

---

## Phase 2 – Prototype (per app)

**Agents**
- [ ] `prototype-builder`

**Skills**
- [x] `/scaffold --app <name>`
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
| `session-start.sh` | Multi-app pipeline dashboard | ☐ |
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