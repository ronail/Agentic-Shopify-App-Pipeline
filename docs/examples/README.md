# Collaborative Session Examples

Realistic session transcripts for the Shopify app pipeline. Each one shows the
**collaborative pattern**: the agent asks, presents options, waits for your
decision, and only then writes files.

The apps in these examples are the two in this repo — `discount-bundles` and
`order-tags` — so the names, gates and story shapes match what you will actually
see.

> **Pattern in one line:** Question → Options → Decision → Draft → Approval.

---

## Available Examples

| Example | Stage | Skills exercised |
|---------|-------|------------------|
| [Research to scaffold](session-research-to-scaffold.md) | research → scaffold | `/research`, `/ux-design`, `/gate-check`, `/scaffold` |
| [Architecture decision](session-architecture-decision.md) | architecture | `/create-architecture`, `/architecture-decision`, `/create-control-manifest` |
| [Prototype gate](session-prototype-gate.md) | prototype | `/build-prototype`, `/prototype-review`, `/gate-check` |
| [Story from backlog to done](session-story-lifecycle.md) | scope → build → test | `/create-stories`, `/story-readiness`, `/dev-story`, `/code-review`, `/story-done` |
| [Release](session-release.md) | release | `/release-checklist`, `/app-store-checklist`, `/release`, `/changelog` |

---

## 1. Research to Scaffold

**Skill:** `/research` → `/ux-design` → `/gate-check` → `/scaffold`
**Agent:** `research-specialist`, then `ux-lead`, then `devops-engineer`
**Duration:** ~90 minutes across two sessions
**Complexity:** Medium

`/research` runs Original or Competitor-Killer research on `request.md` and ends
with a validated wedge, not a feature list. `/ux-design` authors three admin
screen specs before anything is built. `gate-1-research` records approval in
`apps/discount-bundles/approvals.json`; only then does `/scaffold` create the app.

**Key moments:** the competitor scan kills two of five candidate features; the
research brief names the merchant job in one sentence; the gate refuses to pass
because `approvals.json` has no entry yet.

---

## 2. Architecture Decision

**Skill:** `/architecture-decision` (then `/create-control-manifest`)
**Agent:** `app-architect`, reviewed by `checkout-specialist` and `technical-director`
**Duration:** ~45 minutes
**Complexity:** High

The team has to decide how a bundle becomes one cart line. Three options are
presented with real trade-offs (cart transform function, duplicated product,
discount code). The decision is written as `ADR-0001-bundle-cart-transform.md`
with a **Shopify API Surface** table and **App Requirements Addressed** IDs, then
the control manifest is regenerated from it.

**Key moments:** the ADR template forces a `Knowledge risk` rating; the review
catches that the metafield contract belongs in ADR-0002, not here; the control
manifest gains three Forbidden rules straight from the rejected alternatives.

---

## 3. Prototype Gate

**Skill:** `/build-prototype` → `/prototype-review` → `/gate-check gate-2-prototype`
**Agent:** `prototype-builder`, reviewed by `ux-lead` and `product-director`
**Duration:** ~2 days of builder time, 25 minutes of review
**Complexity:** Medium

The prototype is a real embedded admin route on a dev store — not a mockup. The
review judges it against the research wedge, not against the eventual product.
`gate-2-prototype` is the point where scope is allowed to be cut.

**Key moments:** the prototype exposes that the variant picker is the bottleneck;
the review distinguishes "prototype must prove this" from "nice later"; the gate
verdict is CONCERNS (passable) with one named risk.

---

## 4. Story from Backlog to Done

**Skill:** `/create-stories` → `/story-readiness` → `/dev-story` → `/code-review` → `/story-done`
**Agent:** `lead-engineer`, with `graphql-specialist` and `qa-lead`
**Duration:** ~60 minutes
**Complexity:** Medium

One story — "expand fixed-price bundles into component lines" — from acceptance
criteria to merged code. `/story-readiness` blocks it because the embedded
control-manifest version is stale. After the ADR is accepted and the manifest
regenerated, implementation runs test-first.

**Key moments:** readiness catches a stale manifest version before any code; the
requirement ID traces to `requirements.yaml`; `/code-review` flags a float money
calculation (a forbidden pattern) and the fix is a one-line integer change.

---

## 5. Release

**Skill:** `/release-checklist` → `/app-store-checklist` → `/release` → `/changelog`
**Agent:** `release-manager`, `app-store-reviewer`, `security-specialist`
**Duration:** ~90 minutes
**Complexity:** Medium-High

Submission is a checklist, not a vibe. Scopes are justified, the privacy policy
matches the actual data schema, the mandatory compliance webhooks are proven with
a real delivery, and the changelog entry names the requirement IDs.

**Key moments:** the checklist blocks on a missing `customers/redact` test; the
reviewer refuses listing copy that claims a feature the prototype never proved;
`gate-4-release` records the approval with a timestamp.

---

## How to use these

- **New to the system:** read one end-to-end example before your first session.
- **Unsure what to run next:** each example ends with the exact next skill.
- **Checking your own session:** if an agent skipped questions or wrote files
  without asking, point it at
  [COLLABORATIVE-DESIGN-PRINCIPLE.md](../COLLABORATIVE-DESIGN-PRINCIPLE.md).

## What good looks like

1. The agent reads `request.md`, the app's `status.md` and the pinned API
   snapshot before proposing anything.
2. It presents 2–4 options with trade-offs, referencing the merchant job and the
   app's requirement IDs — not generic best practice.
3. It shows the draft (ADR section, story, screen) before writing.
4. It asks "May I write to `<path>`?" once, listing every file it will touch.
5. On completion it names the next skill and the gate that will judge the work.

## Related

- [Collaborative Design Principle](../COLLABORATIVE-DESIGN-PRINCIPLE.md)
- [Workflow Guide](../WORKFLOW-GUIDE.md)
- [Agent Roster](../../.claude/docs/agent-roster.md)
- [Architecture registry](../registry/architecture.yaml)
