# Directory Structure

## Isolation contract

Each Shopify app is a separate product with its own state. There is
**no shared mutable file outside the registry**. No app may read or write
another app's directory, and no hook or skill may accumulate cross-app state in
a top-level file.

- **One writer per app.** Only that app's own agents/workflow write into
  `apps/<app>/` and `production/apps/<app>/`. Cross-app edits require an
  explicit request change.
- **`docs/registry/apps.json` is the ONE shared mutable file.** It is
  append-only: add an entry when an app is created; never rewrite or delete
  existing entries.

### Per-app ownership

Every app owns, and is the sole writer of:

- its directory `apps/<app>/`
- its own `.env.local` (git-ignored)
- its own dev-store credentials file (git-ignored)
- its own kanban file
- its own pipeline directories
  `production/apps/<app>/{sprints,milestones,session-state}/`

### State split

| Location | Holds | Never holds |
|----------|-------|-------------|
| `apps/<app>/` | working state and code: prototype, app-local docs, config, request history | sprint or milestone records |
| `production/apps/<app>/` | build and pipeline artefacts: sprints, milestones, session-state, release manifests, kanban | source code |

### Shared assets

Cross-app assets go to `src/` (shared code) or `design/` (shared design),
never inside an app directory.

## Target tree

```text
/
├── CLAUDE.md                          # Master configuration
├── TEMPLATE.md                        # Template contract (deleted once initialised)
├── request.md                         # Master request document
├── request-history.md                 # Append-only change log for request.md
├── .claude/                           # Agents, skills, hooks, rules, docs
│   └── hooks/track-request-changes.sh # Enforces request-history updates
├── scripts/                           # init-template.sh (deletes itself once applied)
├── apps/                              # One directory per app (working state + code)
│   └── <app>/
│       ├── README.md
│       ├── status.md                  # Stage, blockers, last approved gate
│       ├── approvals.json             # Gate approvals keyed by gate id
│       ├── .env.local                 # git-ignored
│       ├── credentials.<store>.json   # git-ignored dev-store credentials
│       ├── request-history.md         # App-local request history
│       └── prototype/                 # Store-facing prototype
├── production/
│   ├── session-state/                 # Repo-level only (ephemeral, gitignored)
│   └── apps/
│       └── <app>/
│           ├── sprints/
│           ├── milestones/
│           └── session-state/
├── docs/
│   ├── registry/
│   │   ├── apps.json                  # The ONE shared mutable registry
│   │   └── architecture.yaml
│   └── ...                            # Technical documentation
├── src/                               # Shared code across apps
└── design/                            # Shared design assets
```

Deliberately absent top-level directories: `assets/`, `prototypes/`, `tests/`,
`tools/`. They were never part of this pipeline; do not reintroduce them.

## Gates

Approval gate ids, used verbatim in `approvals.json` and status docs:

1. `gate-1-research`
2. `gate-2-prototype`
3. `gate-3-scope`
4. `gate-4-release`
5. `gate-5-update`
