---
name: engineering-principles
description: Foundational software engineering principles that apply across all languages, frameworks, and project types — correctness, simplicity, YAGNI, KISS, DRY, root-cause fixes, least astonishment, explicit over implicit, fail fast, professional craftsmanship, and multi-agent orchestration for complex tasks. This skill is a baseline: apply these principles to every code decision, review, and architecture discussion, regardless of language or framework. Engage proactively whenever writing, reviewing, or designing code — especially when the user's request seems to violate one of these fundamentals. Detects from code context, project files, and task complexity — not dependent on specific language keywords. Triggers regardless of spoken language when the task is complex, multi-step, or large in scope (see §26 — Workflow orchestration).
---

# Engineering Principles

These are the non-negotiable foundations. Every other skill in this plugin is an elaboration of one or more of these principles. They apply to every line of code, every language, every framework, every project.

---

## 1. Correctness > Speed > Cleverness

Correct code is the only code that matters. Fast code that's wrong is worse than slow code that's right. Clever code that's hard to understand is technical debt, even if it's correct and fast.

- A correct, readable solution is better than a clever, unreadable one.
- Optimize only after profiling proves a bottleneck (see Principle 20).
- "It works but it's ugly" is a reason to refactor, not to ship.

## 2. YAGNI — You Ain't Gonna Need It

Build for proven needs, not speculation. Every feature you add but never use is debt, not an asset.

- Don't add abstractions, parameters, or extension points until you have a concrete second consumer.
- "We might need this later" is not a justification. Delete it. Later can scaffold for itself.
- If you haven't needed it yet, you don't know what shape "later" actually needs.

## 3. Boy Scout Rule

Leave every module cleaner than you found it — even if just by renaming one variable or extracting one tiny function.

- Cumulative small improvements prevent code rot.
- "I was just in there to fix a bug" is exactly when to leave it cleaner.
- No, you don't need a ticket. Just fix it.

## 4. Root Cause, Not Symptom

Fix bugs at the root cause, not at every call site. One guard in the shared function is a smaller diff than a guard in every caller.

- Before patching a caller, grep all callers of the function you're about to touch.
- Patching only the path the ticket names leaves every sibling caller still broken.
- A symptom fix is not a fix — it's a second bug waiting for its sibling to trigger.

## 5. KISS — Keep It Simple, Stupid

The simplest solution that works is the correct solution. Not the smartest, not the most extensible, not the most abstract.

- Simple code is easy to change. Complex code is impossible to change.
- If a solution is hard to explain, it's probably wrong for this problem.
- Complexity is never justified by "we'll need it later" (see Principle 2).

## 6. DRY — Don't Repeat Yourself

Every piece of knowledge must have a single, unambiguous, authoritative representation within a system.

- Duplication is the #1 code smell. Hunt it everywhere.
- Not just code: duplicate configuration, duplicate documentation, duplicate logic.
- Three strikes and you extract. Once is coincidence. Twice is suspicious. Three times is a pattern.

## 7. Tell, Don't Ask

Tell objects what to do instead of asking for their data and deciding yourself.

- `if (user.isActive()) user.sendNotification(msg)` — tell the user to notify.
- `if (order.getStatus() === 'paid') order.ship()` — ask the order if it can ship.
- The point is to keep logic with the data it operates on, not scattered across callers.

## 8. Command-Query Separation

A function either *does* something (command) or *answers* something (query), never both.

- `saveAndReturn()` violates CQS. Split into `save()` and `get()`.
- This is not pedantry — combined CQ functions cause hidden side effects that make code unpredictable.

## 9. Meaningful Names

If you cannot name it, you don't understand it. A long descriptive name is better than a long descriptive comment.

- Names should answer: what is this, why does it exist, how is it used?
- `int d` is never acceptable. `int elapsedTimeInDays` is.
- Names are the single highest-leverage readability tool. Spend time on them.

## 10. One Function, One Responsibility

A function does one thing if, and only if, you cannot extract another function from it. Target ~20 lines. Smaller is better.

- If you can't see the whole function on one screen, it's too long.
- One level of abstraction per function. The Step-Down Rule: callers above, callees below.
- No flag parameters (`render(true)`). Split into `renderForSuite()` and `renderForSingleTest()`.

## 11. Tests Come First

Code without tests is legacy code. Not "needs tests" — *legacy*.

- **Three Laws of TDD:** ① Write no production code without a failing test. ② Write no more test than enough to fail. ③ Write no more production code than enough to pass.
- If you can't write a test for a piece of code, the code is coupled to things it shouldn't be.
- Test code is first-class code. Same quality, same review standards.

## 12. Comments = Failure of Expression

Before writing a comment, ask: can I rename or extract to make this unnecessary? Good comments explain *why*, not *what*.

- **Good comments (rare):** intent, warnings of consequences, legal headers, regex explanations, TODOs (pruned regularly).
- **Bad comments (delete on sight):** redundant, journaling, closing-brace, commented-out code, mandated noise.
- "Don't comment bad code — rewrite it." — Brian Kernighan

## 13. Less Is More

Deletion is better than addition. No unrequested abstractions. The best code is the code never written.

- An interface with one implementation is speculative. A factory for one product is speculative. A config value that never changes is speculative.
- Before writing anything, ask: does this need to exist at all? Is it already in the codebase? Does the standard library do it?
- Rung-by-rung: stdlib → installed deps → one line → minimum code.

## 14. Respect Boundaries

Business code must never depend on frameworks, databases, or UI. Architecture is about use cases.

- Domain layer: zero framework imports. Pure types, pure business rules.
- The database is a detail. The web framework is a detail. The UI is a detail.
- Swap the database without touching business logic. If you cannot, your boundary is violated.

## 15. Work Professionally

Never ship code you know is wrong. The only way to go fast is to go well.

- "We'll clean it up later" never happens. Dirty code slows the whole team down.
- A professional says no to unreasonable deadlines rather than shipping garbage.
- Every time you compromise on quality knowingly, you accumulate compound-interest debt.

## 16. Tech Debt — Don't Abandon Code

Finding an existing error or bad code is not a reason to skip it and say "that was already there." **Rot does not become correct because it's old.** Fix it or file a task.

- "It was like that when I got here" is not an acceptable engineering justification.
- Code abandoned today is a production incident waiting for a trigger.
- If you can't fix it right now, make sure there's a tracker entry and move on — but don't pretend it doesn't exist.

## 17. Principle of Least Astonishment

Code should be consistent and predictable. Don't make the reader think "wait, what?" Same formatting, same idioms, same patterns across the codebase.

- Surprise in birthday parties is fun. Surprise in production code is not.
- Follow the existing patterns in the codebase, even if you'd write it differently.
- Consistency within a project beats any individual preference.

## 18. Fail Fast — Fail Quickly, Fail Clearly

Validate at the boundary. Crash early with a clear message rather than silently proceeding with corrupted data and crashing 10 steps later with a cryptic error.

- `if (x == null) return x` is not fail-fast — it's hiding a bug.
- Validate and reject at the API boundary, service boundary, function boundary.
- A clear error message at the point of failure is cheaper than a stack trace from production that requires bisecting.

## 19. Explicit > Implicit

Don't hide behind magic, side effects, or hidden state. Code should say what it does. Implicit is an invitation for bugs that are invisible until production.

- No hidden side effects in functions named as queries.
- No global state mutations. No surprise mutations. No "it just works" magic.
- If someone reading the code can't see the effect, it's implicit — and that's a bug waiting to happen.

## 20. Premature Optimization is the Root of All Evil

"Make it work, make it right, make it fast" — in that order. Optimization before measurement and proven bottleneck is just complexity with no return.

- This is YAGNI for performance. You don't know what to optimize until you measure.
- A cache that's never hit is code you have to maintain for zero benefit.
- First make it correct. Then make it clean. Only then, if it's slow, make it fast.

## 21. Single Responsibility for Modules

Not just functions — classes, services, and modules must have one reason to change.

- A module that does everything is a god object/god service, and god objects are disasters waiting to happen.
- If you can't describe what a module does in one sentence without "and," it has too many responsibilities.
- SRP's evolved formulation: "responsible to one, and only one, actor."

## 22. Open/Closed Principle

Open for extension, closed for modification. Add features by writing new code, not by editing working, tested code.

- Strategy pattern over if-else chains for varying behavior.
- Plugin architecture over switch statements for feature toggles.
- Polymorphism over type checks.

## 23. Prefer Composition Over Inheritance

Inheritance makes code rigid and fragile — a change in the parent can break every child. Composition is more flexible, easier to test, and doesn't create class hierarchies that collapse at generation 3.

- "Is-a" relationships are rare. "Has-a" relationships are common.
- Favor small interfaces composed together over deep class hierarchies.
- If you're reaching for inheritance, ask: could I pass this as a dependency instead?

## 24. Atomic Commits — Small and Focused

One commit = one logical change. Not a mix of refactor + feature + bug fix in one commit.

- A clean diff means a fast review and a readable history.
- If your commit message needs "and," your commit is too large.
- `git add -p` is your friend. Stage related changes together, unrelated changes separately.

## 25. Ask When Ambiguous — Never Assume

When requirements are unclear, the user's intent is uncertain, or there are multiple valid approaches, **ask** instead of guessing. Assumptions create waste: wrong implementation, rework, and frustration.

- **Ambiguous request?** Ask 1-2 focused clarifying questions before writing code. Don't silently pick one interpretation.
- **Multiple valid approaches?** Briefly compare trade-offs and ask which one fits. Don't default to your favorite.
- **Missing context?** Ask for it. Don't infer from partial input.
- **One clarifying question is better than five.** Ask the minimum to unblock.
- **If you must assume, state your assumption explicitly** — "Assuming this is a server component since you mentioned API routes. Say so if you need it to be a client component."

The goal: write code once, correctly, based on what the user actually wants — not what you guessed they wanted.

## 26. Use Multi-Agent Workflows for Complex Tasks — Don't Go Solo

When the user's request is complex, multi-step, or large in scope, **use the Workflow tool** to orchestrate parallel agents. Going solo on a complex task misses the benefits of independent verification and parallel execution.

**Triggers — use Workflow when the task involves:**
- **Multiple files or modules** that need simultaneous changes
- **Review or audit** — fan out finders per file, adversarial verify findings
- **Research or investigation** — sweep multiple angles in parallel
- **Architecture or design** — judge panel with different approaches
- **Migration or refactoring** — parallel transforms in isolated worktrees
- **Any task you'd describe as "big," "complex," "thorough," or "comprehensive"**

**Quality patterns to apply:**
- **Adversarial verification** — after finding issues, spawn 3 skeptics to try to refute each finding. Kill findings that ≥majority refute.
- **Multi-modal sweep** — parallel agents searching differently (by-content, by-entity, by-time, by-pattern).
- **Completeness critic** — a final agent asking "what's missing?" to catch blind spots.
- **Loop-until-dry** — for discovery tasks, keep going until consecutive rounds find nothing new.

**Default to pipeline over barrier.** Pipeline lets item A verify while item B is still being reviewed — no wasted wall-clock time. Barriers (parallel() then parallel()) are only justified when the next stage genuinely needs ALL results from the prior stage (e.g., deduplication across all findings before expensive verification).

**Don't over-engineer.** A workflow for a one-file fix is wasteful. Use Workflow for tasks that genuinely benefit from multiple perspectives or parallel execution. When in doubt, ask the user: "This looks complex — should I use a multi-agent workflow for thorough coverage?"

## 27. Language-Agnostic Detection — Trigger from Concepts, Not English Keywords

Skills must trigger based on **concept**, **code context**, and **project files** — not just explicit English keyword matches. The user may speak any language.

**Rules:**
- Detect from **context** not literal keywords. User says "tes" or "pengujian" → trigger testing skill. User says "bikin test" or "add tests" → same thing.
- Detect from **code being worked on** — `.test.ts` file → testing skill. `routes.ts` → hono-backend/elysiajs. Drizzle schema → drizzle-database.
- Detect from **project files** — `Cargo.toml` → rust. `go.mod` → go. `Dockerfile` → docker.
- **Don't wait for keyword mentions.** If the user is writing TypeScript and says "buat repository pattern" — trigger clean-architecture + typescript. Mixed language doesn't matter — capture the concept.
- **Behavioral pattern > keyword.** User says "kode ini jelek, rapihin" → trigger clean-code. User says "tambahin validasi" → trigger error-handling + security.
- **Ask when unsure.** If context is insufficient to determine which skill, ask one short question. Don't assume.
- The `detect-project.sh` hook automatically detects from project files — this is the primary activation pathway, not just keyword matching.

## 28. Never Suppress Lints — Fix the Code

Linters, type checkers, and analyzers exist to catch bugs before production. **Never disable them with `#[allow]`, `// @ts-ignore`, `# noqa`, or `// eslint-disable-next-line`** — you are bypassing a tool designed to protect you.

### What to do instead:
- **Linter error** → fix the code. If you can suppress it, you can fix it.
- **`clippy::too_many_arguments`** → extract a parameter struct. Don't `#[allow]`.
- **`clippy::type_complexity`** → extract a type alias. Don't `#[allow]`.
- **`@ts-ignore` / `@ts-expect-error`** → fix the type. TypeScript strict mode should not need these.
- **`# noqa` (Python)** → fix the line length, import order, or complexity.
- **`eslint-disable-next-line`** → fix the violation. If the rule is wrong, disable it globally with a reason.

### The only exceptions:
- **False positive from linter** — must be proven, not guessed. Add comment `// lint false positive: <reason>`.
- **Generated code** — protobuf, OpenAPI client, etc. can be excluded via config, not inline suppress.
- **Phased migration** — for large codebases, suppress at project config level with a target to remove within 30 days. Not inline per-line suppressions that accumulate.

### Enforce in CI:
```bash
# Rust
cargo clippy -- -D warnings

# TypeScript
tsc --noEmit --strict

# Python
ruff check --strict

# Go
go vet ./...

# All
git commit --no-verify  # only for emergencies, not routine
```

A suppressed lint is a bug invited into production. If you can `#[allow]` it, you can also fix it.

## 29. Never Assume — Show Evidence for Everything

Never guess, speculate, or assume. **Every claim, suggestion, or piece of code you produce must be backed by evidence or documentation.**

### Rules:
1. **Code you write** — must be based on existing code in the codebase, official framework/library documentation, or compiler/type-checker output. Not "from what I remember" or "from training data."
2. **File structure** — don't guess where a file lives. Search first (`grep`, `find`, glob). If not found, ask the user.
3. **API / function signature** — don't guess parameters or return types. Read the actual source code. For external libraries, check documentation (Context7, web search, or inspect `node_modules/` / `vendor/`).
4. **Error / bug** — don't guess the cause. Find evidence: error logs, stack traces, test output, or code that is clearly wrong.
5. **Config / environment** — don't guess variable values or paths. Find config files, `.env.example`, or ask the user.
6. **Dependency version** — don't guess versions. Check `package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, or lock files.
7. **Citing sources** — when referencing documentation, name the source: "per docs in `docs/add-new-app.md`" not "as I know it."
8. **"What is this?" / "How does X work?"** — don't answer from training data. Read the code first (`grep -r`, read relevant files), then answer based on actual code.

### When uncertain:
- **Search first.** Don't answer from memory. If the information isn't in the codebase or tool output, use web search.
- **Ask the user.** If you've searched and can't find it, ask. Don't fabricate.
- **Acknowledge limitations.** "I'm not sure about X, but based on Y which I found at..." is better than a confident wrong answer.

### Examples:
```
❌ "I think this function returns Promise<User>"
✅ "I can see at src/users/service.ts:42 that getUser's return type is Promise<User>"

❌ "The config might be in .env"
✅ "I searched for .env and didn't find one. There's a .env.example — maybe that's the template. Could you check?"

❌ "Dockerfiles are usually in the root"
✅ "I found the Dockerfile at: infra/docker/hub.Dockerfile"
