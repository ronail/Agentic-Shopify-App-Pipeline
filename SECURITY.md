# Security Policy

## Supported Versions

Only the `main` branch receives security fixes. Forks and older releases are
not supported.

## Reporting a Vulnerability

**Do not report security vulnerabilities through public GitHub issues.**

Use GitHub's private vulnerability reporting instead:

**[Report a vulnerability →](https://github.com/ronail/Agentic-Shopify-App-Pipeline/security/advisories/new)**

Include as much detail as possible:
- Description of the vulnerability and what it affects
- Steps to reproduce
- Potential impact and attack scenarios
- Any suggested mitigations

**What to expect:**
- Acknowledgment within **48 hours**
- Status update within **7 days**
- Resolution within **90 days** for confirmed vulnerabilities

## What Is In Scope

This repo is a **local development tool** — it installs shell hooks and
coordinates AI agents that run directly on your machine — plus the template
code those agents generate for Shopify apps. Security issues fall into two
groups: contributed code that executes in users' environments without their
awareness, and generated app code that mishandles merchant data.

### High Severity — framework
- Hooks (`.claude/hooks/*.sh`) that execute malicious or undisclosed shell
  commands on user machines
- Skills or agents that exfiltrate environment variables, API keys, or secrets
- Prompt injection via skill or agent definitions that causes the model to bypass
  safety measures or take unauthorized destructive actions
- Contributions that silently alter behavior in ways users cannot audit

### High Severity — generated app code
- Access tokens or session tokens logged, stored in plaintext, or exposed to the
  browser
- Webhook handlers that act on payloads before HMAC verification
- Admin API calls made with a merchant-supplied identifier without checking the
  session's shop
- OAuth flows that skip state/HMAC validation or accept an unverified callback

### Medium Severity
- Skills that make undisclosed outbound network requests
- Agent definitions that escalate permissions or bypass user confirmation prompts
- Hook patterns that behave differently across platforms to conceal behavior
- Skills that write outside their documented scope without an explicit user
  approval step
- Requested access scopes wider than the feature needs

### Out of Scope
- The behavior of Claude or the Claude Code CLI itself
  (report to [Anthropic](https://www.anthropic.com/security))
- Bugs in the user's Claude Code installation or editor extension
- Vulnerabilities in Shopify's platform or Admin API
  (report to [Shopify](https://hackerone.com/shopify))
- Theoretical vulnerabilities with no realistic attack path
- Issues requiring physical access to the user's machine

## Security Guidelines for Contributors

When contributing hooks, skills, agents, or templates:

- **Hooks must be POSIX-compatible** — use `grep -E`, not `grep -P`; avoid
  platform-specific syntax that behaves differently across operating systems
- **No silent network calls** from hooks or skills unless explicitly documented
  and opt-in by the user
- **No reading secrets or environment variables** beyond what is minimally
  required and clearly documented in the skill's header
- **Skills must not write outside their documented scope** without an explicit
  user confirmation step
- **Templates must not hardcode credentials, API versions, or store domains** —
  scaffold them from config so a reviewer can see where they come from

## Disclosure Policy

We follow a **90-day coordinated disclosure** timeline:

1. You submit the vulnerability privately
2. We acknowledge within 48 hours
3. We confirm and assess severity within 7 days
4. We develop and test a fix
5. We notify you before any public disclosure
6. Public disclosure happens after the fix ships, or at 90 days — whichever
   comes first

We credit reporters in release notes unless you prefer to remain anonymous.
