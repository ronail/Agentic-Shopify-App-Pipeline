# Skill Test Spec: /propose-updates

> **Category**: authoring  
> **Priority**: medium  
> **Spec written**: 2026-10-29

## Skill Summary

Turns observed pipeline friction into written proposals for changes to agents, skills, rules or hooks, with evidence and a risk note, parked for ratification. Use after a task that fought the framework, a repeated workaround, or a retro. Writes proposals only, never applies them.

- **Invocation**: `/propose-updates` [area, e.g. 'skills' or 'gate-3-scope' or blank to scan recent work]
- **Owner**: no `agent:` frontmatter — runs in the calling context
- **Write access**: yes (`Read, Glob, Grep, Write, Edit, Bash`) — every write needs explicit approval
- **Terminal state**: artifact produced (no verdict token by design)

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (skill has 7 `##` sections: “Purpose”, “When to use”, “Inputs”, “Steps”, “Outputs”…)
- [ ] N/A — artifact-producing skill: no verdict keyword by design; success is the artifact existing with its required sections
- [ ] Write approval gate present — the skill requires “Ask before writing if the proposals folder does not exist.” before writing
- [ ] Next-step handoff section present at end — **GAP**: no explicit next-step section

---

## Director Gate Checks

N/A — this skill produces evidence or artifacts that feed a gate but never records one. It must not write gate approvals or change an app's `stage`.

- **Full mode**: no director fan-out driven by this skill; no gate is recorded by this skill
- **Lean mode**: identical behaviour; a missing artifact is still a failure, not a warning
- **Solo mode**: runs unattended — verdict must remain evidence-backed, never softened

---

## Test Cases

### Case 1: Happy Path — Name the friction as an observation, not a solution. One sentence:…

**Fixture** (assumed project state):
- production/session-state/ — What was actually worked on
- .claude/skills/*/SKILL.md — Current skill bodies and their stated paths
- .claude/agents/*.md — Ownership and tool grants
- `docs/registry/apps.json` resolves the app slug
- present but optional: docs/registry/apps.json

**Input:** `/propose-updates` [area, e.g. 'skills' or 'gate-3-scope' or blank to scan recent work]

**Expected behavior**:
1. **Name the friction as an observation, not a solution.** One sentence: "The `/release` flow asks for a file that no skill creates." Solutions come later; a proposal that starts with a solution hides its own evidence.
2. **Attach evidence.** The file path and line, the command output, or the session where it happened. A proposal with no evidence is an opinion, and opinions do not get ratified.
3. **Classify the fix**: `missing-file` (a skill assumes a path nothing produces), `ownership-overlap` (two agents claim one decision), `stale-path` (a referenced path no longer exists), `tool-grant` (an agent needs a tool it lacks), `wording` (instructions…
4. **Propose the minimal change.** One target file, one edit shape. If the fix needs three files, the friction is probably misdiagnosed — say which part you are unsure about.
5. **State the blast radius.** Which agents and skills read the target, and what would break if the change is wrong. Anything touching a gate or an approval record is `high` risk and needs a named reviewer.

**Assertions**:
- [ ] Every `yes`-required input from the Inputs table is read before judging; a missing one is reported, not assumed
- [ ] Produces the documented output (`production/proposals/<id>.md`)
- [ ] Every claim carries an evidence path or a number — bare "looks fine" assertions are rejected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Evidence or discard. No cited path or output, no proposal.

**Fixture**:
- The skill's unconditional rule is violated: **Evidence or discard.** No cited path or output, no proposal.
- No write has been approved

**Expected behavior**:
1. The violated precondition is detected before any finding is produced.
2. The documented blocked/failure state is reported, naming the missing artifact or record.
3. The skill stops and writes nothing.

**Assertions**:
- [ ] Skill reports the block explicitly instead of producing a partial recommendation
- [ ] The message names the specific path or record that failed, not a generic error
- [ ] Skill stops early and does not produce output that pretends the work succeeded
- [ ] No files written without user approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Invocation Variant — argument supplied vs. resolved from disk

**Fixture**:
- Standard project state for this skill
- Invocation omits the argument (`/propose-updates`)

**Expected behavior**:
1. The target is resolved from registry/state files, never guessed from the app name.
2. If the target is ambiguous, the skill asks instead of picking.

**Assertions**:
- [ ] No argument → target resolved from disk state and stated in the output
- [ ] Ambiguous target → question asked; no writes, no silent default

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Edge Case — One change per proposal. Bundled changes cannot be…

**Fixture**:
- Boundary condition from the skill's own rules: **One change per proposal.** Bundled changes cannot be ratified or reverted independently.

**Expected behavior**:
1. The skill applies its documented rule instead of overwriting or repeating work.
2. The conflict is surfaced to the user with what was found and what the skill did.

**Assertions**:
- [ ] Prior state is either preserved or explicitly superseded with a reason — never silently rewritten
- [ ] Edge case handled without crash or silent failure
- [ ] Output states the resolution so a later reader can reproduce it

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Director Gate — approval boundary

**Fixture**:
- A run that reaches the terminal state
- Review mode: full / lean / solo

**Expected behavior**:
1. No director gate is spawned and no gate approval is written.
2. The handoff names the next skill/agent explicitly.
3. In solo mode the skill still refuses to mark work approved on its own authority.

**Assertions**:
- [ ] In full mode: no gate recorded, and no stage advanced, without an explicit approval in the transcript
- [ ] In lean mode: identical behaviour — no silent auto-advance
- [ ] In solo mode: no director gates spawn and no gate entry is written
- [ ] A CONCERNS or FAIL verdict is never auto-advanced past

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses the skill's documented approval gate before writes: “Ask before writing if the proposals folder does not exist.”
- [ ] Presents findings/draft to the user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Cases are written against the current `SKILL.md` (8 numbered steps, 4 rules, 4 declared inputs, 7 `##` sections).
- The body states no verdict keyword; terminal state must be read from the Output section. Verify the static assertion above before running the cases — it is a real finding, not a formatting artefact.
- Anything depending on live Shopify behaviour (webhook delivery, billing state, granted scopes, Admin API limits) needs a run against a real test store — document fixtures cannot prove it.
