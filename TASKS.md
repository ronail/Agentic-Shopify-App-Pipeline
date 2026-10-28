# Agentic Shopify App Pipeline – Vision & Task List

**Goal**: Fully automatic pipeline that takes a user idea, researches, proposes MMMVPs, builds prototype → production, manages full SDLC, deploys to test store, and supports ongoing updates — all with human approval gates.

---

## Pipeline Flow

```
1. User Idea (tracked in idea.md / changes.md)
          ↓
2. Research
   - Path A: Original idea validation
   - Path B: Competitor killer analysis
          ↓
3. Return list of MMMVP proposals
          ↓
4. Build Prototype
          ↓
5. User Review / Refinement
          ↓
6. Production Goals Defined
          ↓
7. Full SDLC (Epics → Stories → Kanban, concurrent)
          ↓
8. Ready for Release → Create Shopify Test Store
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

## Phase 1 – Foundation

| # | Task | Status |
|---|------|--------|
| 1.1 | Repo created | ✅ Done |
| 1.2 | This TASKS.md (vision + tasks) | ✅ Done |
| 1.3 | CLAUDE.md created | ✅ Done |
| 1.4 | Update README.md | ☐ |
| 1.5 | Create AGENTS.md overview | ☐ |
| 1.6 | Create idea.md + changes.md tracking templates | ☐ |

---

## Phase 2 – Agents

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
- [ ] `research-specialist` (new – owns MMMVP generation)
- [ ] `prototype-builder` (new)
- [ ] `test-store-manager` (new)

---

## Phase 3 – Skills

### Research & Discovery
- [x] `/start`
- [x] `/research` (supports Original + Competitor Killer paths)
- [ ] `/idea-validate`
- [ ] `/mmmvp-proposals` ← generate ranked MMMVP list

### Prototype
- [x] `/scaffold`
- [ ] `/build-prototype`
- [ ] `/prototype-review`

### Planning & Development
- [ ] `/create-epics`
- [ ] `/create-stories`
- [ ] `/dev-story`
- [ ] `/kanban-status`
- [ ] `/webhook-design`
- [ ] `/billing-setup`
- [ ] `/polaris-ui`
- [ ] `/app-bridge-review`

### Review & Quality
- [x] `/security-audit`
- [ ] `/code-review`
- [ ] `/performance-check`
- [ ] `/app-store-checklist`

### Release & Test Store
- [ ] `/create-test-store`
- [ ] `/deploy-to-test-store`
- [ ] `/release`
- [ ] `/hotfix`
- [ ] `/changelog`

### Ongoing Update Loop
- [ ] `/update-research` (re-run research on original idea)
- [ ] `/propose-updates`
- [ ] `/apply-updates`

---

## Phase 4 – Hooks

| Hook | Trigger | Status |
|------|---------|--------|
| `session-start.sh` | Session open | ☐ |
| `validate-shopify-toml.sh` | Pre-commit | ☐ |
| `validate-scopes.sh` | Pre-push | ☐ |
| `security-scan.sh` | Post-edit | ☐ |
| `app-store-gate.sh` | Pre-release | ☐ |
| `track-idea-changes.sh` | On idea.md edit | ☐ |

---

## Phase 5 – Templates & Tracking

- [ ] `idea.md` – Master idea + decisions log
- [ ] `changes.md` – Tracked changes / refinement history
- [ ] App PRD template
- [ ] MMMVP proposal template
- [ ] Webhook design doc
- [ ] Billing plan matrix
- [ ] App Store listing template
- [ ] Security review checklist
- [ ] Release notes template
- [ ] Test store setup checklist

---

## Phase 6 – Human Approval Gates (Non-negotiable)

1. After MMMVP proposals → User chooses which to prototype
2. After Prototype → User approves / requests refinement
3. After Production goals defined → User confirms scope
4. After Test Store ready → User tests & approves release
5. After any Update proposal → User approves before applying

---

## Next Immediate Actions (when ready)

1. Create `idea.md` + `changes.md` templates
2. Finish critical new agents: `research-specialist`, `prototype-builder`, `test-store-manager`
3. Build `/mmmvp-proposals`, `/build-prototype`, `/create-test-store` skills
4. Update README with full vision

---

*Last updated: 2026-10-28*