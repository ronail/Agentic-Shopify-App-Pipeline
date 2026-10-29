# Request History

> **File**: `request-history.md` (repo root) · **App-local**: `apps/<app>/request-history.md`
> **Append-only.** Never edit or delete a past entry — corrections are new entries
> that reference the original.

## Format

One entry per accepted change, newest at the bottom. Keep entries short enough to
scan; the detail lives in the PRD it triggered.

```markdown
## [YYYY-MM-DD] — [Short title]

- **Requester**: [person/agent]
- **Approved by**: [person + gate id if relevant]
- **Change**: [What changed in the request, in one or two sentences]
- **Reason**: [The merchant pain or constraint that forced it]
- **Apps affected**: [apps/<app>, ...]
- **Downstream updated**: [PRD / ADR / milestone / stories — links]
- **Supersedes**: [earlier entry date, or "none"]
```

---

## Entries

## [YYYY-MM-DD] — Initial request

- **Requester**: [who]
- **Approved by**: [who]
- **Change**: Initial portfolio request established — [N] apps in scope.
- **Reason**: [Why now]
- **Apps affected**: [list]
- **Downstream updated**: [`request.md`], [`docs/registry/apps.json`]
- **Supersedes**: none

## [YYYY-MM-DD] — [Example: multi-location sync deferred]

- **Requester**: [who]
- **Approved by**: [producer, gate-3-scope]
- **Change**: Multi-location write-back moved out of the first release; read-only
  location mapping stays in scope.
- **Reason**: Submission window is fixed; pilots' core pain is visibility.
- **Apps affected**: `apps/order-sync`
- **Downstream updated**: `docs/prd/sync.md`, `docs/adr/adr-0005-read-only-location-mapping.md`
- **Supersedes**: [entry date of the original multi-location requirement]

---

## Rules

| Rule | Why |
|------|-----|
| One entry per approved change, appended at the end | The file is an audit trail; ordering is the only index |
| Every entry names an approver | Unapproved scope changes are the main source of drift |
| Every entry lists downstream docs updated | A request change with no PRD change is a lie |
| Corrections are new entries | History is evidence; rewriting it destroys trust |
| App-local changes go in `apps/<app>/request-history.md` | The isolation contract: no cross-app writes |
