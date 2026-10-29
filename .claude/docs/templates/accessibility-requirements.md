# Accessibility Requirements: [App Name]

> **App**: `apps/<app>` · **Version**: [x.y.z] · **Last audited**: [Date]
> **Baseline**: WCAG 2.2 Level AA, plus the Shopify admin's own conventions
> (Polaris components, admin focus behaviour, screen-reader expectations).
> **Owner**: accessibility-specialist / ux-lead

---

## Accessibility Tier Definition

### Tier Definitions

| Tier | Commitment | Applies to |
|------|------------|-----------|
| **Basic** | Keyboard reachable, visible focus, labelled controls, no colour-only meaning | Every screen, minimum |
| **Standard** | Basic + WCAG 2.2 AA (contrast, reflow, errors identified, target size), screen-reader pass on primary tasks | Default for app-store apps |
| **Comprehensive** | Standard + reduced motion, zoom to 200% without loss, screen-reader pass on every flow, locale/RTL checks | Apps sold to enterprise / Plus merchants |
| **Exemplary** | Comprehensive + external audit, documented limitations, assistive-tech test matrix per release | Apps making accessibility claims in the listing |

### This Project's Commitment

- **Tier**: [Standard]
- **Rationale**: [Why this tier — merchant profile, listing claims, risk]
- **Verified by**: [audit date, tools, tester]
- **Published where**: [app listing / docs — if we claim it, we must be able to prove it]

---

## Visual Accessibility

| Requirement | Target | Implementation | Verified |
|-------------|--------|----------------|----------|
| Contrast — body text | ≥ 4.5:1 | Polaris text tokens | [ ] |
| Contrast — large text / icons | ≥ 3:1 | Polaris tokens | [ ] |
| Focus indicator | Visible on every interactive element | Polaris focus ring; never `outline: none` | [ ] |
| Text resize | 200% without loss of function | Relative units, no fixed text heights | [ ] |
| Reflow | 320px width, no horizontal scroll for content | Polaris responsive layout | [ ] |
| Spacing | Text spacing overrides do not clip content | No fixed-height text containers | [ ] |
| Meaningful order | DOM order matches visual order | Layout components in reading order | [ ] |
| Images | Decorative images `alt=""`; informative images described | Explicit `alt` on every image | [ ] |
| Data tables | Header cells scoped, caption present | `IndexTable` / semantic table | [ ] |

### Colour-as-Only-Indicator Audit

| Location | Indicator | Colour-only? | Fix |
|----------|-----------|--------------|-----|
| [Row status] | `Badge` tone | No — text label present | — |
| [Chart series] | Line colour | Yes | Add direct labels or patterns |
| [Form error] | Red border | Yes | Add icon + text + `aria-invalid` |
| [Sync health dot] | Green/red dot | Yes | Add text label beside the dot |

**Rule**: colour may reinforce meaning, never carry it alone.

---

## Motor Accessibility

| Requirement | Implementation | Verified |
|-------------|----------------|----------|
| Full keyboard operation | Every action reachable by Tab/Enter/Space/Esc | [ ] |
| No keyboard traps | Focus escapes modals correctly | [ ] |
| Target size | ≥ 24×24 CSS px (Polaris default 32px) | [ ] |
| Single-pointer operation | No drag-only or hover-only actions | [ ] |
| No timing pressure | Session timeouts warn before expiring | [ ] |
| Motion control | `prefers-reduced-motion` honoured everywhere | [ ] |
| Sticky/fixed elements | Never cover focused element on scroll | [ ] |

---

## Cognitive Accessibility

| Requirement | Implementation | Verified |
|-------------|----------------|----------|
| Consistent navigation | Same nav structure on every page | [ ] |
| Predictable actions | Buttons do what their label says, everywhere | [ ] |
| Error prevention | Destructive actions confirmed, inputs validated on blur | [ ] |
| Error recovery | Errors state the fix, keep entered data | [ ] |
| Plain language | Sentences under ~25 words; no jargon in merchant copy | [ ] |
| No memory burden | Values visible where needed; no "remember this code" | [ ] |
| Progress clarity | Multi-step flows show step N of M | [ ] |
| Timeouts | Warning + extension option for long forms | [ ] |

---

## Auditory Accessibility

Admin apps produce no audio. The equivalent risk is information that only a
**screen reader announcement** conveys, or that is only conveyed visually and
never announced.

| Requirement | Implementation | Verified |
|-------------|----------------|----------|
| No audio-only information | Not applicable — no audio output | [ ] |
| Live region for async results | Toasts `polite`, critical errors `assertive` | [ ] |
| Loading announced | `aria-busy` on the updating region | [ ] |
| Errors announced | Field error linked, form summary focused on submit | [ ] |
| No unexpected announcements | No live region wrapping entire page | [ ] |

### Critical-Announcement Audit

Places where a silent visual change would leave a screen-reader user unaware:

| Event | Visual signal now | Announcement added |
|-------|-------------------|--------------------|
| [Sync completes] | Toast | `role="status"` polite message |
| [Row fails] | Red badge | Live region summary on change |
| [Bulk job progresses] | Progress bar | `progressbar` with value updates |
| [Plan limit reached] | Banner | Focus moves to banner on appearance |

---

## Platform Accessibility API Integration

| Surface | Integration | Notes |
|---------|-------------|-------|
| Embedded admin (iframe) | App Bridge keeps focus and titles in sync with the admin shell | Page title set per route |
| Polaris components | Built on native semantics and ARIA | Do not override roles casually |
| Browser zoom / OS scaling | Layout reflows; no clipped controls | Test at 200% and 400% |
| Screen readers | VoiceOver (Safari), NVDA (Chrome/Firefox), TalkBack (mobile admin) | Record version per audit |
| Shopify mobile admin | Touch targets, no hover dependencies | Test on a real device |
| POS / extension surfaces | Follow the host surface's accessibility contract | Document host limitations |

---

## Per-Feature Accessibility Matrix

| Feature | Keyboard | Screen reader | Contrast | Touch | Status |
|---------|----------|---------------|----------|-------|--------|
| [Onboarding wizard] | [Pass/Fail] | [Pass/Fail] | [Pass] | [Pass] | [Verified date] |
| [Sync settings] | | | | | |
| [Bulk retry] | | | | | |
| [Billing / plan change] | | | | | |

---

## Accessibility Test Plan

| Test | Method | Frequency | Owner |
|------|--------|-----------|-------|
| Keyboard-only pass | Manual, per flow | Every release | qa-tester |
| Screen-reader pass | VoiceOver on the primary task | Every release | qa-tester |
| Contrast check | Polaris token audit + automated axe scan | Every release | ux-lead |
| Automated scan | axe / Playwright accessibility assertions in CI | Every PR | devops-engineer |
| Zoom / reflow | 200% and 320px width | Every release | qa-tester |
| RTL spot-check | `ar` locale on the primary task | Each localized release | localization-lead |
| Reduced motion | OS setting on, all flows | Every release | qa-tester |

---

## Known Intentional Limitations

| Limitation | Reason | Merchant-facing mitigation | Reviewed |
|------------|--------|---------------------------|----------|
| [e.g. charts lack a data-table alternative] | [Time; charts are secondary] | [CSV export available] | [Date] |

---

## Audit History

| Date | Tier claimed | Auditor | Scope | Findings | Fixed |
|------|--------------|---------|-------|----------|-------|
| [Date] | [Standard] | [Name] | [Flows] | [N issues] | [N] |

---

## External Resources

- WCAG 2.2 quick reference — https://www.w3.org/WAI/WCAG22/quickref/
- Polaris accessibility guidance — https://polaris.shopify.com
- Shopify admin accessibility expectations (app review requirements)
- ARIA Authoring Practices — https://www.w3.org/WAI/ARIA/apg/

## Open Questions

| # | Question | Owner | Needed by |
|---|----------|-------|-----------|
| 1 | [Question] | [Who] | [Date] |
