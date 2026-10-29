# Agent Coordination Rules

The protocol every agent follows when working with another agent or a human.
These are behavioural rules; the handoff graph is in
`agent-coordination-map.md`, the gate definitions in `director-gates.md`, and
the review passes in `review-workflow.md`.

---

## 1. The collaboration loop

Every task that produces a durable artifact (a file, an approval, a stage
change) runs the same five steps. No step may be skipped, and no step may be
compressed into "I just did it".

1. **Question** — state the decision in one sentence, and what is actually at
   stake (merchant value, App Store risk, review score, engineering days).
2. **Options** — 2–3 real options. For each: what ships concretely, who it
   serves, what it costs, what it forecloses. No strawmen.
3. **Decision** — one recommendation with reasoning and evidence. Name the
   trade-off out loud.
4. **Draft** — write it down before implementing: files, structure, diff
   summary, or the exact document text.
5. **Approval** — ask explicitly ("May I write these files?") and wait. A
   leading question is not an approval; silence is not an approval.

Read-only work (a status check, a grep, a research read) is exempt. Anything
that writes, gates, or changes stage runs the loop.

## 2. Authority and delegation

- **The human decides product, scope, pricing, and release timing.** Agents
  recommend; they do not ratify their own recommendations.
- **Delegate downward only.** Directors → leads → specialists. A specialist
  escalates rather than negotiating upward past its lead.
- **Assignment ≠ decision.** A `producer` may assign work to any agent, but may
  not decide architecture (that is `technical-director`) or scope (that is
  `product-director`).
- **One owner per artifact.** Each file under `docs/`, `production/`, `apps/`,
  `src/`, `scripts/` has an owning agent for the duration of a task. A second
  agent edits it only with the owner's explicit handoff.

## 3. Handoffs

- A handoff is an artifact plus a named receiver. "QA will look at it" is not a
  handoff; a test plan path is.
- The receiver confirms the artifact exists and answers the question it was
  meant to answer, or returns it. Silent acceptance of a bad handoff is the most
  expensive failure mode in this pipeline.
- Blocked work is surfaced immediately with the blocker named. Never silently
  drop a workstream; produce a partial report naming what completed and what
  blocked.
- Parallel dispatch is allowed only when inputs are independent. If B needs A's
  output, run A first — do not parallelise and reconcile later.

## 4. Conflict resolution

| Conflict | Resolve in |
|---|---|
| Two specialists, same module | `lead-engineer` |
| Implementation vs architecture | `technical-director` |
| Merchant value vs engineering cost | `product-director` + `technical-director`, `producer` frames the trade |
| Scope vs deadline | `product-director` decides scope, `producer` re-plans |
| Security vs delivery pressure | `security-specialist` finding stands until `technical-director` records a waiver |
| Quality vs release date | `qa-lead` verdict stands; only a written waiver advances the gate |
| Two directors disagree | surface both positions to the human, one recommendation each |

A resolution is written into `request.md`, an ADR, or a tech-debt record. A
conflict "resolved" in chat only will be re-litigated in the next sprint.

## 5. Gate discipline

- Gates close stages: `gate-1-research`, `gate-2-prototype`, `gate-3-scope`,
  `gate-4-release`, `gate-5-update`. There are no others; an unrecognised id is
  a typo and is refused.
- Nothing advances a stage except a recorded approval in
  `apps/<app>/approvals.json` with `id`, `timestamp`, and `approver`.
- Gate verdicts are binary: READY, NOT READY, BLOCKED. "Ready with notes" is
  NOT READY.
- Gate evidence must be on the commit being judged. Evidence from an earlier
  commit is a finding, not a pass.
- Waivers are per-criterion, written by the named approver, with a compensating
  control and an expiry. Never waive a security Critical, an unverified webhook
  path, or a cross-tenant data issue — escalate instead.

## 6. Cross-domain change propagation

When a change crosses domains, the owner notifies before the change lands:

| Change | Who notifies | Whom |
|---|---|---|
| Scope / `request.md` | `product-director` | `producer`, `technical-director`, `ux-lead` |
| ADR added or revised | `technical-director` | `lead-engineer`, `app-architect`, affected specialists, `qa-lead` |
| API version or deprecation | `api-lead` | `app-architect`, `graphql-specialist`, `webhooks-specialist` |
| Polaris / flow change | `ux-lead` | `polaris-specialist`, `accessibility-specialist`, `qa-lead` |
| Schema or migration | `app-architect` | `lead-engineer`, `devops-engineer`, `test-store-manager` |
| Billing or pricing change | `billing-specialist` + `growth-lead` | `release-manager`, `app-store-reviewer`, `community-manager` |
| Locale or market coverage | `localization-lead` | `polaris-specialist`, `liquid-specialist`, `release-manager` |

## 7. File and data boundaries

- Write only inside the paths your rule owns: `apps/<app>/`, `docs/`,
  `production/`, `src/`, `scripts/`. Never `docs/legacy/`.
- `docs/registry/apps.json` is the one shared mutable registry. Only `stage` and
  `last_approved_gate` for your own app's entry may change; never reorder or
  rewrite other entries.
- Merchant data never lands in fixtures, logs, or test seeds. Use synthetic
  data from `test-store-manager`.
- Secrets are read from the environment; never written to a file, a doc, or a
  commit.

## 8. Review modes

Gate intensity is resolved once per skill run: `--review [full|lean|solo]`
overrides, else `production/review-mode.txt`, else `lean`.

| Mode | Runs |
|---|---|
| `full` | every skill gate plus the phase-gate panel |
| `lean` | phase-gate panel only (the default) |
| `solo` | no director gates; the recorded verdicts must say so |

Skipping a gate is a recorded note, never a silent omission. Solo mode does not
skip security review or the App Store checklist — those are gate evidence, not
director opinions.

## 9. Model tiers

Agent frontmatter `model:` is the shared tier label. On Codex, resolve it
through `.codex/agent-models.toml` and pass the model explicitly. On Hermes,
subagent models come from the profile's `delegation` section — frontmatter is
advisory.

| Tier | Claude | Codex | Use |
|---|---|---|---|
| **Haiku** | `claude-haiku-5-5` | `gpt-6-luna` | Read-and-format work: status, changelogs, lookups — no judgment |
| **Sonnet** | `claude-sonnet-5-5` | `gpt-6.1-terra` | Implementation, single-system analysis — the default |
| **Opus** | `claude-opus-5-5` | `gpt-6.1-sol` | Multi-document synthesis, gate verdicts, cross-system review |

Opus agents: `product-director`, `technical-director`, `producer`,
`lead-engineer`. Haiku agents: `qa-tester`, `accessibility-specialist`,
`community-manager`. Everything else is Sonnet — see `agent-roster.md`.

Haiku skills: `help`, `sprint-status`, `kanban-status`, `changelog`,
`patch-notes`, `create-test-store`, `propose-updates`, `update-research`.
Opus skills: `architecture-review`. All others are Sonnet. New skills: Haiku
only if they read and format; Opus only if they synthesise 5+ documents into a
high-stakes verdict.

## 10. Hermes and Codex invocation

- **Codex**: read the agent's frontmatter `model`, resolve the tier through
  `.codex/agent-models.toml`, and pass the GPT model on the child task. Do not
  rely on the project-wide default for `haiku` or `opus` tiers.
- **Hermes**: `delegation.backend` selects the routing mode; run `/start hermes`
  to configure it. Agent `model:` fields are advisory here.
- **Either way**: read any skill the agent references before spawning it. The
  model mapping changes which model runs, not what the instructions say.

## 11. Subagents vs agent teams

**Subagents** (default): spawned within one session via Task, share the session
context, run sequentially or in parallel, return results to the parent. Use for
almost everything.

**Agent teams** (opt-in, `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`): independent
sessions coordinated by a shared task list. Use only when workstreams touch
disjoint files, each runs >30 minutes, and a director or `producer` is
coordinating 3+ sessions. Do not use when one stream's output feeds another, or
when cost matters.

## 12. Parallel dispatch protocol

1. Issue all independent Task calls before waiting for any result.
2. Collect all results before starting a dependent phase.
3. If any agent is BLOCKED, surface it immediately — do not skip it silently.
4. Always produce a partial report when some agents complete and others block.
5. Apply the strictest verdict when a gate panel returns mixed results: one
   NOT READY overrides every READY.
