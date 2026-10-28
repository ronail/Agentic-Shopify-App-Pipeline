# Setup Requirements

This template requires a few tools to be installed for full functionality.
All hooks fail gracefully if tools are missing — nothing will break, but
you'll lose validation features.

## Required

| Tool | Purpose | Install |
| ---- | ---- | ---- |
| **Git** | Version control, branch management | [git-scm.com](https://git-scm.com/) |
| **Claude Code** | AI agent CLI | `npm install -g @anthropic-ai/claude-code` |

Claude Code is the primary workflow runtime. Codex users should also install
the [Codex CLI](https://developers.openai.com/codex/cli) to use the project
configuration in `.codex/`. Hermes users can follow the shared repository
conventions and configure subagent model routing interactively via `/start
hermes` (see the Hermes Setup section below for details).

## Recommended

| Tool | Used By | Purpose | Install |
| ---- | ---- | ---- | ---- |
| **jq** | Hooks (7 of 12) | JSON parsing in commit/push/asset/agent hooks | See below |
| **Python 3** | Hooks (2 of 12) | JSON validation for data files | [python.org](https://www.python.org/) |
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
- Git for Windows includes **Git Bash**, which provides the `bash` command
  used by all hooks in `settings.json`
- Ensure Git Bash is on your PATH (default if installed via the Git installer)
- Hooks use `bash .claude/hooks/[name].sh` — this works on Windows because
  Claude Code invokes commands through a shell that can find `bash.exe`

### macOS / Linux
- Bash is available natively
- Install `jq` via your package manager for full hook support

## Verifying Your Setup

Run these commands to check prerequisites:

```bash
git --version          # Should show git version
bash --version         # Should show bash version
jq --version           # Should show jq version (optional)
python3 --version      # Should show python version (optional)
```

## What Happens Without Optional Tools

| Missing Tool | Effect |
| ---- | ---- |
| **jq** | Commit validation, push protection, asset validation, and agent audit hooks silently skip their checks. Commits and pushes still work. |
| **Python 3** | JSON data file validation in commit and asset hooks is skipped. Invalid JSON can be committed without warning. |
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

Claude Code works with any editor, but the template is optimized for:
- **VS Code** with the Claude Code extension
- **Cursor** (Claude Code compatible)
- Terminal-based Claude Code CLI
