# Kanban Card

> **Board**: `production/apps/<app>/kanban.md` · **One card per unit of work**
> A card is a commitment, not a note. If it has no acceptance criteria and no
> owner, it is not ready to leave the backlog.

## Card

```markdown
### [APP-123] [Short imperative title]

- **App**: apps/<app>
- **Stage**: [research | concept | prototype | architecture | build | submission | live]
- **Gate**: [gate-1-research | gate-2-prototype | gate-3-scope | gate-4-release | gate-5-update | none]
- **Column**: [Backlog | Ready | In Progress | Review | Blocked | Done]
- **Owner**: [agent or role]
- **Priority**: [P0 — blocks a gate | P1 — this sprint | P2 — next sprint | P3 — someday]
- **Estimate**: [S ≤ half day | M ≤ 2 days | L ≤ 5 days | XL — split it]
- **Created**: [YYYY-MM-DD] · **Updated**: [YYYY-MM-DD]
```

### Context

[Two or three sentences: why this card exists and what problem it removes. Link
the request or PRD line it serves.]

- **Serves**: [FR-3 in `docs/prd/<app>.md` / request-history entry date]
- **Depends on**: [APP-100, or "none"]
- **Blocks**: [APP-140, or "none"]

### Acceptance Criteria

- [ ] [Testable statement — observable, not "improve X"]
- [ ] [Testable statement]
- [ ] Evidence recorded (test, screenshot, or log)

### Definition Of Done

- [ ] Acceptance criteria met and evidenced
- [ ] Tests written or the manual check recorded (`test-evidence.md` for UI work)
- [ ] Docs updated if behaviour changed (PRD / ADR / architecture)
- [ ] No new S1/S2 bug introduced
- [ ] Card moved to Done with the evidence link

### Links

| Type | Link |
|------|------|
| PRD | [`docs/prd/<app>.md` § ...] |
| ADR | [`docs/adr/adr-....md`] |
| Code | [path] |
| Evidence | [`production/apps/<app>/qa/evidence/...`] |

### Blockers

| Blocker | Since | Owner | Unblock condition |
|---------|-------|-------|-------------------|
| [What is blocking] | [date] | [who] | [what must happen] |

---

## Column Rules

| Column | Entry condition | Exit condition |
|--------|-----------------|----------------|
| Backlog | Written, not yet estimable | Has owner + AC |
| Ready | Owner, estimate, AC, no open blockers | Work starts |
| In Progress | **WIP limit: [2] per app** | Code/docs complete |
| Review | Evidence attached | Reviewer approves or requests changes |
| Blocked | A named blocker with an owner | Blocker resolved |
| Done | All DoD boxes checked | — (never reopened; new card instead) |

## Card Hygiene

- One outcome per card. "Refactor and add billing" is two cards.
- Titles are imperatives: "Retry failed syncs", not "Sync retries discussion".
- A card blocked for more than [5] days gets escalated at `/sprint-status`.
- A card in Review without evidence is not in Review.
- Done cards stay on the board for the sprint, then archive to
  `production/apps/<app>/kanban-archive.md`.
