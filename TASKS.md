# Agentic Shopify App Pipeline – Task List

## Goal

Automatic pipeline driven by **one single user request / requirement**.

From that one request the system can generate and manage **multiple Shopify apps** in parallel.

Multiple independent user requests are **not supported**. Everything flows from a single master request.

**Core Idea:**
One Request → Multiple Apps (each with its own full lifecycle)

**Per-app Flow (all apps born from the same original request):**

1. Master request / requirement is recorded
2. Research (Original idea **or** Competitor killer) against that single request
3. Ranked MMMVP proposals (can result in multiple distinct apps)
4. User selects which MMMVP(s) to turn into apps
5. For each selected app:
   - Build prototype
   - User reviews / refines
   - Production goals defined
   - Full SDLC (Epics + Stories) in concurrent Kanban
   - Create Shopify Test Store → User tests
   - User approves → Actual release
6. Ongoing loop (per app or across apps): re-research against the **original single request** → propose updates → update app(s) + test store(s) → user approves

---

## Acceptance Criteria

### Single Request → Multi-app
- [ ] System accepts only **one master request / requirement**
- [ ] That single request is the source of truth for all research and updates
- [ ] Research can produce multiple MMMVP proposals
- [ ] User can choose to turn one or more MMMVPs into separate apps
- [ ] Multiple apps can run in parallel, all traced back to the same original request
- [ ] Multiple separate user requests are not supported

### Multi-app Pipeline Support
- [ ] Each app has fully isolated state (idea refinement, prototype, epics/stories, test store, release)
- [ ] `/start` shows dashboard of all apps born from the master request + their stages
- [ ] All skills are app-scoped (`--app <name>` or context detection)
- [ ] `/kanban-status` supports single app or `--all`
- [ ] Approval gates are enforced per app
- [ ] Shared agents/skills never leak data between apps

### Core Flow
- [ ] Master request tracked
- [ ] Research supports Original Idea + Competitor Killer modes
- [ ] Ranked MMMVP proposals generated
- [ ] Prototype + user review per selected app
- [ ] Epics + Stories after production goals confirmed
- [ ] Concurrent Kanban development
- [ ] Test store creation & deployment per app
- [ ] Release blocked until explicit user approval
- [ ] Ongoing update loop always refers back to the original single request

---

## Phase 0 – Master Request & Multi-app Foundation

- [ ] Master request file (e.g. `request.md` or `requirement.md`)
- [ ] Folder structure: `apps/<app-name>/`
- [ ] Per-app: `idea.md`, `changes.md`, `status.md`
- [ ] Central registry of all apps generated from the master request
- [ ] Convention: every skill is app-scoped
- [ ] `/start` shows master request + all derived apps and stages

---

## Phase 1 – Research & MMMVP (from single request)

**Agents**
- [x] `product-director`
- [ ] `research-specialist`

**Skills**
- [x] `/start`
- [x] `/research` (Original + Competitor Killer) – always against master request
- [ ] `/idea-validate`
- [ ] `/mmmvp-proposals` → can recommend multiple apps

---

## Phase 2 – Prototype (per selected app)

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

## Phase 6 – Ongoing Update Loop

Always re-researches against the **original single master request**.

**Skills**
- [ ] `/update-research` (uses master request)
- [ ] `/propose-updates` (can affect one or multiple apps)
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
| `session-start.sh` | Show master request + all apps & stages | ☐ |
| `track-idea-changes.sh` | Log changes per app | ☐ |
| `validate-shopify-toml.sh` | Validate config per app | ☐ |
| `security-scan.sh` | Catch secrets / unsafe code | ☐ |
| `app-store-gate.sh` | Block release if checklist fails | ☐ |

---

## Human Approval Gates (Required – per app)

1. MMMVP selection (which proposals become apps)
2. Prototype → Production
3. Scope confirmation before full SDLC
4. Test Store → Live Release
5. Any future update proposal

---

*Last updated: 2026-10-28*