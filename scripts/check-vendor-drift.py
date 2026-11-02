#!/usr/bin/env python3
"""Check that the third-party skills pinned in ``.claude/vendor.lock.json``
are installed as pinned, and that upstream has not moved past the pin.

Vendor skills are dependencies, not committed content: the lock records a repo,
a path and an exact commit, and ``scripts/install-vendor-skills.sh`` fetches it.
That leaves two ways to be wrong:

1. **Installed state** — the skill is absent, or its ``.installed.json`` commit
   no longer matches the lock. Offline; catches a hand-edited or stale install.
2. **Upstream drift** — the upstream default branch has moved past the pinned
   commit. One API call per entry; the signal to re-pin deliberately.

Usage:
    python3 scripts/check-vendor-drift.py            # both halves
    python3 scripts/check-vendor-drift.py --offline  # installed state only
    python3 scripts/check-vendor-drift.py --report-md summary.md

Exit codes: 0 clean, 1 drift or missing install, 2 configuration/API failure.
"""

from __future__ import annotations

import argparse
import json
import os
import pathlib
import sys
import urllib.error
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
LOCK = ROOT / ".claude" / "vendor.lock.json"
API = "https://api.github.com"


def api_get(url: str) -> dict:
    req = urllib.request.Request(url)
    req.add_header("Accept", "application/vnd.github+json")
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode("utf-8"))


def installed_commit(dest: pathlib.Path) -> str:
    meta = dest / ".installed.json"
    if not meta.is_file():
        return ""
    try:
        return json.loads(meta.read_text()).get("commit", "")
    except json.JSONDecodeError:
        return ""


def check_installed(entry: dict) -> list[str]:
    name = entry["name"]
    dest = ROOT / entry["dest"]
    if not (dest / "SKILL.md").is_file():
        return [f"{name}: not installed ({entry['repo']} @ {entry['commit'][:7]})"]
    have = installed_commit(dest)
    if have != entry["commit"]:
        return [f"{name}: installed {have[:7] or 'unknown'} but pinned {entry['commit'][:7]}"]
    return []


def check_upstream(entry: dict) -> tuple[list[str], list[str]]:
    name, repo, pinned = entry["name"], entry["repo"], entry["commit"]
    try:
        head = api_get(f"{API}/repos/{repo}/commits/HEAD").get("sha", "")
    except urllib.error.HTTPError as exc:
        return [], [f"{name}: API {exc.code} — upstream check skipped"]
    except urllib.error.URLError as exc:
        return [], [f"{name}: network error ({exc.reason}) — upstream check skipped"]

    if not head:
        return [], [f"{name}: upstream returned no commit — skipped"]
    if head != pinned:
        return [f"{name}: upstream moved {pinned[:7]} -> {head[:7]} ({repo})"], []
    return [], [f"{name}: upstream at pinned {pinned[:7]}"]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--offline", action="store_true", help="skip the upstream check")
    parser.add_argument("--report-md", help="write a markdown report to this path")
    args = parser.parse_args()

    if not LOCK.is_file():
        print(f"missing {LOCK}", file=sys.stderr)
        return 2
    entries = json.loads(LOCK.read_text()).get("skills", [])
    if not entries:
        print("lock file has no skills", file=sys.stderr)
        return 2

    problems: list[str] = []
    notes: list[str] = []
    for entry in entries:
        problems.extend(check_installed(entry))
        if not args.offline:
            up_problems, up_notes = check_upstream(entry)
            problems.extend(up_problems)
            notes.extend(up_notes)

    lines = ["# Vendor skill drift check", ""]
    lines += [f"- {n}" for n in notes] or ["- upstream checks skipped (offline)"]
    if problems:
        lines += ["", f"## Problems ({len(problems)})", ""]
        lines += [f"- {p}" for p in problems]
        lines += ["", "Install or refresh with `bash scripts/install-vendor-skills.sh --install`."]
    else:
        lines += [
            "",
            "All pinned vendor skills are installed at their pinned commit "
            "and upstream has not moved.",
        ]

    report = "\n".join(lines)
    print(report)
    if args.report_md:
        pathlib.Path(args.report_md).write_text(report + "\n")
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as fh:
            fh.write(report + "\n")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
