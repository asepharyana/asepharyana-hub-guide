---
name: git-workflow
description: MANDATORY — always active. Git workflow best practices — commit conventions, branching strategies, PR conventions, rebase vs merge, and code review. Use when writing commit messages, reviewing PRs, planning branching strategy. Detects from code context and project files — not dependent on specific language keywords."
---

# Git Workflow

## Commit Message Convention

Format: `<type>(<scope>): <description>`

```
feat(auth): add google oauth sign-in
fix(billing): handle null currency in invoice
chore(deps): update typescript to 5.5
docs(api): document rate-limit headers
refactor(orders): extract payment validation
test(users): add unit tests for CreateUser
ci(deploy): split build and push steps
perf(db): add index on orders.created_at
style(ui): fix button alignment
```

**Rules:**
- Type is lowercase. No period at the end.
- Scope is required — the affected module/context.
- Imperative mood ("add" not "added" or "adds").
- Subject under 72 chars.
- Body wraps at 72 chars. Explains *why* (not *what*).
- Footer for breaking changes: `BREAKING CHANGE: ...`
- Footer for co-authors: `Co-Authored-By: Name <email>`

## Branching Strategy

### Trunk-Based (preferred for CI/CD)
```
main ← feature branches
```
- Short-lived feature branches (1-2 days max).
- PR → auto-merge to main after CI passes.
- Deploy from main. Hotfix = branch from main → merge back.

### GitHub Flow
```
main → feature/xyz → PR → main
main → fix/xyz → PR → main
main → chore/xyz → PR → main
```

### Git Flow (for release-based projects)
```
main → develop → feature/xyz → PR → develop
                              → release/v1.2 → main + develop
                              → hotfix/v1.2.1 → main + develop
```

**Choose:**
- **Trunk-based** — if you deploy multiple times a day (SaaS, web apps).
- **Git Flow** — if you version releases (libraries, mobile apps, on-prem).

## PR Conventions

### Title
Same as commit convention: `feat(scope): description`

### Description Template
```
## What
Brief description of the change.

## Why
Problem being solved. Link to issue/ticket.

## How
High-level approach — architecture decisions, trade-offs.

## Testing
- [ ] Unit tests added/passed
- [ ] Integration tests added/passed
- [ ] Manual test steps

## Screenshots (if UI change)
...

## Checklist
- [ ] Lint passes
- [ ] Tests pass
- [ ] Docs updated
- [ ] Breaking changes documented
```

### PR Size
- **Target: <200 lines changed.** Large PRs get less thorough reviews.
- If >500 lines, split into logical chunks or mark as "stacked PR."
- One logical change per PR. Don't mix refactors with features.

## Code Review

### Reviewer Checklist
1. [ ] Does the solution match the PR description?
2. [ ] Any edge cases unhandled? (empty state, errors, concurrency)
3. [ ] Tests cover happy path + error paths + edge cases?
4. [ ] No dead code, commented-out code, magic numbers?
5. [ ] Dependencies are necessary (no scope creep)?
6. [ ] Error handling appropriate (not silent, not leaky)?
7. [ ] Security: input validated? Auth checked? No secrets?

### Review Etiquette
- **Be specific** — "Line 42: this query is N+1, use `JOIN`" not "this is slow"
- **Ask, don't demand** — "Should this be a named constant?" not "Make this a constant"
- **Approve quickly for trivial changes** — don't block for style nits
- **Distinguish blocking vs nit** — explicitly label `nit:` or `blocking:`
- **Respond to reviews** — every comment gets a reply or action

## Merging Strategy

| Strategy | When |
|----------|------|
| **Squash merge** | One feature = one commit on main. Clean history. |
| **Rebase merge** | Preserve individual commits. For stacked PRs. |
| **Merge commit** | Preserves full history of feature branch. Noisy. |

**Default: squash merge.** Keeps main clean and bisectable.

## Anti-patterns

- ❌ **Committing to main directly** — always use PRs (except hotfix emergencies)
- ❌ **Large, unfocused commits** — `"WIP"`, `"fixes"`, `"misc changes"`
- ❌ **Rebasing shared branches** — never rebase a branch others have pulled
- ❌ **Merge commits in main** — unless you use merge-commit strategy deliberately
- ❌ **Stale branches** — clean up after merge. Name indicates age/staleness
- ❌ **No issue/PR reference** — every commit should answer "why?"
