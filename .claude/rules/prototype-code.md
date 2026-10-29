---
paths:
  - "apps/**/prototype/**"
---

# Prototype Code Rules

- Prototypes live only under `apps/<app>/prototype/` and are throwaway — they are never imported by shipped routes or handlers
- Each prototype ships a short README stating the question it answers, the hypotheses tested, and the verdict
- Relaxed standards apply: no doc comments, coverage, or test evidence required — but no secrets, no live merchant data, and no unreviewed write paths
- Use a dev store and test data only; never point a prototype at production credentials
- TypeScript stays on; no `any` leaking into the app's shared `types/`
- When the verdict is "keep it", rewrite the logic into `apps/<app>/` with tests before wiring it in; delete the prototype
- Delete prototypes that stopped answering a live question — the folder is not an archive
