---
name: app-icon-forge
description: "Design a Shopify app icon from concept to production PNG set: discovery, 3-4 concepts, SVG, feedback loop, and export at 1200x1200 listing, favicon, and social sizes. Feeds the app-store-listing media section."
argument-hint: "[app-slug]"
user-invocable: true
allowed-tools: Read, Glob, Write, Edit, Bash
model: sonnet
---

> **Explicit invocation only**: run this skill when the user asks for
> `/app-icon-forge`, or when `/app-page-materials` reaches the icon asset.

## Phase 1: Parse Arguments

- `app` — the slug from `docs/registry/apps.json`; default to the app named in
  `request.md` or the most recently modified `production/apps/<app>/session-state/active.md`

Read the app name and any brand color from `apps/<app>/README.md` and
`apps/<app>/shopify.app.toml`. If the app name is missing, ask for it.

---

## Phase 2: Discovery

Ask 3-4 short questions in one message, numbered. Skip any the request already
answered.

1. **App name** (required)
2. **What the app does** — one sentence
3. **Brand colors** — hex, descriptive words, or "no preference"
4. **Preferred style** — Minimal geometric, Lettermark, Abstract symbol, Badge,
   Monoline, or "You pick"

"You pick" and "no preference" are complete answers. Pick a direction yourself
and move on; do not re-ask in a different form.

---

## Phase 3: Concepts (words only)

Present 3-4 distinct concepts. Each is a short name, a one-sentence visual
description, and a one-sentence rationale tied to the app's meaning. No SVG in
this phase.

Apply these constraints silently (surface them only if asked):

- Readable at 64x64 px — the Shopify admin renders the icon small
- Single focal element, at most two colors
- Works on both light and dark admin backgrounds
- Memorable silhouette at 32 px
- Avoid clichés: gears, shopping carts, dollar signs, generic checkmarks, boxes
  with arrows, magnifying glasses, lightning bolts, clouds, and circular
  refresh/sync arrows

Ask which concept to take forward. Do not draw yet.

---

## Phase 4: SVG

Produce a clean SVG for the chosen concept:

- `viewBox="0 0 200 200"`
- No embedded fonts — convert lettermarks to paths
- Clean paths, whole numbers or halves, no auto-generated noise
- No external references, no CSS imports
- Stroke or fill, not both on one element

Emit the SVG in a ```svg block, label it **v1**, and say one line about what you
chose and why.

---

## Phase 5: Feedback Loop

Ask "What would you change?" Re-render the full updated SVG each round, starting
the reply with the version and a one-line changelog (`**v2** — ...`). If you hit
v6+ without convergence, say so and offer to return to Phase 3.

Do not export until the user explicitly approves ("looks good", "ship it",
"that's the one").

---

## Phase 6: Export

Ask: "May I write the SVG and PNG exports to `apps/<app>/design/icon/`?" Write on approval.

1. Save the approved SVG to `apps/<app>/design/icon/icon-final.svg`.
2. Ensure `sharp` is available:

   ```bash
   node -e "require('sharp')" 2>&1
   ```

   If it errors, install it: `npm install sharp` (or `pnpm add sharp` when the
   app uses pnpm).

3. Run the exporter:

   ```bash
   node .claude/skills/app-icon-forge/scripts/export-icon.mjs \
     apps/<app>/design/icon/icon-final.svg \
     --brand-color "<HEX>" \
     --out apps/<app>/design/icon/exports
   ```

4. Report every written path. The script writes:

   - `shopify-listing-1200.png` — 1200x1200, transparent
   - `app-store-1024.png`, `app-store-512.png` — transparent
   - `favicon-64.png`, `favicon-32.png`
   - `social-1200x630.png` — icon centered on the brand color

If `sharp` fails to install or the script errors, surface the error and stop.

---

## Ownership

Owned by **app-store-reviewer** (listing asset sign-off). `ux-lead` reviews the
mark for merchant recognition. The exported 1200x1200 is recorded in the
`app-store-listing.md` media section.

---

## Rules

- **The listing icon is 1200x1200**, JPEG or PNG, square with padding. Shopify
  rounds the corners — do not draw a rounded square.
- **No text, no screenshots, no Shopify trademarks** in the icon.
- **Never copy another brand's mark.** Distinctive silhouette, not a generic
  category glyph.
- **The SVG is the source of truth.** PNGs are derived; re-export after any SVG
  change rather than editing a PNG.

---

## Verification

- `shopify-listing-1200.png` is exactly 1200x1200.
- The mark is still recognizable when scaled to 32x32.
- The icon reads on both a light and a dark background.
- Verdict: `complete` when the 1200x1200 PNG exists and the mark reads at 32x32; otherwise `incomplete`.

---

## Next Steps

- `/app-page-materials [app]` — record the icon in the listing media section
- `/app-screenshot-capture [app]` — the remaining static media
- `/app-demo-video [app]` — promo video and review screencast

Reference: `.claude/skills/app-icon-forge/references/icon-design-principles.md`
