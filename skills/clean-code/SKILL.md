---
name: clean-code
description: Apply Robert C. Martin's (Uncle Bob's) Clean Code, Clean Architecture, and Clean Craftsmanship principles when writing, reviewing, or refactoring code. Use this skill whenever the user asks to write new code of non-trivial size, refactor existing code, review code for quality, design a module or system boundary, write tests, or whenever the user mentions "clean code," "clean architecture," "SOLID," "SRP," "OCP," "LSP," "ISP," "DIP," "TDD," "refactor," "code smells," or "Uncle Bob." Also engage proactively when producing code with poor naming, long functions (>20 lines), deep nesting, unclear abstractions, duplicated logic, switch/if-else chains on type, missing tests, or frameworks bleeding into business logic.
---

# Clean Code

Core principles for writing readable, maintainable, and professional code.

## Philosophy

1. **Code is read far more than written** — ratio >10:1. Optimize for the reader.
2. **Boy Scout Rule** — leave every module cleaner than you found it.
3. **The only way to go fast is to go well.** Dirty code slows everyone down.

## 1. Meaningful Names

- Use **intention-revealing names** — what is it, why does it exist, how is it used?
- **Avoid disinformation** — don't call it `accountList` unless it's a `List`. No `l`/`O` as variable names.
- **Pronounceable, searchable names** — `genymdhms` is not acceptable.
- **Class names** are nouns (`Customer`), **method names** are verbs (`postPayment`).
- **One word per concept** — standardize `fetch` vs `retrieve` vs `get`.
- **Ubiquitous language** — use the business domain's vocabulary consistently.

## 2. Functions

- **Small.** Target ~20 lines. If you can't see the whole function, it's too long.
- **Do one thing.** Operational test: you cannot extract another function from it.
- **One level of abstraction per function** — the Step-Down Rule.
- **Few arguments.** 0 ideal, 1-2 fine, 3 suspect, 4+ → need a struct or a split.
- **No flag arguments.** `render(true)` → split into `renderForSuite()` and `renderForSingleTest()`.
- **No side effects.** A function named `checkPassword` must not also log a session.
- **Command-Query Separation** — either *do* or *answer*, never both.
- **Prefer exceptions (or Result types) to error codes.**
- **DRY** — Don't Repeat Yourself. Duplication is the #1 smell.

## 3. Comments

> "Don't comment bad code — rewrite it." — Brian Kernighan

Every comment is a failure to make code self-explanatory. Before writing a comment, ask: *can I rename or extract?*

**Good comments (rare):**
- Legal headers, regex explanations, wire protocol details
- **Intent** — *why* (not *what*)
- Warnings of consequences ("this test takes two hours")
- TODOs (prune regularly)

**Delete on sight:** redundant comments, journaling (`// added by Rick`), closing-brace comments, commented-out code, mandated noise.

## 4. Formatting

- **Newspaper metaphor:** high-level first, details as you scroll.
- **Vertical density:** related concepts close together. Caller above callee.
- **Blank lines** separate concepts, not pad.
- **Indentation = abstraction signal.** Ideal functions have ≤2 indentation levels.

## 5. Objects and Data Structures

- **DTOs are data structures, not objects.**
- **Law of Demeter** — don't talk to strangers. No train wrecks (`a.getB().getC().doSomething()`).
- **Tell, don't ask** — tell the object to do the work instead of asking for state and deciding.

## 6. Error Handling

- Use exceptions/Result types, not return codes.
- Write try-catch-finally first when an operation can fail.
- Wrap third-party exceptions in your own types.
- **Don't return null.** Return empty collections or use Option/Result.
- **Don't pass null.** Fail fast at boundaries.

## 7. Tests

- **Three Laws of TDD:** 1) no production code without a failing test, 2) no more test than sufficient to fail, 3) no more production code than sufficient to pass.
- **F.I.R.S.T.:** Fast, Independent, Repeatable, Self-validating, Timely.
- Test code is first-class — same quality as production code.

## 8. Classes

- **Small by responsibility**, not by lines. SRP: one reason to change, one actor.
- **Cohesion** — methods should use most instance variables. Low cohesion = two classes in one.
- **Organize for change** — isolate volatile concepts behind interfaces.

## 9. Systems

- **Separate construction from use** — wiring lives in one place.
- **Dependency injection** over hardcoded `new` deep in business logic.
- Cross-cutting concerns (logging, security, metrics) belong in middleware, not scattered code.

## Code Smells — Quick Checklist

| Category | Smells |
|----------|--------|
| Functions | >3 args, flag params, dead params, obscure intent, misplaced responsibility |
| Classes | Feature envy, god class, inappropriate intimacy, lazy class |
| General | Duplication, magic numbers, inconsistent naming, negative conditionals, switch on type |
| Names | `data`/`info`/`handle`, not matching abstraction level, Hungarian notation |
| Tests | Insufficient coverage, skipped tests, order-dependent, slow, over-mocking |
