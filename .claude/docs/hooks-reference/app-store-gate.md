# app-store-gate.sh — release blocked on the App Store checklist

`/app-store-checklist <app>` writes a verdict to
`production/apps/<app>/app-store-checklist.md`. The release is blocked unless
that file says the app is ready.

## Checklist contract

```markdown
## App Store Readiness — <app> — <date>
Verdict: ready | not-ready (N fails)

| # | Check | Result | Evidence / fix |
|---|-------|--------|----------------|
| 1 | Scopes minimal | PASS | apps/<app>/shopify.app.toml requests read_products only |
```

The gate fails when any of these is true:

- the checklist file does not exist
- there is no `Verdict:` line, or the verdict does not start with `ready`
- any table row's result column is `FAIL`
- any `- [ ]` checkbox is still unchecked
- there is no `PASS` row at all (an empty checklist is not a pass)

History sections may quote old failures freely; only the result column
(`| FAIL |`) counts.

## Invocation

```bash
bash .claude/hooks/app-store-gate.sh --app my-app
bash .claude/hooks/app-store-gate.sh --checklist /tmp/fixture.md
APP_STORE_CHECKLIST=/path/to/checklist.md bash .claude/hooks/app-store-gate.sh

# hook mode: fires only on release / submission commands
echo '{"tool_input":{"command":"/release my-app"}}' | bash .claude/hooks/app-store-gate.sh
```

Exit `0` = allowed. Exit `2` = `BLOCKED [app-store-gate.sh]: ...` on stderr.

## Failing fixture (AC-R6.6)

```bash
TMP=$(mktemp -d)
cat > "$TMP/checklist.md" <<'EOF'
## App Store Readiness — demo — 2026-10-29
Verdict: not-ready (1 fails)

| # | Check | Result | Evidence / fix |
|---|-------|--------|----------------|
| 1 | Scopes minimal | FAIL | requests write_products with no call site |
EOF
bash .claude/hooks/app-store-gate.sh --checklist "$TMP/checklist.md"
# BLOCKED [app-store-gate.sh]: App Store checklist failed — release is blocked
# exit 2
```
