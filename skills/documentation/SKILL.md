---
name: documentation
description: Best practices for software documentation — README, API docs, ADRs, inline comments, changelogs, and knowledge base organization. Use when writing README files, designing documentation strategy, adding inline comments. Detects from code context and project files — not dependent on specific language keywords."
---

# Documentation Best Practices

## The Minimalist Philosophy

> "Produce no document unless its need is immediate and significant." — Robert C. Martin

Documentation has ongoing cost: maintenance, outdated content, reader trust erosion. Write less, maintain ruthlessly.

**Rule:** If a document would be wrong within 6 months, don't write it — automate it or make the code self-explanatory.

## Documentation Types (by audience)

### 1. README — for newcomers
Every project needs one. Answers 4 questions in order:
1. **What is this?** — one-paragraph description
2. **Why does it exist?** — what problem it solves
3. **How do I run it?** — quickstart: install → configure → run
4. **Where do I go for help?** — link to issues, docs, chat

```markdown
# project-name
Brief description (1-2 sentences).

## Quickstart
```bash
npm install
cp .env.example .env
npm run dev
```

## Configuration
Key environment variables, config files.

## API
Link to OpenAPI spec or API docs.

## Development
Testing, linting, building, contributing guide.
```

**README anti-patterns:**
- ❌ Outdated setup steps (worse than no setup guide)
- ❌ Long architecture essays (put in ADR or docs/)
- ❌ Contributor lists (git log handles this)
- ❌ Badges from tools you don't use

### 2. ADRs (Architecture Decision Records) — for maintainers

Record *why* a decision was made, not *what* was decided (that's in the code).

```
docs/adr/
├── 001-use-postgres-for-primary-store.md
├── 002-use-dapr-for-pub-sub.md
└── 003-migrate-to-biome-from-eslint.md
```

**Template:**
```markdown
# ADR-001: Use PostgreSQL for Primary Store

**Date:** 2024-01-15
**Status:** Accepted | Proposed | Deprecated | Superseded

## Context
Why this decision was needed, what alternatives were considered.

## Decision
What was decided and why over alternatives.

## Consequences
What becomes easier, harder, or needs migration.
```

### 3. API Documentation — for consumers

- **REST:** OpenAPI 3.x spec. Generate from code (Hono Zod OpenAPI, FastAPI Swagger).
- **GraphQL:** Schema is documentation — auto-generated from SDL.
- **Libraries:** API reference (JSDoc, rustdoc, godoc, pydoc).
- **Include:** endpoint/method, params, request/response schema, errors, example, auth.

### 4. Inline Comments — for future developers

**Good comments (rare but valuable):**
```typescript
// WHY: This ordering ensures we process the oldest items first
// so failed retries don't starve newer entries. Priorities > 5
// are reserved for system-internal events.
```

**Bad comments (delete on sight):**
```typescript
// ❌ Redundant
i++ // increment i

// ❌ Misleading (out of date)
// This function validates input (it no longer does)

// ❌ Mumbling
// handle the thing

// ❌ Journal
// 2024-01-15: fixed the bug

// ❌ Commented-out code
// const old = calcTotal(items);
```

### 5. CHANGELOG.md — for users

Auto-generated from commits (release-please, changie, git-cliff). Never manual.

```markdown
# Changelog

## [1.2.0] - 2025-06-15
### Added
- feat(auth): Google OAuth sign-in
- feat(ui): dark mode toggle

### Fixed
- fix(billing): handle null currency in invoice generation
- fix(api): rate-limit headers on error responses

### Changed
- chore(deps): update TypeScript to 5.5
```

### 6. How-to Guides — for specific tasks

- Focused, task-oriented. One guide = one task.
- "How to add a new service" not "architecture overview."
- Keep in `docs/` directory alongside the code.

## Architecture (for docs/)

```
docs/
├── add-new-app.md        # How-to guide
├── deployment.md         # Deployment guide
├── adr/                  # Architecture Decision Records
├── diagrams/             # Architecture diagrams (keep simple)
└── runbooks/             # Incident response procedures
```

## Automation

- **Pre-commit check** — warn if README has no quickstart.
- **CI check** — verify ADR links are valid.
- **OpenAPI validation** — CI validates spec file is up to date.
- **Dependabot/Renovate** — keeps dependency docs fresh automatically.

## Documentation Anti-patterns

- ❌ **Rotting docs** — outdated docs are worse than no docs. Delete or update.
- ❌ **Copy-paste docs** — duplicated content across files. Cross-reference instead.
- ❌ **Epic README** — README that tries to document everything. Split into `docs/`.
- ❌ **Documenting the obvious** — `// This function saves a user`
- ❌ **No code examples** — abstract docs without concrete usage are useless.
- ❌ **No tone** — documentation can be clear without being dry. A little personality helps.
