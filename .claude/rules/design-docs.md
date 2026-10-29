---
paths:
  - "design/**"
---

# Design Doc Rules (ADRs, UX Specs, Requirements)

- Every app subsystem has an ADR under `docs/architecture/apps/<app>/`; the decision, alternatives, and consequences are all stated
- Requirement docs live under `design/` or `apps/<app>/` and are registered in that app's `requirements.yaml` with `REQ-<AREA>-<NNN>` IDs
- Each requirement set carries all 8 sections: Overview, Merchant Job, Detailed Rules, Calculations, Edge Cases, Dependencies, Configuration, Acceptance Criteria
- Calculations are written as formulas with variable definitions and at least one worked example
- Edge cases explicitly cover empty stores, huge catalogs, multi-currency, and partial failures
- UX specs list the Polaris surfaces touched, every state (loading/empty/error), and the accessibility notes
- Every value with a default states its rationale or source
- Superseding a decision adds a new ADR that links back; the old one is marked superseded, never silently rewritten
