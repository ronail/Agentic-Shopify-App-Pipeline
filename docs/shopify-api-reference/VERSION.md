# Shopify API Version

**Pinned version: `2026-10`**

| Field             | Value                                  |
| ----------------- | -------------------------------------- |
| Status            | Latest stable                          |
| Release date      | 2026-10-01                             |
| Supported until   | 2027-10-16                             |
| Cadence           | Quarterly (Shopify releases a new stable version every 3 months; each stays supported for ~12 months) |

## Rules

- **Apps pin this in `apps/<app>/shopify.app.toml`.** The version in that file
  is what Shopify uses for the app's Admin GraphQL calls, webhook payloads and
  extension APIs. This document is the human-readable record of that pin.
- **Never edit an older snapshot in place.** When the pin moves, copy the
  current `<version>/` directory to the new version name, update it, and add the
  new row here. Historical notes stay as written so an older app build can
  still be reasoned about.
- No API work starts from memory. Check `2026-10/` in this directory first; if a
  detail is missing, go to https://shopify.dev/docs/api and add it here.

## Upgrading

1. Read the release notes for the new version and the previous one's
   "breaking changes" / "deprecated" lists.
2. Diff them against `<old-version>/` and write the new `<new-version>/` snapshot.
3. Update this file, then the `api_version` in each app's `shopify.app.toml`.
4. Test against a development store before shipping.
