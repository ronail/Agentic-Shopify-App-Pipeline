# Setup Requirements

Prerequisites for the Agentic Shopify App Pipeline. All hooks fail gracefully if
their tools are missing — nothing breaks, but you lose validation.

## First Run in a Generated Repo

If you generated this repo from the template, run the initialiser **before**
anything else:

```bash
scripts/init-template.sh --name "<your project>" --app <slug>     # preview
scripts/init-template.sh --name "<your project>" --app <slug> --apply
```

It strips the worked-example apps, their ADRs/requirements/sprint state, the
session transcripts, the retarget history and `Skill Testing Framework/`; resets
the three registries; optionally seeds `apps/<slug>/`; runs
`.claude/scripts/check-references.py` and `.claude/scripts/isolation-check.py`;
then deletes itself and `TEMPLATE.md`. Commit the result before starting work.
`/setup` wraps the same flow with an approval step.

## Required

| Requirement | Purpose | How to get it |
| --- | --- | --- |
| **Git** | Version control, branch management, worktrees | [git-scm.com](https://git-scm.com/) |
| **Node.js LTS** (with npm) | Remix app server, build, test runner | [nodejs.org](https://nodejs.org/) — pick the LTS line |
| **Shopify CLI** | `shopify app dev`, `shopify app deploy`, config push, tunnels | `npm install -g @shopify/cli@latest` (or as a project dev dependency) |
| **Shopify Partner account** | App registration, client credentials, extension drafts, App Store submission | [partners.shopify.com](https://partners.shopify.com) |
| **Development store** | The store the app installs into while you build | Partner dashboard → Stores → Add store → Development store |
| **A harness** | Runs the agents and skills | Claude Code (`npm install -g @anthropic-ai/claude-code`), Codex CLI, or Hermes |

Claude Code is the primary workflow runtime. Codex users should install the
[Codex CLI](https://developers.openai.com/codex/cli) to use the project
configuration in `.codex/`. Hermes users follow the shared repository
conventions and configure subagent model routing via `/start hermes` (see the
Hermes section below).

## Shopify Platform Pins

These are fixed for this repo. Do not drift them without a recorded ADR.

| Pin | Value | Where it lives |
| --- | --- | --- |
| **Admin GraphQL API version** | `2026-10` | `apps/<app>/shopify.app.toml`; read from config, never hardcoded in a query |
| **API reference snapshot** | `docs/shopify-api-reference/2026-10/` | Checked-in per-surface notes: `admin-graphql.md`, `webhooks.md`, `billing.md`, `checkout-extensions.md`, `storefront.md` |
| **App stack** | Remix + Node service, embedded Polaris admin | `apps/<app>/` |
| **Extension surfaces** | Theme app extensions and checkout UI extensions, only when the app needs them | `apps/<app>/extensions/` |

The LLM's training data predates 2026-10. Before writing any Admin GraphQL
query, mutation, or webhook payload, read the pinned snapshot — do not guess at
field names, mutation arguments, or deprecation status.

### Scopes

Scopes are declared in `apps/<app>/shopify.app.toml` under `access_scopes` and
pushed to the store by `shopify app deploy` (and by `shopify app dev` on start).

- Request the **minimum** set that the app's requirements name — one access
  scope per capability the app actually implements.
- Every scope needs a reason in the ADR's **Shopify API Surface** section. An
  unjustified scope is a security finding and an App Store review risk.
- Removing a scope requires reinstall on the store to take effect.
- Protected customer data requires a declared use case in the Partner dashboard
  before the scope will return data.

## Recommended

| Tool | Used By | Purpose | Install |
| --- | --- | --- | --- |
| **jq** | Hooks | JSON parsing in commit/push/agent hooks | See below |
| **Python 3** | Hooks | JSON validation for data files | [python.org](https://www.python.org/) |
| **Bash** | All hooks | Shell script execution | Included with Git for Windows |

### Installing jq

**Windows** (any of these):
```
winget install jqlang.jq
choco install jq
scoop install jq
```

**macOS**:
```
brew install jq
```

**Linux**:
```
sudo apt install jq     # Debian/Ubuntu
sudo dnf install jq     # Fedora
sudo pacman -S jq       # Arch
```

## Platform Notes

### Windows
- Git for Windows includes **Git Bash**, which provides the `bash` command used
  by all hooks in `settings.json`
- Ensure Git Bash is on your PATH (default if installed via the Git installer)
- Hooks use `bash .claude/hooks/[name].sh` — this works on Windows because
  Claude Code invokes commands through a shell that can find `bash.exe`
- Symlinked agent memory (see `agent-memory-setup.md`) needs `core.symlinks=true`
  or administrator privileges

### macOS / Linux
- Bash is available natively
- Install `jq` via your package manager for full hook support

## Verifying Your Setup

```bash
git --version              # git version
node --version             # LTS line, e.g. v22.x
npm --version
shopify version            # Shopify CLI
jq --version               # optional
python3 --version          # optional
```

Then prove the Shopify side works end to end:

```bash
shopify auth logout && shopify auth login   # Partner account reachable
shopify app config link                     # repo attached to a Partner app
shopify app dev --store <your-dev-store>    # server + tunnel + install
```

A successful `shopify app dev` prints the embedded admin URL and installs the
app on your dev store. If the install fails, the usual causes are a scope the
app has not declared, a missing `application_url`, or an expired CLI login.

## What Happens Without Optional Tools

| Missing Tool | Effect |
| --- | --- |
| **jq** | Commit validation, push protection, and agent audit hooks silently skip their checks. Commits and pushes still work. |
| **Python 3** | JSON data file validation in commit hooks is skipped. Invalid JSON can be committed without warning. |
| **Both** | All hooks still execute without error (exit 0) but provide no validation. You're flying without safety nets. |

## Hermes Setup (Alternative Harness)

Hermes is supported as an alternative harness to Claude Code. The repository
provides shared conventions (skills, agents, hooks) that work with Hermes
profiles, and Hermes resolves subagent models through its own delegation
configuration rather than through frontmatter.

### Installing Hermes

See the [Hermes Agent documentation](https://hermes-agent.nousresearch.com/docs)
for installation instructions. Once installed, verify with:

```bash
hermes --version
```

### Profile and delegation configuration

Hermes profiles reside in `~/.hermes/profiles/<name>/config.yaml` and control
model resolution, API keys, and provider settings. This repository does not
ship Hermes-specific configuration — you manage profiles in your Hermes
installation.

To configure how subagents pick their model:

1. Run `/start hermes` during onboarding
2. Phase 3d detects your profiles, the active `delegation.backend`, and whether
   the `advanced-delegation` plugin is installed, then asks for a mode:
   `model_map` (a per-task named model route), `profile_routes` (a per-task
   Hermes profile), or `default` (one model for every subagent)
3. The plan is written to `production/hermes-delegation.yaml` (paste-ready
   config) and `production/hermes-profile-mapping.json` (the record)

`model_map` and `profile_routes` need the official plugin in the profile that
delegates (Hermes 0.22.5 or newer):

```bash
hermes plugins install advanced-delegation
hermes delegation config        # or paste production/hermes-delegation.yaml
```

A selected backend that is missing or cannot run fails closed — `delegate_task`
errors instead of falling back to `default`.

When using Hermes, the `model:` fields in skill/agent frontmatter are advisory
only — the `delegation` configuration determines which model actually runs.
Without Hermes (e.g., using Claude Code directly), those `model:` fields are
used directly.

### Verifying Hermes Integration

After running `/start hermes`, check that the routing record and config were
written:

```bash
cat production/hermes-profile-mapping.json production/hermes-delegation.yaml
```

The JSON carries `"schemaVersion": 2` with a `delegation` block (strategy,
backend, route table) and a `roles` map. A legacy file with no `schemaVersion`
key is the older flat `{"agent-name": "profile-name"}` mapping and is still
readable.

## Recommended IDE

Claude Code works with any editor, but the pipeline is optimized for:

- **VS Code** with the Claude Code extension
- **Cursor** (Claude Code compatible)
- Terminal-based Claude Code CLI

## Further Reading

- `quick-start.md` — the five-step boot sequence
- `technical-preferences.md` — stack, naming, budgets, forbidden patterns
- `coding-standards.md` — code and requirements doc standards
- `docs/shopify-api-reference/2026-10/` — the pinned API snapshot
