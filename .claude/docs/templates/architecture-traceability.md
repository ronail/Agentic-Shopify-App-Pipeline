# Architecture Traceability Index

## Document Status

- **Last Updated**: [YYYY-MM-DD]
- **App**: [`apps/<app>` | `all`]
- **PRD sources scanned**: [list `docs/prd/*.md` files]
- **ADR sources scanned**: [list `docs/adr/*.md` files]
- **Maintained by**: app-architect / architecture-review

## Coverage Summary

| Layer | Requirements | Covered by ADR | Coverage |
|-------|--------------|----------------|----------|
| Foundation | [N] | [N] | [N%] |
| Core | [N] | [N] | [N%] |
| Feature | [N] | [N] | [N%] |
| Presentation | [N] | [N] | [N%] |
| **Total** | [N] | [N] | [N%] |

## Traceability Matrix

| Requirement ID | PRD Section | Summary | ADR | Status |
|----------------|-------------|---------|-----|--------|
| [PRD-001] | [`docs/prd/sync.md` § Requirements] | [One-line requirement] | [ADR-0003] | [Covered / Partial / Gap] |

## Known Gaps

### Foundation Layer Gaps (BLOCKING — must resolve before coding)

- [Requirement with no ADR — why it blocks, who owns it, target date]

### Core Layer Gaps (must resolve before relevant system is built)

- [Requirement with no ADR]

### Feature Layer Gaps (should resolve before feature sprint)

- [Requirement with no ADR]

### Presentation Layer Gaps (can defer to implementation)

- [Requirement with no ADR]

## Cross-ADR Conflicts

| ADR A | ADR B | Conflict | Resolution |
|-------|-------|----------|------------|
| [ADR-0003] | [ADR-0007] | [What contradicts — e.g. two different webhook retry policies] | [Supersede one / narrow scope] |

## ADR → PRD Coverage (Reverse Index)

| ADR | Title | PRD Requirements Satisfied |
|-----|-------|---------------------------|
| [ADR-0003] | [Title] | [PRD-001, PRD-004] |

## Superseded Requirements

| Requirement | Superseded By | Date | Reason |
|-------------|---------------|------|--------|
| [PRD-002] | [PRD-011] | [Date] | [Scope change approved at gate-3] |

## How to Use This Document

1. Run `/architecture-review` after any PRD or ADR change — it regenerates this index.
2. Any requirement marked **Gap** at the Foundation layer blocks `/create-stories`.
3. Any conflict row blocks `/create-architecture` sign-off until resolved.
4. Gaps at the Presentation layer may be resolved inside the implementing story,
   provided the story records the decision it made.
