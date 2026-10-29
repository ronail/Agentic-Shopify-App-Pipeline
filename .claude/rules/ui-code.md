---
paths:
  - "apps/**"
---

# Admin UI Code Rules (Polaris / App Bridge)

- Use Polaris components before writing custom markup; custom CSS only when no primitive covers the case and only with Polaris design tokens, never raw hex
- Build with App Bridge context (`useAppBridge`, shop, host, locale); never parse the query string for shop or host yourself
- Every Admin API call goes through a route loader/action — components never call Shopify APIs directly from the browser
- Function components and hooks only; one route module per admin page (`app/routes/app.<page>.tsx`)
- Required states on every data surface: loading (Skeleton), empty (EmptyState with a next action), error (Banner with a retry)
- Every interactive control is keyboard reachable, labelled for screen readers, and meets WCAG 2.1 AA contrast
- Merchant-visible copy and limits come from config or a translation source, never hardcoded in the component
- Perceived load for an admin route stays under 1.5 s p75 — lazy-load heavy panels, keep the initial bundle under 250 KB gzipped
