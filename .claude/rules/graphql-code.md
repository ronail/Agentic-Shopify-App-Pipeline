---
paths:
  - "apps/**"
---

# GraphQL Operation Rules

- Owner agent: `graphql-specialist` — cost-based throttling, pagination, bulk operations, and error handling
- One operation per file, named in PascalCase after the file (`DiscountCreate.graphql`); variables typed by an explicit interface
- Request only the fields the feature consumes; add nested connections only with a measured cost in mind
- Read `extensions.cost` and the throttle status on every response; stay under 50% of the bucket per burst and back off before exhaustion
- No single query above 500 requested cost — switch to a bulk operation instead
- Paginate with cursors (`after`/`hasNextPage`/`endCursor`) and loop until `hasNextPage` is false; never assume page one is everything
- Check `userErrors` on every mutation and surface them as actionable merchant-facing messages, not raw payloads
- Bulk operations: poll the operation status with backoff, stream the JSONL result, and record the URL before processing
