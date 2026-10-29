#!/usr/bin/env python3
"""Isolation check — enforces AC-R8.5 / AC-R10.5.

Contract (`.claude/docs/directory-structure.md`): no two apps may write the same
path outside the one shared mutable registry, `docs/registry/apps.json`.

An app's declared outputs are:
  * every file under `apps/<slug>/` and `production/apps/<slug>/` (walked), and
  * any repo-relative paths listed in `apps/<slug>/outputs.json`
    (shape: {"outputs": ["path", ...]} or a bare JSON array of paths).

Exit 0 and print `ISOLATION OK` when the tree is clean. Exit 1 and print each
shared path BY NAME, with the apps that claim it, otherwise.

Usage: isolation-check.py [ROOT]
ROOT defaults to the repository root two levels above this script
(<root>/<agent-dir>/scripts/isolation-check.py).
"""
import json
import os
import sys

SHARED_ALLOWED = "docs/registry/apps.json"
APP_ROOTS = ("apps", "production/apps")


def repo_root(argv):
    if len(argv) > 1:
        return os.path.abspath(argv[1])
    here = os.path.dirname(os.path.abspath(__file__))       # <root>/<dir>/scripts
    return os.path.dirname(os.path.dirname(here))           # <root>


def norm(path):
    return os.path.normpath(path).replace(os.sep, "/")


def app_slugs(root):
    slugs = set()
    for base in APP_ROOTS:
        d = os.path.join(root, base)
        if not os.path.isdir(d):
            continue
        for name in os.listdir(d):
            if os.path.isdir(os.path.join(d, name)):
                slugs.add(name)
    return sorted(slugs)


def declared_outputs(root, slug):
    paths = set()
    for base in APP_ROOTS:
        top = os.path.join(root, base, slug)
        if not os.path.isdir(top):
            continue
        for dirpath, _dirs, files in os.walk(top):
            for fname in files:
                paths.add(norm(os.path.relpath(os.path.join(dirpath, fname), root)))

    manifest = os.path.join(root, "apps", slug, "outputs.json")
    if os.path.isfile(manifest):
        try:
            with open(manifest, encoding="utf-8") as fh:
                data = json.load(fh)
        except (OSError, ValueError) as exc:
            sys.exit("isolation-check: cannot parse %s: %s" % (manifest, exc))
        entries = data.get("outputs", []) if isinstance(data, dict) else data
        for entry in entries:
            paths.add(norm(str(entry)))
    return paths


def main(argv):
    root = repo_root(argv)
    slugs = app_slugs(root)

    owners = {}
    for slug in slugs:
        for path in declared_outputs(root, slug):
            owners.setdefault(path, set()).add(slug)

    shared = {p: apps for p, apps in owners.items()
              if len(apps) > 1 and p != SHARED_ALLOWED}

    if shared:
        print("ISOLATION FAIL — %d shared output path(s):" % len(shared))
        for path in sorted(shared):
            print("  SHARED PATH: %s  -> apps: %s"
                  % (path, ", ".join(sorted(shared[path]))))
        return 1

    print("ISOLATION OK — %d apps (%s), no shared output paths"
          % (len(slugs), ", ".join(slugs) or "none"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
