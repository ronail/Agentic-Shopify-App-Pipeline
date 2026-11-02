# Icon Design Principles

Read this when a concept batch was rejected twice, when generating a lettermark,
or when checking a mark against the cliché list.

## Size ramp

The icon is rendered at 1200x1200 on the listing, ~64 px in the Shopify admin
nav, and 32 px in a favicon. Design for the smallest size first: if the mark
needs fine detail to read, it fails.

## Structure

- **One focal element.** Two focal points split attention at thumbnail size.
- **At most two colors.** More starts to read as a sticker.
- **Solid background or transparent**, never a photographic scene.
- **Padding.** Leave roughly 10% clear on each edge; Shopify rounds the corners
  automatically, so do not draw the rounding.

## Contrast

The mark appears on light and dark admin themes. A pure black mark disappears on
dark; a pure white mark disappears on light. If the concept depends on a
background, ship a two-tone variant.

## Negative space

Test the silhouette by filling the mark solid black. If it becomes a blob, the
form is too complex. The gap between strokes should stay legible at 32 px.

## Cliché list

Do not propose: gears, shopping carts, dollar signs, generic checkmarks, boxes
with arrows, magnifying glasses, lightning bolts, clouds, and circular or
cycling arrows (the default for sync, refresh, reorder, and inventory apps).

## Lettermark rules

- Convert text to paths; never rely on `font-family`.
- One or two letters maximum.
- Match stroke weight to the container; a hairline letter vanishes at 32 px.
- Optically center the glyph, not the bounding box.

## Anti-patterns

- Gradients that only read at 1200 px
- Drop shadows that muddy the silhouette
- Copying a category leader's mark with a color swap
- Detail that requires the 1200 px render to explain
