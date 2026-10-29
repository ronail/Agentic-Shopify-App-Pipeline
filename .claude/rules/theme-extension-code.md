---
paths:
  - "apps/**"
---

# Theme App Extension Rules

- Owner agent: `liquid-specialist` — Liquid, theme app extensions, and app blocks
- Extensions live under `apps/<app>/extensions/<name>/` and are registered in the app config, not created ad hoc
- Expose behaviour as an app block with merchant-editable settings in the block schema; never require a theme code edit
- Liquid stays presentation-only: no API calls, no business math that also exists server-side
- Every setting block declares `id`, `type`, `label`, and a sensible `default`; limits are validated in the block schema
- Escape every merchant value (`escape`) and never trust metafield content as markup
- App block markup inherits theme styles, includes no global CSS overrides, and is keyboard/screen-reader accessible
- Test on a real dev-store theme across the app's supported block schema versions before release
