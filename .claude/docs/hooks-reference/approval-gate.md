# approval-gate.sh — gate approval enforcement

Blocks a release, an update application, or a phase transition unless the
required gate is recorded in `apps/<app>/approvals.json` with a timestamp **and**
an approver.

## Gate ids and what they unlock

| Action | Required gate |
| ------ | ------------- |
| `/release <app>` | `gate-4-release` |
| `/apply-updates <app>`, `/propose-updates <app>` | `gate-5-update` |
| `advance-phase <app> research` | `gate-1-research` |
| `advance-phase <app> prototype` | `gate-2-prototype` |
| `advance-phase <app> scope` | `gate-3-scope` |
| `advance-phase <app> release` | `gate-4-release` |
| `advance-phase <app> update` | `gate-5-update` |

Stages `build` and `qa` have no gate of their own: they sit between
`gate-3-scope` and `gate-4-release`.

## Record shape

```json
{
  "gate-4-release": {
    "id": "gate-4-release",
    "timestamp": "2026-11-02T09:14:00Z",
    "approver": "product-director"
  }
}
```

A record missing `timestamp`, `approver`, or the gate key itself is treated as
not approved. The file lives at `apps/<app>/approvals.json`; `--apps <dir>`
(or `APPS_DIR`) points the hook at another root, which is how the negative
fixtures run.

## Invocation

```bash
# explicit
bash .claude/hooks/approval-gate.sh --app my-app --gate gate-4-release
bash .claude/hooks/approval-gate.sh --app my-app --action release

# hook mode: reads the PreToolUse payload, silent unless the command is gated
echo '{"tool_input":{"command":"/release my-app"}}' \
  | bash .claude/hooks/approval-gate.sh
```

Exit `0` = approved or not a gated action. Exit `2` = `BLOCKED
[approval-gate.sh]: ...` on stderr.

## Failing fixture (AC-R6.6)

```bash
TMP=$(mktemp -d)
mkdir -p "$TMP/apps/demo"
printf '%s\n' '{"gate-1-research": {"id": "gate-1-research", "timestamp": "2026-10-29T00:00:00Z", "approver": "product-director"}}' \
  > "$TMP/apps/demo/approvals.json"
bash .claude/hooks/approval-gate.sh --apps "$TMP/apps" --app demo --gate gate-4-release
# BLOCKED [approval-gate.sh]: gate-4-release is not approved for 'demo' ...
# exit 2
```

## Why a gate is a hook, not a checklist

A gate that has never rejected anything is not verified. The fixture above is the
proof: the same script returns `0` for `gate-1-research` and `2` for
`gate-4-release` against one approvals file.
