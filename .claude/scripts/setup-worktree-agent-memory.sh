#!/bin/bash
# Set up shared project agent memory for a git worktree.
set -e

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <worktree-path>" >&2
  exit 1
fi

worktree_path="$1"
worktree_claude="$worktree_path/.claude"
root_repo="$(git rev-parse --show-toplevel)"
root_memory="$root_repo/.claude/agent-memory"
link="$worktree_claude/agent-memory"

if [ ! -d "$worktree_path" ]; then
  echo "Error: Worktree path does not exist: $worktree_path" >&2
  exit 1
fi
if [ ! -d "$worktree_claude" ]; then
  echo "Error: Worktree .claude directory does not exist: $worktree_claude" >&2
  exit 1
fi
if [ ! -d "$root_memory" ]; then
  echo "Error: Root agent-memory directory does not exist: $root_memory" >&2
  exit 1
fi

if [ -L "$link" ]; then
  echo "Symlink already exists: $link"
  exit 0
fi

if [ -e "$link" ]; then
  echo "Warning: local agent-memory exists at $link and will be replaced."
  read -r -p "Continue? (y/n) " answer
  if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
  fi
  rm -rf "$link"
fi

relative_path="$(python3 -c 'import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))' "$root_memory" "$worktree_claude")"
ln -s "$relative_path" "$link"
echo "Created symlink: $link -> $relative_path"
