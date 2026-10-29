# detect-gaps.sh — pipeline gap report

| Field | Value |
| --- | --- |
| Event | SessionStart |
| Matcher | — |
| Reads | `docs/registry/apps.json`, `apps/<slug>/status.md`, `apps/<slug>/approvals.json`, `request.md`, `request-history.md` |
| Writes | none (advisory) |
| Blocks | no — always exits 0 |

## What it does

- Registry ⟷ disk drift: an app listed with no `apps/<slug>/` directory, or a directory with no registry entry.
- `request.md` ⟷ `apps/<slug>/status.md` stage drift.
- Stalled apps: `status.md` untouched for `GAP_STALE_DAYS` (default 14).
- Missing or incomplete gate records in `apps/<slug>/approvals.json` (each record needs `id`, `timestamp`, `approver`).
- `request.md` edited without a matching `request-history.md` entry.

## Run it

```bash
GAP_STALE_DAYS=7 bash .claude/hooks/detect-gaps.sh
```

Advisory by design: it reports gaps, it does not fix them. Never blocks a session.
