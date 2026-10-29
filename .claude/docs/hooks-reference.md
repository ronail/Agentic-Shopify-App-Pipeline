# Active Hooks

Fifteen hooks live in `.claude/hooks/`. They are registered twice from this repo —
once for Claude Code in `.claude/settings.json`, once for Codex in
`.codex/hooks.json` — and the Hermes registration ships as
`production/hermes-hooks.yaml`, a `hooks:` snippet the operator applies to their
own profile config (`~/.hermes/config.yaml`, machine-global — not auto-applied
from the repo). One script copy, three hosts.

Each row below has its own note in `.claude/docs/hooks-reference/`, named after
the hook without the `.sh` suffix.

| Hook | Event | Trigger | Action | Blocks? |
| ---- | ----- | ------- | ------ | ------- |
| `session-start.sh` | SessionStart | Session begins | Prints the pipeline dashboard `/start` renders: `docs/registry/apps.json` + every `apps/<slug>/status.md` (stage, last gate, prototype, pipeline files, next skill, drift, blockers) | no (read-only) |
| `detect-gaps.sh` | SessionStart | Session begins | Pipeline gaps: registry ⟷ disk drift, `request.md` ⟷ `apps/<slug>/status.md` stage drift, stalled apps (`GAP_STALE_DAYS`, default 14), missing/incomplete records in `apps/<slug>/approvals.json`, untracked `request.md` edits | no (advisory) |
| `validate-commit.sh` | PreToolUse (Bash) | `git commit` | Staged JSON must parse; `apps/<app>/approvals.json` records need `id` + `timestamp` + `approver`; staged `request.md` needs staged `request-history.md`; advises on `status.md` shape and unowned `TODO/FIXME/HACK` | yes, `exit 2` |
| `validate-push.sh` | PreToolUse (Bash) | `git push` | Warns on pushes to a protected branch (`develop`/`main`/`master`) or an explicit push to one | no (warn only) |
| `approval-gate.sh` | PreToolUse (Bash) | `/release`, `/apply-updates`, phase transitions | Reads `apps/<app>/approvals.json`; blocks unless the required gate id is recorded with both a timestamp and an approver | yes, `exit 2` |
| `app-store-gate.sh` | PreToolUse (Bash) | release / store submission | Reads `production/apps/<app>/app-store-checklist.md`; blocks unless the verdict is `ready`, no row is `FAIL`, no `- [ ]` is unchecked, and at least one `PASS` row exists | yes, `exit 2` |
| `validate-skill-frontmatter.sh` | PostToolUse (Write/Edit) | `SKILL.md` or `.claude/agents/*.md` written | Frontmatter parses: `name`, `description`, `model: haiku\|sonnet\|opus`, `agent:` refs resolve to `.claude/agents/<name>.md`, `skills:` refs resolve (advisory) | no (PostToolUse, advisory — `exit 2` reports the error after the write) |
| `validate-skill-change.sh` | PostToolUse (Write/Edit) | any `.claude/skills/` edit | Advises running `/skill-test static <skill>` | no (advisory) |
| `track-request-changes.sh` | PostToolUse (Write/Edit) | `request.md` edited | Rejects an edit to `request.md` that was not accompanied by an entry in `request-history.md`; payloads for any other file exit 0 | no (PostToolUse, advisory — `exit 2` names the untracked edit after the write) |
| `notify.sh` | Notification | Notification event | Desktop notification — PowerShell on Windows, `osascript` on macOS, `notify-send` on Linux, plain line otherwise | no |
| `pre-compact.sh` | PreCompact | Context compression | Dumps per-app session state (`production/apps/<app>/session-state/active.md`), app stages, modified files, WIP markers and the last request change into the conversation | no |
| `post-compact.sh` | PostCompact | After compaction | Points back at the per-app session state, `request.md` and the last `request-history.md` row | no |
| `session-stop.sh` | SessionEnd | Session ends | Writes the accomplishment summary from `apps/<slug>/status.md`, `apps/<slug>/approvals.json` and `request-history.md` to stdout and appends it to `production/session-logs/session-log.md` | no |
| `log-agent.sh` | SubagentStart | Agent spawned | Audit trail start — logs `agent_type` with a timestamp to `production/session-logs/agent-audit.log` | no |
| `log-agent-stop.sh` | SubagentStop | Agent stops | Audit trail stop — completes the subagent record | no |

## Contract

- **Exit codes.** `exit 0` allows. In Claude Code, Codex and Hermes only `exit 2`
  blocks — and only on the pre-tool event (the stderr message is shown to the
  model). `exit 1` is a *non-blocking* error: the tool call proceeds. PostToolUse
  hooks therefore also use `exit 2` to report an error by name, but the write has
  already landed: they are advisory, not gates.
- **A gate names itself.** Every rejection starts with `BLOCKED [<hook>]:` and
  states the file and the required record, so a failed gate is never mistaken for
  a generic error.
- **No hard dependencies.** Every hook runs with `bash` alone. `jq` and
  `python3` are used when present and skipped when absent (grep/sed fallbacks);
  a missing parser degrades to a warning, never a crash.
- **Read-before-write.** The session hooks read app state; they never create an
  app directory or edit `docs/registry/apps.json`.

## Payload shapes

Every hook reads one JSON object on stdin. The keys each event carries:

| Event | Keys used |
| ----- | --------- |
| PreToolUse (Bash) | `tool_name`, `tool_input.command` |
| PreToolUse (Write/Edit) | `tool_name`, `tool_input.file_path`, `tool_input.content` |
| PostToolUse (Write/Edit) | `tool_name`, `tool_input.file_path` |
| SessionStart / SessionEnd / PreCompact / PostCompact | `session_id`, `cwd` |
| SubagentStart / SubagentStop | `session_id`, `agent_id`, `agent_type` |
| Notification | `session_id`, `message` |

A hook that receives no payload (run by hand) must still exit 0 and do something
sensible — every one here does.

## Per-hook notes

- `.claude/docs/hooks-reference/approval-gate.md` — gate ids, mapping and the failing fixture
- `.claude/docs/hooks-reference/app-store-gate.md` — checklist contract and the failing fixture
- every other hook has a one-page note at `.claude/docs/hooks-reference/<hook-name-without-.sh>.md`
