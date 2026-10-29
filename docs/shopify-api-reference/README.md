# Shopify API Reference

Version-pinned snapshots of the Shopify APIs this pipeline builds against.
**Always check here before using any Shopify API** — the pinned version is the
contract; training data is older and Shopify ships quarterly.

## Layout

```
docs/shopify-api-reference/
  VERSION.md          the pinned version for this repo (read this first)
  <version>/          one directory per pinned API version, e.g. 2026-10/
    README.md         index of the surfaces below
    admin-graphql.md
    webhooks.md
    billing.md
    checkout-extensions.md
    storefront.md
```

Each `<version>/` directory is an immutable snapshot: the surface notes for one
quarterly release. Never edit an older snapshot in place — add a new version
directory and repoint `VERSION.md` (see the rule in `VERSION.md`).

## Pinned version

Current pin: **2026-10** — [VERSION.md](VERSION.md), notes in
[2026-10/](2026-10/README.md).

## Adding a new version

1. Copy the newest `<version>/` directory to the new version name.
2. Update the notes against https://shopify.dev/docs/api (release notes +
   changelog) and delete anything that no longer applies.
3. Update `VERSION.md`.
4. Bump the version in `apps/<app>/shopify.app.toml`.
