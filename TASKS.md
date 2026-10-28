# Agentic Shopify App Pipeline – Vision & Task List

## Goal

Build a fully automatic Shopify app pipeline that:

1. Takes a user initial request / idea (tracked in markdown)
2. Performs research on either:
   - Original idea validation, **or**
   - Competitor killer analysis
3. Returns a ranked list of **MMMVP proposals**
4. Builds a prototype
5. Asks user to review or refine for production development
6. Once production goals are defined → runs full SDLC (Epics → Stories) in a **Kanban concurrent** style until ready to release
7. Sets up a Shopify **Test Store** for user testing
8. Waits for explicit user approval before actual release
9. Supports ongoing loop (scheduled or manual):
   - Re-research using the original request
   - Determine update requirements
   - Update the app + test store
   - Wait for user approval again

All major stage transitions require **human approval gates**.

---

## Acceptance Criteria (Refactoring Goal)

The pipeline is considered complete when **all** of the following are true:

### Core Flow
- [ ] User can start with a raw idea in `idea.md`
- [ ] System can run research in two modes: Original Idea **or** Competitor Killer
- [ ] System returns a clear ranked list of MMMVP proposals
- [ ] User can select one MMMVP and trigger prototype build
- [ ] Prototype can be reviewed and refined by user
- [ ] After user confirms production goals, system creates Epics + Stories
- [ ] Development can run concurrently in Kanban style (`/kanban-status` works)
- [ ] When ready, system can create and deploy to a Shopify Test Store
- [ ] Actual production release is blocked until user explicitly approves
- [ ] Ongoing research + update proposals can be triggered (manual or scheduled)
- [ ] All updates also go through test store + user approval before live release

### Structure & Quality
- [ ] Agents, skills, and hooks exist for every major stage above
- [ ] `idea.md` and `changes.md` are the single source of truth for decisions
- [ ] Human approval gates are enforced at every critical transition
- [ ] README clearly explains the full pipeline for a solo founder

### Non-Goals (Out of Scope for v1)
- Fully autonomous release without any human approval
- Multi-app portfolio management
- Advanced analytics / revenue tracking

---

## Pipeline Flow

```
1. User Idea (tracked in idea.md / changes.md)
          ↓
2. Research
   - Path A: Original idea validation
   - Path B: Competitor killer analysis
          ↓
3. Ranked list of MMMVP proposals
          ↓
4. Build Prototype
          ↓
5. User Review / Refinement
          ↓
6. Production Goals Defined
          ↓
7. Full SDLC (Epics → Stories → Kanban concurrent)
          ↓
8. Ready → Create Shopify Test Store
          ↓
9. User Testing & Approval
          ↓
10. Actual Release
          ↓
11. Ongoing Loop (Scheduled or Manual)
    - Re-research with same original request
    - Determine update requirements
    - Update App + Test Store
    - Wait for user approval
```

---

## Phase 0 – Idea Tracking

- [ ] Create `idea.md` template (master idea + decisions)
- [ ] Create `changes.md` template (refinement history)
- [ ] Hook: `track-idea-changes.sh`

---

## Phase 1 – Research & MMMVP

**Agents**
- [ ] `research-specialist`
- [x] `product-director`

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

## Phase 3 – Production Planning & SDLC

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

## Phase 4 – Quality & Security

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

## Phase 7 – Supporting Agents & Skills (Nice-to-have)

- [ ] `ux-lead`, `growth-lead`
- [ ] Liquid / Polaris / App Bridge / GraphQL / Webhooks / Billing / Auth / Performance specialists
- [ ] `/webhook-design`, `/billing-setup`, `/polaris-ui`, etc.

---

## Hooks

| Hook | Trigger | Status |
|------|---------|--------|
| `session-start.sh` | Session open | ☐ |
| `track-idea-changes.sh` | On idea.md edit | ☐ |
| `validate-shopify-toml.sh` | Pre-commit | ☐ |
| `validate-scopes.sh` | Pre-push | ☐ |
| `security-scan.sh` | Post-edit | ☐ |
| `app-store-gate.sh` | Pre-release | ☐ |

---

## Templates

- [ ] `idea.md`
- [ ] `changes.md`
- [ ] MMMVP proposal template
- [ ] App PRD template
- [ ] Test store setup checklist
- [ ] Security review checklist
- [ ] Release notes template

---

## Human Approval Gates (Must Enforce)

1. After MMMVP proposals → User selects which to prototype
2. After Prototype → User approves or requests refinement
3. After Production goals defined → User confirms scope
4. After Test Store ready → User tests & approves release
5. After any Update proposal → User approves before applying

---

*Last updated: 2026-10-28*