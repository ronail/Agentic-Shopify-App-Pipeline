---
name: app-screenshot-capture
description: "Capture the 3-6 unique 1600x900 App Store screenshots from a deployed Shopify app build: plan the screens, drive the browser, crop browser chrome, verify dimensions, and record a caption manifest."
argument-hint: "[app-slug]"
user-invocable: true
allowed-tools: Read, Glob, Write, Edit, Bash
model: sonnet
---

> **Explicit invocation only**: run this skill when the user asks for
> `/app-screenshot-capture`, or when `/app-page-materials` reaches the
> screenshots asset.

## Purpose

Screenshots are static images of the real merchant UI. They are not the video,
not the feature image, and not mock dashboards. This skill produces the 3-6
unique images the listing needs, at the size Shopify renders them.

## Prerequisites

- The app is deployed to a test store (`/deploy-to-test-store` completed).
- Playwright is available in the app project:

  ```bash
  node -e "require('playwright')" 2>&1
  ```

  If it errors, install it: `npm install -D playwright && npx playwright install chromium`.

## Steps

1. **Plan the screens.** Read `apps/<app>/README.md` and
   `production/apps/<app>/prototype-review.md`. Choose 3-6 screens that show the
   real value path:
   - the core payoff screen
   - a workflow step (onboarding, a key action, a result)
   - settings or configuration
   - optional additional views only if they add information

   Each screen must be a different view, not a variant of the last.

2. **Capture at 1600x900.** Drive the deployed build with Playwright at
   `viewport: { width: 1600, height: 900 }` and save a PNG per screen to
   `production/apps/<app>/assets/screenshots/`.

3. **Crop browser chrome.** Screenshots must show the app, not the browser
   frame. Capture the app viewport only; no tabs, URL bar, or OS chrome.

4. **Remove sensitive data.** No real customer PII, no real orders, no API keys.
   Use test-store data.

5. **No pricing.** Prices belong in the pricing section, not inside screenshots.

6. **Verify dimensions.** Every file is exactly 1600x900:

   ```bash
   node -e "const s=require('sharp'); for (const f of process.argv.slice(1)) s(f).metadata().then(m=>console.log(f, m.width+'x'+m.height))" production/apps/<app>/assets/screenshots/*.png
   ```

7. **Write the manifest.** Ask: "May I write the screenshots and manifest to
   `production/apps/<app>/assets/screenshots/`?" Write on approval. The manifest
   has one row per file — filename, screen shown, caption, and the requirement ID
   it demonstrates.

## Outputs

```
production/apps/<app>/assets/screenshots/
  screenshot-1.png ... screenshot-N.png   (1600x900 each)
  manifest.md
```

Verdict: `complete` when 3-6 unique 1600x900 files exist and every one is named in
the manifest; otherwise `incomplete`.

## Ownership

Owned by **ux-lead** (screen selection and fidelity). **app-store-reviewer**
signs off that the images match the shipped UI and the listing claims.

## Rules

- **Real screens only.** No mock dashboards, no placeholder values that mislead
  a reviewer about what the app does.
- **3-6 unique images.** At least one shows real merchant UI.
- **1600x900, 16:9.** No browser chrome, PII, pricing, or Shopify logos.
- **Screenshots are not video frames.** Do not reuse video stills or the feature
  image as a screenshot.

## Next Steps

- `/app-page-materials [app]` — record the screenshots in the listing
- `/app-demo-video [app]` — the video materials
- `/app-store-checklist [app]` — verify the listing assets
