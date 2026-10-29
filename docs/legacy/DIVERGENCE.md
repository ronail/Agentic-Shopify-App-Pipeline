# DIVERGENCE — permanent fork from ronail/Agent-Harness-Game-Studios

**Status:** permanent. This is not a tracking fork.

## The rule

This repository diverged permanently from
[`ronail/Agent-Harness-Game-Studios`](https://github.com/ronail/Agent-Harness-Game-Studios)
at commit **`fec6e35`** (`chore: import Agent Harness Game Studios framework as baseline`).

- **No upstream merges.** Do not run `git merge template/main`, `git pull upstream`, or
  any equivalent. Upstream is a game-development framework; this repository is a Shopify
  app pipeline. A merge reintroduces deleted agents, deleted skills, deleted rules and
  game-shaped config that later phases removed on purpose.
- **No rebase onto upstream.** Upstream history is no longer an ancestor once phases
  rewrite the tree; replaying it produces conflicts whose "resolution" is deleting the
  same files again.
- **Upstream fixes are cherry-picked by hand.** When a fix upstream is genuinely
  domain-neutral — a hook bug, a shell portability fix, a documentation correction — read
  the upstream commit, re-express the change in Shopify terms against this tree, and
  commit it here as a normal change. A raw cherry-pick of a commit that touches game
  content is not acceptable, even if it applies cleanly.

## Why

The refactor from the imported baseline is destructive by design: agents are deleted,
skills are deleted, the engine layer is removed, and the config layer is retargeted at
Shopify. `UPGRADING.md`, which upstream shipped, described the opposite strategy — merge
the template forward and re-apply local edits per release. That guide has been deleted
because following it resurrects the framework this repository replaced.

## What this means in practice

| Situation | Do this |
|-----------|---------|
| Upstream fixes a hook | Read the diff, rewrite it for this tree, commit as `fix:` |
| Upstream adds a new game agent | Ignore it |
| Upstream adds a genuinely domain-neutral skill | Consider re-authoring it for a pipeline stage; do not copy the directory |
| Upstream changes licence or attribution | Mirror the attribution change in `LICENSE` and `README.md` |
| You want to know what changed upstream | `git log` against a separate clone; this repo has no upstream remote to fetch |

## Attribution still applies

Divergence is a code relationship, not a credit relationship. Both upstream projects
remain credited in `README.md`, and `LICENSE` keeps both copyright notices unchanged.
