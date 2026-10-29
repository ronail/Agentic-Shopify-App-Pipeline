# Agentic Shopify App Pipeline — Shopify App Studio Agent Architecture

AI-driven research, development, release and review pipeline for Shopify apps,
run by coordinated Claude Code subagents. Each agent owns one domain, enforces
separation of concerns, and hands off only at a defined pipeline gate.

## Technology Stack

- **Language**: TypeScript
- **UI**: React with Polaris (embedded Shopify admin)
- **Embedding**: App Bridge
- **Shopify API**: GraphQL Admin API (version-pinned per app)
- **Runtime**: Node
- **Local Dev**: Shopify CLI
- **Tests**: Vitest
- **Version Control**: Git with trunk-based development

## Project Structure

@.claude/docs/directory-structure.md

## Technical Preferences

@.claude/docs/technical-preferences.md

## Coordination Rules

@.claude/docs/coordination-rules.md

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for full protocol and examples.

> **First session?** If the repo has no app scaffolded yet, run `/start` to begin
> the guided onboarding flow: research the merchant problem worth solving, then
> scaffold `apps/<app-name>/`.

## Coding Standards

@.claude/docs/coding-standards.md

## Context Management

@.claude/docs/context-management.md
