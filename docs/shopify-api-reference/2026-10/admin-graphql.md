# Admin GraphQL API — 2026-10

## Endpoint

Version is part of the URL path, not a header:

```
POST https://{shop}.myshopify.com/admin/api/2026-10/graphql.json
```

- Auth: `X-Shopify-Access-Token: {access_token}` (offline/online token from OAuth).
- Body: `{"query": "...", "variables": {...}}`.
- Always pin the literal version string in code/config; never rely on the
  unversioned `.../admin/api/graphql.json` alias, which follows whatever Shopify
  currently considers stable and will silently move under the app.

## Cost-based throttling

Every query has a computed cost before it runs; the response carries the real
numbers in `extensions.cost`:

```graphql
{
  "extensions": {
    "cost": {
      "requestedQueryCost": 0,
      "actualQueryCost": 0,
      "throttleStatus": {
        "maximumAvailable": 0,
        "currentlyAvailable": 0,
        "restoreRate": 0
      }
    }
  }
}
```

Rules that matter for implementation:

- Bucket is a leaky bucket: capacity and restore rate are per shop (higher on
  Plus plans). Read `maximumAvailable` / `restoreRate` from the response rather
  than hard-coding a plan's numbers.
- Cost scales with the requested connections and their `first:`/`last:` values
  and nesting depth, not with returned rows. Cheap fix for expensive queries:
  lower page sizes, request fewer nested connections, split into several small
  queries.
- On throttle, Shopify returns a `THROTTLED` error in the top-level `errors`
  array (HTTP 200 typically). Back off using `currentlyAvailable` /
  `restoreRate`; do not retry in a tight loop.
- Prefer one query with an alias block over N sequential queries for the same
  root field, but keep the total cost under budget.

Confirm current numbers and error shapes at
https://shopify.dev/docs/api/admin-graphql/2026-10 (see the "Rate limits" /
"GraphQL" guide pages) before tuning a throttle.

## Bulk operations

For anything above ~250 records, use bulk operations instead of paging.

- Read: `bulkOperationRunQuery(query: "...") { bulkOperation { id status } }`,
  then poll `currentBulkOperation` (status `CREATED`/`RUNNING`/`COMPLETED`/
  `FAILED`). Result is a JSONL file at `url` — one object per line, children
  linked by `__parentId` instead of nested objects.
- Write: `bulkOperationRunMutation` with a staged upload JSONL file; needs an
  upload path (`stagedUploadsCreate`) first.
- One bulk operation of each kind can run per shop at a time; a second request
  while one is active fails. Treat it as a queue per shop.
- The result URL expires — download and persist promptly, stream the JSONL
  rather than loading it whole.

Exact mutation signatures and statuses:
https://shopify.dev/docs/api/admin-graphql/2026-10 (BulkOperation / bulkOperationRunQuery).
