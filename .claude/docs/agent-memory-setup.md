# Shared Root-Level Agent Memory

Claude agents persist project memory under `.claude/agent-memory/<agent-role>/`.
Git worktrees otherwise give each checkout a separate directory, so findings are
lost when work moves between branches. This setup makes each worktree point at
one root-level memory store with a relative symlink.

## Architecture

```text
root repository/.claude/agent-memory/       shared store
worktree/.claude/agent-memory ->             relative symlink to the store
```

The memory directory is local session state and is excluded from Git. Each
worktree needs to be configured once.

## Setup

From the repository root, run:

```bash
./.claude/scripts/setup-worktree-agent-memory.sh <worktree-path>
```

For example:

```bash
./.claude/scripts/setup-worktree-agent-memory.sh ./.claude/worktrees/my-feature
```

The script validates both paths, preserves an existing symlink, warns before
replacing a local directory, and creates a portable relative symlink.

Verify the result with:

```bash
ls -la <worktree-path>/.claude/agent-memory
```

## Migration, cleanup, and recovery

Back up local memory before accepting migration, then merge useful files into
the root store. To return a worktree to isolated memory, remove only its
symlink; the root store is unaffected:

```bash
rm <worktree-path>/.claude/agent-memory
```

If the link is broken, remove it and rerun the setup script. On macOS and Linux
symlinks work without extra configuration. Windows requires symlink support,
administrator privileges, or Git configured with `core.symlinks=true`.

## Design rationale

Symlinks provide one source of truth, immediate visibility between worktrees,
no synchronization job, and no duplicated memory files. The setup script uses
relative paths so the repository remains portable when its parent directory
moves.

## Limitations

This is a one-time setup per worktree; automatic setup during worktree creation
is a future enhancement. Shared memory is machine-local and should not contain
secrets or information intended for version control.
