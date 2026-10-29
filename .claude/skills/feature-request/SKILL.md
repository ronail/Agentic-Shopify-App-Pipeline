---
name: feature-request
description: "Handle a feature request through the Producer-led protocol with tiered routing. Simple single-domain requests delegate directly to domain agents; complex cross-domain requests go through the producer for full 3-phase coordination."
argument-hint: "[feature description] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Task, AskUserQuestion, request_user_input, clarify
model: sonnet
---

# Feature Request Handler

When a feature request is submitted, it is routed through a **tiered
coordination protocol** that dispatches simple requests to domain agents
directly (sonnet tier) and reserves the full Producer-led 3-phase workflow
(opus tier) for complex, cross-domain features.

**This skill does not write files directly.** All decomposition, assignment,
and verification is performed by delegated agents.

---

## Tiered Routing Overview

| Complexity | Routing | Model tier | When to use |
|-----------|---------|------------|-------------|
| **Simple** (≤ 2 domains, ≤ 3 stories) | Direct delegation to domain agent | sonnet | Single-domain, straightforward features |
| **Complex** (> 2 domains OR > 3 stories OR architecture keywords) | Delegate to `producer` agent | opus | Cross-domain, needs coordination |

**Escalation**: If the producer is unavailable (Complex route),
`product-director` acts as interim coordinator for feature requests,
re-delegating to the producer when available.

**When to use this skill**:
- A user submits a new feature request
- A feature idea emerges mid-sprint that needs scope assessment
- An external stakeholder (merchant, partner, support) requests a feature

---

## Phase 0: Parse Arguments

- `$ARGUMENTS[0]` — the feature request description
- `--review [full|lean|solo]` — optional review mode override

Resolve review mode (stored for downstream use):
1. If `--review [mode]` was passed → use that
2. Else read `production/review-mode.txt` → use that value
3. Else default to `lean`

**Argument check**: If no feature description is provided, output:

> "Usage: `/feature-request [feature description] [--review full|lean|solo]`
> Provide a description of the feature to handle (e.g., `add volume discounts`,
> `implement merchant onboarding checklist`)."

Then stop — do not spawn any agents.

---

## Phase 1: SDLC Validity Check

Before complexity assessment, validate that the feature request itself is
**valid, actionable, and ready for routing**. This is a lightweight, read-only
check (haiku tier, consistent with `/scope-check`) that prevents underspecified
requests from consuming higher-tier agent budget on clarification that should
have happened upfront.

**Approach**: Evaluate the request against 4 validity dimensions, reading
relevant project context files (no director gates spawned). Each dimension
is assessed as PASS / NEEDS CLARIFICATION / BLOCKED.

### The 4-Step Validity Framework

| Step | Dimension | What to verify | Sources to read |
|------|-----------|---------------|-----------------|
| **1** | **Strategic Alignment** (The "Why") | Does this feature serve the current `request.md` and the app it belongs to? Does it move a goal the user actually stated? Is the request from a real merchant or operator need? | `request.md`, `request-history.md`, `apps/<app>/status.md`, `production/milestones/` |
| **2** | **Value & Impact** (The "What") | Does it solve a root-cause problem (not just a symptom)? How often will it be used? Is projected value > cost to build? | Feature description argument, `docs/architecture/apps/<app>/requirements.yaml`, existing stories |
| **3** | **Technical Feasibility** (The "How") | Can the current architecture and platform APIs support this? Security/compliance risks? Long-term maintenance burden or technical debt? | `production/stage.txt`, `docs/architecture/architecture.md`, `docs/architecture/apps/<app>/ADR-*.md` |
| **4** | **Scope & Resources** (The "Who & When") | Is there design/engineering/QA bandwidth now? What existing roadmap items must be delayed? Dependencies identified? In/out of scope clear? | `production/sprints/` (current capacity), `production/milestones/`, feature description argument |

**Assessment algorithm**:
1. Read project context: `production/stage.txt` for current phase,
   `request.md` for the master request and goals,
   `production/sprints/` for current sprint and capacity,
   `docs/architecture/` for technical constraints.
2. Evaluate each of the 4 steps as PASS / NEEDS CLARIFICATION / BLOCKED.
3. Assign an overall verdict:
   - **VALID** — all 4 steps pass (or at most 2 are NEEDS CLARIFICATION)
   - **NEEDS CLARIFICATION** — 3–4 steps are NEEDS CLARIFICATION
   - **BLOCKED** — ≥1 step is BLOCKED (no strategic alignment, infeasible, unbounded scope, or untestable outcomes)

### Verdict outcomes

| Verdict | Behavior |
|---------|----------|
| **VALID** | Proceed to Phase 2 (Complexity Assessment) |
| **NEEDS CLARIFICATION** | Present the checklist with gaps flagged. Ask targeted clarifying questions via the structured UI. Offer: `[A] Clarify now — answer the questions and re-run` / `[B] Proceed anyway — I accept the risk` |
| **BLOCKED** | Do NOT route. Present specific gaps. Offer: `[A] Provide more detail and re-run` / `[B] Cancel — defer this feature` |

> **Never auto-advance a BLOCKED request.** The verdict is advisory but BLOCKED
> requests must not consume producer or domain agent budget without user sign-off.

---

## Phase 2: Complexity Assessment

Scan `$ARGUMENTS[0]` for domain keywords to determine routing:

**Domain keyword mapping**:

| Domain | Keywords (case-insensitive) | Agent |
|--------|----------------------------|-------|
| `ui` | ui, ux, layout, interface, design, theme, screen, admin, component, accessibility | `ux-lead` (with `polaris-specialist` or `app-bridge-specialist` as implementer) |
| `api` | api, graphql, query, mutation, endpoint, integration, sync, schema | `api-lead` (with `graphql-specialist` as implementer) |
| `billing` | billing, plan, price, pricing, subscription, charge, trial, usage, monetiz | `billing-specialist` |
| `checkout` | checkout, cart, discount, function, delivery, shipping, payment | `checkout-specialist` |
| `auth` | auth, oauth, token, session, scope, permission, install, uninstall | `auth-specialist` |
| `platform` | webhook, job, event, deploy, ci, migration, performance, analytics, data | `webhooks-specialist` (with `devops-engineer` or `analytics-engineer` as appropriate) |

**Assessment algorithm**:
1. **Count domains**: Scan the description for keywords across all 6 domains. Count how many distinct domains have ≥ 1 match.
2. **Estimate stories**:
   - If the description mentions "epic" or lists 2+ distinct features → estimate ≥ 3 stories
   - If "and" connects 2+ features → estimate 2 stories
   - Otherwise → estimate 1 story
3. **Flag for opus-tier consultation**: If the description contains architecture
   keywords (architect, database, network, security, performance,
   scaling, migration, refactor, rewrite), treat as **Complex** even
   if domain count is ≤ 2 — these require `technical-director` (opus) review.
4. **Route**:
   - If `domains ≤ 2` AND `estimated_stories ≤ 3` → **Simple** → proceed to Phase 3 (Implementation Decision)
   - If `domains > 2` OR `estimated_stories > 3` → **Complex** → proceed to Phase 3 (Implementation Decision)

---

## Phase 3: Implementation Decision

After validity and complexity are assessed, perform a **lightweight
breakdown** (haiku tier, single agent) to produce concrete epics/stories
with acceptance criteria — enough for sprint planning without full
implementation delegation.

Then present the **timing decision** to the user. They now know:
- Whether the request is VALID / NEEDS CLARIFICATION / BLOCKED
- The complexity tier (Simple or Complex) and estimated story count
- The routing path (Direct Delegation → [agent] or Producer Delegation)
- **Concrete epics/stories** with acceptance criteria

**Flow**: Phase 4+ (Delegation → Review → Verify → Output) runs **only if
the user selects `[A] Handle now`**. Options `[B]` and `[C]` are terminal.

**Present the options** (using `AskUserQuestion`/`clarify`):

> The feature request has been assessed and broken down:
> - **Validity**: [VALID / NEEDS CLARIFICATION / BLOCKED]
> - **Complexity**: [Simple (→ [dominant agent]) / Complex (→ producer)]
> - **Epics/Stories**: [list with acceptance criteria]
>
> How would you like to proceed?
> - `[A] Handle now` — proceed immediately to implementation. A PR will be
>   created at the end of development once all acceptance criteria are met.
> - `[B] Add to current sprint` — schedule these stories into the current
>   sprint for the next planning cycle.
> - `[C] Add to later sprint` — defer these stories to a future sprint backlog.

**If the user selects `[A] Handle now`**:
- Proceed to **Phase 4A (Direct Delegation)** for Simple requests or **Phase 4B (Producer Delegation)** for Complex requests. Delegate to the responsible domain agent(s) to begin work on the stories.
- **Ensure a PR is created at the end of development.** This is the final
  deliverable gate — do not declare the feature complete until the PR is opened
  against the correct base branch and all acceptance criteria are satisfied.
  Follow the PR template at `.github/PULL_REQUEST_TEMPLATE.md`.
- Route through the standard pipeline: implement → review (lean or full per the
  resolved review mode) → PR → verify CI passes → merge.

**If the user selects `[B] Add to current sprint`**:
- Delegate to `/sprint-plan` with the epics/stories from this breakdown to
  schedule them into the current sprint.
- The feature remains in the sprint backlog until the next development cycle.
- **STOP** — do not proceed to Phase 4+. The lightweight breakdown is sufficient
  for sprint planning; full delegation happens when the sprint starts.

**If the user selects `[C] Add to later sprint`**:
- Record the epics/stories in the project backlog for future sprint planning.
- No immediate implementation is triggered.
- **STOP** — do not proceed to Phase 4+. The feature is deferred; full
  delegation occurs when the sprint is planned.

---

## Phase 4A: Direct Delegation (Simple Route)

Spawn the domain agent for the **dominant** (highest keyword match count) domain
via `delegate_task` with context:

> "A simple feature request has been submitted. This is a single-domain
> request (scope does not require cross-department coordination).
>
> **Feature Request**: [paste entire description]
>
> **Your task**: Apply the relevant domain expertise to this request.
> Review project context: `production/stage.txt`, `production/sprints/`,
> `request.md`, and `docs/architecture/apps/[app]/`. Review mode: [resolved mode].
>
> Produce:
> 1. A breakdown into concrete, assignable tasks (with acceptance criteria)
> 2. Any questions for the user (use AskUserQuestion/clarify if needed)
> 3. Identification of any cross-domain concerns that would warrant
>    escalation to the producer for complex coordination
>
> Spawn subagents only if the work genuinely spans sub-domains within your
> expertise. Do NOT delegate across to other domain leads unless you
> identify cross-domain concerns.
>
> **Do NOT invoke `producer`, `product-director`, or `technical-director`**
> (all opus tier). Only use sonnet-tier domain agents within your expertise.
> If you identify cross-domain concerns, surface them for the user to decide
> whether to re-route to the producer."

**Wait for results**. Then proceed to Phase 5A (Review Direct Delegation).

---

## Phase 4B: Producer Delegation (Complex Route)

Spawn `producer` via `delegate_task` with full context:

> "A complex feature request has been submitted that spans multiple domains.
> Handle it through the Producer-led 3-phase protocol:
>
> **Phase 1 — Digest & Breakdown**: Read the feature request below, clarify
> scope if needed (ask the user questions via AskUserQuestion/clarify), and
> decompose it into epics and stories with clear acceptance criteria.
> Consult `product-director` for request alignment and
> `technical-director` for feasibility assessment if the request touches
> architecture or platform constraints.
>
> **Model-tier guidance**: For all other subagent spawns, use sonnet-tier
> agents (`lead-engineer`, `qa-tester`, specialists, etc.). Only invoke
> opus-tier agents (`producer`, `product-director`, `technical-director`)
> when explicitly required by the request scope.
>
> **Phase 2 — Coordinate & Handle**: Assign tasks to responsible domain
> agents using the delegation map in `.claude/docs/agent-coordination-map.md`.
> Agents must NOT begin until assigned with defined scope and acceptance
> criteria. Spawn subagents (`lead-engineer`, `qa-tester`, etc.) as
> needed within your iteration budget.
>
> **Phase 3 — Verify**: Validate that all acceptance criteria are met and
> sign off. If you are unavailable or blocked, escalate to `product-director`
> as interim coordinator for this feature request.
>
> **Escalation rule**: If producer is unavailable, `product-director`
> handles features, `technical-director` handles bugs.
>
> **Feature Request**: [paste entire feature description argument]
>
> **Project context**: Read `production/stage.txt` for current phase,
> `production/sprints/` for current sprint context, and
> `request.md` for the master request. Review mode: [resolved mode].
>
> Report back with:
> 1. The decomposed epics/stories with acceptance criteria
> 2. The domain agents assigned to each task
> 3. The verification verdict (APPROVED / CONCERNS / BLOCKED)
> 4. Next steps for implementation"

Wait for the producer's full report. The producer may spawn its own subagents
(`qa-tester`, specialists, etc.) — that is expected.

Then proceed to Phase 5B (Review Producer Delegation).

---

## Phase 5A: Review Direct Delegation

Review the domain agent's response:

- **If the agent produced a task breakdown** with acceptance criteria: confirm
  the tasks are clear and actionable.
- **If the agent identified cross-domain concerns** that warrant producer-level
  coordination: surface to the user:
  - `[A] Re-route to producer — this needs cross-domain coordination`
  - `[B] Proceed with direct delegation — I'll handle the cross-domain parts myself`
- **If the agent raised CONCERNS** about scope/feasibility: surface via
  `AskUserQuestion`/`clarify`:
  - `[A] Address the concerns — adjust the feature description`
  - `[B] Proceed anyway — I accept the risk`

---

## Phase 5B: Review Producer Delegation

Review the producer's response (Complex route only):

- **If the producer decomposed the request** and assigned tasks: confirm the
  assignment list and acceptance criteria are clear.
- **If the producer returned CONCERNS**: surface them via `AskUserQuestion`/
  `clarify`:
  - `[A] Proceed with adjustments — apply the producer's recommendations`
  - `[B] Revise scope — I'll adjust the feature description and re-run`
  - `[C] Escalate to product-director — let the director make the call`
- **If the producer returned BLOCKED**: report the blockers, surface the
  producer's recommended next actions, and present:
  - `[A] Address blockers first, then re-run /feature-request`
  - `[B] Cancel — defer this feature`
- **If the producer escalated to product-director** (producer unavailable):
  note the interim coordinator and present their recommendation.

---

## Phase 6: Verify

**For Direct Delegation (Simple)**: The domain agent has provided a task
breakdown with acceptance criteria. Present the breakdown to the user and
ask them to confirm the acceptance criteria are understood and acceptable
before proceeding to implementation.

**For Producer Delegation (Complex)**: Review the producer's verification
report. The producer validates that all acceptance criteria are met.

- **APPROVED**: All acceptance criteria met. Present the producer's sign-off.
- **CONCERNS**: Surface to user with options to resolve or accept.
- **BLOCKED**: Explain what remains and recommend next steps.

---

## Phase 7: Output

Present a concise summary:

```markdown
## Feature Request Processed

**Request**: [feature description]
**Validity**: [VALID / NEEDS CLARIFICATION / BLOCKED]
**Routing**: [Direct Delegation → [agent name] / Producer-led → producer]
**Verdict**: [APPROVED / CONCERNS / BLOCKED]

**Epics/Stories**:
- [Epic: ...] → [N] stories, acceptance criteria: [...]
- [Epic: ...] → [N] stories, acceptance criteria: [...]

**Domain agents involved**: [list of agents spawned]
**Verification**: [summary of acceptance criteria validation]
**Escalation path**: [producer / product-director (interim) / direct]
```

Verdict: **COMPLETE** — feature request has been processed; epics/stories
and acceptance criteria are defined and assigned.

Verdict: **BLOCKED** — [reason]. Recommended: [resolve blocker] and re-run.

Verdict: **UPGRADED** — a simple request was identified as needing cross-domain
coordination. Re-run `/feature-request` to route through the producer.

---

## Next Steps

- `/create-epics` — if epics were identified that need formal epic files
- `/create-stories [epic-slug]` — to break epics into implementable story files
- `/sprint-plan new` — to schedule stories into a sprint (use when the user
  chose `[B] current sprint` or `[C] later sprint`)
- `/scope-check` — to verify no scope creep against the original intent
- To ship a feature handled now: open a PR against the base branch following
  `.github/PULL_REQUEST_TEMPLATE.md` once acceptance criteria are met
- Re-run `/feature-request` with clarifications if validity was NEEDS CLARIFICATION
