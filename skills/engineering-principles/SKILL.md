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

## 27. Language-Agnostic Auto-Trigger — Jangan Hardcode Bahasa Inggris

Skills harus trigger berdasarkan **konsep**, **konteks kode**, dan **file project** — bukan cuma kata kunci Bahasa Inggris. User bisa ngomong pake bahasa apapun.

**Aturan:**
- Detect dari **konteks** bukan keyword literal. User minta "tes" atau "pengujian" → trigger testing skill. User minta "bikin test" atau "add tests" → same thing.
- Detect dari **kode yang lagi dikerjain** — file `.test.ts` → testing skill. Class `OrderService` dengan pola tertentu → clean-architecture skill. `routes.ts` → hono-backend/elysiajs.
- Detect dari **file project** — `Cargo.toml` → rust skill. `go.mod` → go skill. `Dockerfile` → docker skill.
- **Gak perlu nunggu user nyebut keyword.** Kalau user lagi nulis kode TypeScript dan nyebut "buat repository pattern" — itu trigger clean-architecture + typescript. Kalimatnya campur aduk, konsepnya yang ditangkap.
- **Behavioral pattern > keyword.** User bilang "kode ini jelek, rapihin" → trigger clean-code. User bilang "tambahin validasi" → trigger error-handling + security.
- **Tanya kalau ragu.** Kalau konteks gak cukup buat nentuin skill mana, tanya 1 pertanyaan pendek. Jangan asumsi.
- Hook `detect-project.sh` udah otomatis deteksi dari file project — ini jalur utama activation, bukan cuma keyword matching.

## 28. Never Suppress Lints — Fix the Code

Linter, type checker, dan analyzer ada untuk menangkap bug sebelum produksi. **Jangan pernah matiin mereka dengan `#[allow]`, `// @ts-ignore`, `# noqa`, atau `// eslint-disable-next-line`** — itu mengakali alat yang dibuat untuk melindungi kamu.

### What to do instead:
- **Linter error** → perbaiki kodenya. Kalau kamu bisa suppress, kamu bisa fix.
- **`clippy::too_many_arguments`** → extract parameter struct. Jangan `#[allow]`.
- **`clippy::type_complexity`** → extract type alias. Jangan `#[allow]`.
- **`@ts-ignore` / `@ts-expect-error`** → perbaiki type-nya. TypeScript strict mode harusnya gak perlu ini.
- **`# noqa` (Python)** → perbaiki line length, import, atau kompleksitas.
- **`eslint-disable-next-line`** → perbaiki pelanggarannya. Kalau rule-nya salah, nonaktifkan global dengan alasan.

### Satu-satunya pengecualian:
- **False positive dari linter** — tapi harus dibuktikan, bukan ditebak. Tambah komentar `// lint false positive: <reason>`.
- **Generated code** — kode hasil generate (protobuf, OpenAPI client) bisa di-exclude via config, bukan inline suppress.
- **Migration bertahap** — kalau codebase besar, suppress dulu di level project config, target hapus <30 hari. Bukan inline per-line yang numpuk.

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

Lint yang di-skip adalah bug yang diundang. Kalau kamu bisa `#[allow]` itu, kamu juga bisa perbaiki itu.
