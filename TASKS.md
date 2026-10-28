# Agentic Shopify App Pipeline – Task List

## Goal

Automatic pipeline driven by **one single master request / requirement**.

From that one request the system can generate and manage **multiple Shopify apps** in parallel.

The master request **can be updated** at any time. Every update must be fully tracked.

Multiple independent user requests are **not supported**. Everything flows from the single (versioned) master request.

**Core Idea:**
One Master Request (updatable + fully tracked) → Multiple Apps

**Per-app Flow:**

1. Master request is recorded (and can be updated later)
2. Research (Original idea **or** Competitor killer) against current master request
3. Ranked MMMVP proposals (can result in multiple distinct apps)
4. User selects which MMMVP(s) to turn into apps
5. For each selected app:
   - Build prototype
   - User reviews / refines
   - Production goals defined
   - Full SDLC (Epics + Stories) in concurrent Kanban
   - Create Shopify Test Store → User tests
   - User approves → Actual release
6. Ongoing loop: re-research against the **current master request** → propose updates → update app(s) + test store(s) → user approves

---

## Acceptance Criteria

### Master Request
- [ ] System has exactly one master request
- [ ] Master request can be updated at any time
- [ ] Every update to the master request is tracked (who/what/when + reason)
- [ ] Full history of master request changes is available
- [ ] All research and update loops always use the **current** version of the master request
- [ ] Multiple independent requests are not supported

### Single Request → Multi-app
- [ ] One master request can generate multiple MMMVP proposals
- [ ] User can turn one or more MMMVPs into separate apps
- [ ] Multiple apps can run in parallel, all traced back to the same master request

### Multi-app Pipeline Support
- [ ] Each app has fully isolated state (prototype, epics/stories, test store, release)
- [ ] `/start` shows master request (current version) + all derived apps and stages
- [ ] All skills are app-scoped (`--app <name>` or context detection)
- [ ] `/kanban-status` supports single app or `--all`
- [ ] Approval gates are enforced per app
- [ ] Shared agents/skills never leak data between apps

### Core Flow
- [ ] Research supports Original Idea + Competitor Killer modes
- [ ] Ranked MMMVP proposals generated
- [ ] Prototype + user review per selected app
- [ ] Epics + Stories after production goals confirmed
- [ ] Concurrent Kanban development
- [ ] Test store creation & deployment per app
- [ ] Release blocked until explicit user approval
- [ ] Ongoing update loop always refers to current master request

---

## Phase 0 – Master Request & Multi-app Foundation

- [ ] `request.md` (current master request)
- [ ] `request-history.md` or equivalent (full tracked changelog of every update)
- [ ] Folder structure: `apps/<app-name>/`
- [ ] Per-app: `idea.md`, `changes.md`, `status.md`
- [ ] Central registry of all apps generated from the master request
- [ ] Skill or command to update master request (with mandatory reason)
- [ ] `/start` shows current master request + change history summary + all apps

---

## Phase 1 – Research & MMMVP (from current master request)

**Agents**
- [x] `product-director`
- [ ] `research-specialist`

**Skills**
- [x] `/start`
- [x] `/research` (Original + Competitor Killer) – always against current master request
- [ ] `/idea-validate`
- [ ] `/mmmvp-proposals` → can recommend multiple apps
- [ ] `/update-request` (update master request + force tracking entry)

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

Always re-researches against the **current master request**.

**Skills**
- [ ] `/update-research`
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
| `session-start.sh` | Show current master request + history summary + all apps | ☐ |
| `track-request-changes.sh` | Force tracking on every master request update | ☐ |
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
6. Any update to the master request (optional confirmation)

---

*Last updated: 2026-10-28*