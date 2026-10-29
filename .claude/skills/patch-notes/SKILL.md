---
name: patch-notes
description: "Use when writing merchant-facing release notes. Translates an app's changelog entry into plain-language notes a Shopify merchant understands — what changed, what it means for their store, and what they must do — with no internal jargon."
argument-hint: "[app] [version] [--style brief|detailed|full]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash
model: haiku
agent: community-manager
---

# Patch Notes

Produces the notes a **merchant** reads: what changed in their app, what it means for
their store, and whether they need to do anything. The engineering record lives in
`apps/<app>/CHANGELOG.md`; this skill is the translation layer on top of it.

A merchant runs a business, not a build pipeline. If a sentence only makes sense to
someone who has read the code, it does not belong in these notes.

---

## Phase 1: Parse Arguments

- `app` — slug from `docs/registry/apps.json`; default to the app named in `request.md`
- `version` — the release to write notes for; ask if absent
- `--style` — `brief` (bullets only), `detailed` (default: context per change), `full`
  (adds a short note from the team on the biggest change)

---

## Phase 2: Gather Source Material

- `apps/<app>/CHANGELOG.md` — the `[version]` entry is the primary source
- `production/apps/<app>/patch-notes-<version>.md` — an existing draft, if any
- Sprint records in `production/apps/<app>/sprints/` — why the work happened
- `request.md` and the app-local request history — merchant-reported problems already known
- `git log` between the previous and current tag, scoped to `apps/<app>/`, as a fallback

**If there is no changelog entry and no git range for `[version]`:**

> "No changelog data found for [version]. Run `/changelog [app] [version]` first, then
> re-run `/patch-notes [app] [version]`."

Verdict: **BLOCKED** — stop without generating notes.

---

## Phase 2b: Detect Tone and Template

**Tone**, in this order:

1. `apps/<app>/docs/tone-guide.md`
2. Any tone/voice/style section in `.claude/docs/technical-preferences.md`
3. `docs/PATCH-NOTES-STYLE.md`
4. Default: plain, calm, specific. No exclamation marks, no marketing adjectives, no
   "we're thrilled".

**Template**: Glob `apps/<app>/docs/patch-notes-template.md`, then
`.claude/docs/templates/release-notes.md`. If one exists, follow its section order
instead of the built-in styles and fill it from the categorized changes. Where a
template section has nothing merchant-visible to say, drop the section rather than
inventing content for it.

---

## Phase 3: Categorize and Translate

Categories, merchant-facing:

- **New** — a capability the merchant did not have before
- **Improved** — an existing flow got faster, clearer, or more reliable
- **Fixed** — something was broken and now is not
- **Pricing or plan changes** — anything that changes what they pay or can access
- **Action required** — reinstall, re-authorise, update a setting, update their theme
- **Known issues** — honest statement plus a workaround where one exists

Translation rules:

- Describe the **effect on the store**, not the mechanism
- Drop anything with no merchant-visible effect
- Keep concrete numbers when they are the point (limits, timings, plan prices)
- Name the surface the merchant knows: "the Bundles page", "your product page",
  "checkout" — never module or file names
- Anything that breaks an existing setup is a headline, not a footnote

| Internal phrasing | Merchant phrasing |
|---|---|
| "Dedupe webhook deliveries by event ID" | "Duplicate order updates no longer create duplicate tags" |
| "Migrated to Admin API [version]" | "Updated to Shopify's current API so syncs keep working reliably" |
| "Added pagination at 100 per page" | "Large catalogs now load in a single pass instead of timing out" |
| "Server-side billing gating" | "Plan access is now checked on every action, so features can't be used outside your plan" |
| "Refactored discount service" | *(no line — nothing changed for the merchant)* |

---

## Phase 4: Generate the Notes

### Brief
```markdown
# [App] [version] — [short title]

**New**
- [what they can now do]

**Improved**
- [what got better, with the merchant-visible effect]

**Fixed**
- [what used to go wrong; what happens now]

**Action required**
- [step, or omit the section entirely]
```

### Detailed (default)
```markdown
# [App] [version] — [short title]
*[date]*

## What's new
[Two sentences: the main change and what it means for their store.]

## New
### [Capability]
[What it does, where to find it, and one sentence on when to use it.]

## Improved
- **[Area]**: [before → after, in merchant terms]

## Fixed
- [What used to go wrong]. [What happens now.]

## Pricing and plans
- [Only if something changed; state old and new explicitly.]

## Action required
- [Exactly what to do and where. Omit the section if nothing is required.]

## Known issues
- [Issue in merchant terms] — [workaround, or "we're working on it".]
```

### Full
Everything in Detailed, plus:
```markdown
## A note from the team
> [2–3 sentences in first-person team voice on the biggest change: why it was made,
> what merchants asked for, what is coming next. No internal detail.]
```

Also produce a **short form** for in-app banners or update emails: one sentence plus,
if needed, one action line. Under 300 characters.

---

## Phase 5: Review the Draft

Reject the draft and rewrite if any of these is true:

- A sentence names an internal component, ticket, sprint, branch, or log message
- A fix describes the cause instead of the symptom the merchant saw
- "Improved performance" appears without saying what the merchant will notice
- Something that requires merchant action is buried below the fold
- A claim cannot be traced to a changelog entry
- Tone drifted into marketing ("revolutionary", "industry-first", "seamless")

---

## Phase 6: Save

Present the notes with: counts per category, the short form, and the list of internal
changes deliberately excluded.

Ask: "May I write these to `production/apps/<app>/patch-notes-<version>.md`?" On
approval, write the file, creating the directory if needed.

If a draft already exists at that path, show the diff and ask before replacing it.

Verdict: **COMPLETE** — patch notes written.

---

## Phase 7: Next Steps

- `/release-checklist [app] --version [version]` — confirm nothing else blocks submission
- `/release [app] [version]` — publish the release the notes describe
- Have `community-manager` read the final text for tone before it goes to merchants

---

## Rules

- Never invent a change that is not in the changelog or the commit range
- Never promise a date, a roadmap item, or a fix "coming soon" unless it is written down
  in the sprint record
- Pricing copy must match live billing configuration exactly; verify before writing
- If the release contains nothing a merchant would notice, say so plainly and ship a
  two-line note — an inflating release note damages trust faster than a short one
