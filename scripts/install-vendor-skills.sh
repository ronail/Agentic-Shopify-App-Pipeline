#!/usr/bin/env bash
# Materialise the third-party skills pinned in .claude/vendor.lock.json.
#
# They are dependencies, not framework skills: nothing is committed, and a
# generated project fetches what it needs at init time. The lock pins an exact
# commit, so an install is reproducible and an upgrade is a diff to this file.
#
#   bash scripts/install-vendor-skills.sh --check            # report only
#   bash scripts/install-vendor-skills.sh --install          # all entries
#   bash scripts/install-vendor-skills.sh --install <name>   # one entry
#   bash scripts/install-vendor-skills.sh --install-at-init  # install_at_init entries
#
# Exit codes: 0 ok, 1 something missing/stale (--check), 2 bad input or fetch failure.

set -eu

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK="$ROOT/.claude/vendor.lock.json"
MODE="check"
ONLY=""

case "${1:-}" in
  --check) MODE="check" ;;
  --install) MODE="install"; ONLY="${2:-}" ;;
  --install-at-init) MODE="init" ;;
  -h|--help) sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  "") ;;
  *) echo "unknown argument: $1" >&2; exit 2 ;;
esac

[ -f "$LOCK" ] || { echo "missing $LOCK" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "python3 is required to read the lock" >&2; exit 2; }

# name \t repo \t path \t commit \t dest \t install_at_init
ENTRIES=$(python3 - "$LOCK" <<'PY'
import json, sys
lock = json.load(open(sys.argv[1]))
for s in lock.get("skills", []):
    print("\t".join([
        s["name"], s["repo"], s["path"], s["commit"], s["dest"],
        "1" if s.get("install_at_init") else "0",
    ]))
PY
)

installed_commit() {
  python3 - "$1/.installed.json" <<'PY' 2>/dev/null || true
import json, sys
try:
    print(json.load(open(sys.argv[1])).get("commit", ""))
except Exception:
    pass
PY
}

failures=0
while IFS="$(printf '\t')" read -r name repo path commit dest init; do
  [ -n "$name" ] || continue
  if [ -n "$ONLY" ] && [ "$name" != "$ONLY" ]; then continue; fi
  if [ "$MODE" = "init" ] && [ "$init" != "1" ]; then continue; fi

  target="$ROOT/$dest"
  have=""
  if [ -f "$target/SKILL.md" ]; then have=$(installed_commit "$target"); fi

  case "$MODE" in
    check)
      if [ -z "$have" ]; then
        echo "missing   $name ($repo @ ${commit:0:7})"
        failures=$((failures + 1))
      elif [ "$have" != "$commit" ]; then
        echo "stale     $name (installed ${have:0:7}, pinned ${commit:0:7})"
        failures=$((failures + 1))
      else
        echo "ok        $name @ ${commit:0:7}"
      fi
      ;;
    install|init)
      if [ "$have" = "$commit" ]; then
        echo "already   $name @ ${commit:0:7}"
        continue
      fi
      tmp=$(mktemp -d)
      trap 'rm -rf "$tmp"' EXIT
      echo "fetching  $name from $repo @ ${commit:0:7}"
      if ! git init -q "$tmp" \
        || ! git -C "$tmp" remote add origin "https://github.com/$repo.git" \
        || ! git -C "$tmp" fetch -q --depth 1 origin "$commit"; then
        echo "fetch failed for $name — check network access and the pinned commit" >&2
        exit 2
      fi
      git -C "$tmp" checkout -q FETCH_HEAD
      [ -d "$tmp/$path" ] || { echo "upstream path not found: $path" >&2; exit 2; }
      rm -rf "$target"
      mkdir -p "$target"
      cp -R "$tmp/$path/." "$target/"
      rm -rf "$target/agents"          # regenerated locally by .codex/generate_compat.py
      printf '{\n  "commit": "%s",\n  "repo": "%s",\n  "path": "%s"\n}\n' \
        "$commit" "$repo" "$path" > "$target/.installed.json"
      echo "installed $name @ ${commit:0:7} -> $dest"
      ;;
  esac
done <<EOF
$ENTRIES
EOF

if [ "$MODE" = "check" ] && [ "$failures" -gt 0 ]; then
  echo
  echo "$failures vendor skill(s) missing or stale. Install with:"
  echo "  bash scripts/install-vendor-skills.sh --install"
  exit 1
fi

exit 0
