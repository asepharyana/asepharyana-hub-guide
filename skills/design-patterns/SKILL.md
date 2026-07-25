---
name: design-patterns
description: Guidance on Gang of Four design patterns and modern alternatives — when to use each pattern, how to implement it correctly, and when to avoid it. Use when designing class structures, solving recurring design problems, refactoring switch/if-else chains, or whenever the user mentions "design patterns," "GoF," "Factory," "Strategy," "Observer," "Singleton," "Adapter," "Decorator," or "DI."
---

# Design Patterns

Patterns are solutions to recurring design problems. Use the right pattern for the right axis of change.

## When to Use Patterns

- **More types, fewer operations** → OO patterns (polymorphism)
- **More operations, fewer types** → functional patterns (pattern matching, functions)
- **Expected to change together?** Keep them together in one abstraction.
- **Expected to change independently?** Separate them with an interface.

## Creational Patterns

| Pattern | When | Why |
|---------|------|-----|
| **Factory Method** | A class can't know the type of objects it must create | Push creation decision to subclasses |
| **Abstract Factory** | Need families of related objects | Enforce compatibility across a product line |
| **Builder** | Object construction has many optional parts | Replace telescoping constructors |
| **Singleton** | Exactly one instance is needed | *Avoid if possible* — use dependency injection instead |
| **Prototype** | Creating objects is expensive; cloning is cheaper | Copy-on-write, configurable app |

**Modern alternative:** For factories, prefer passing a function/constructor directly (`(config) => new Connection(config)`) over a factory class.

## Structural Patterns

| Pattern | When | Why |
|---------|------|-----|
| **Adapter** | Interface mismatch between expected and actual | Wrap, don't modify |
| **Bridge** | Abstraction and implementation vary independently | Decouple interface from implementation |
| **Composite** | Treat individual objects and compositions uniformly | Menu trees, file systems, UI trees |
| **Decorator** | Add responsibilities without subclassing | Middleware, streams, logging wrappers |
| **Facade** | Simplify a complex subsystem | Single entry point to complex system |
| **Flyweight** | Many fine-grained objects are too expensive | Share intrinsic state across instances |
| **Proxy** | Control access to another object | Lazy loading, caching, access control, logging |

**Modern alternative:** Middleware chains (e.g., Hono/Express middleware) are a functional take on Decorator. Proxy is often handled by AOP or proxy libraries.

## Behavioral Patterns

| Pattern | When | Why |
|---------|------|-----|
| **Strategy** | Multiple algorithms for the same task | Pass behavior as a parameter |
| **Observer** | One-to-many dependency where state changes need notification | Event emitters, pub/sub |
| **Command** | Parameterize operations, queue, undo, log | Transaction logging, job queues |
| **Template Method** | Skeleton of algorithm varies in steps | Subclasses override specific steps |
| **Iterator** | Access elements sequentially without exposing structure | Built into every modern language |
| **State** | Object behavior changes when its state changes | State machines |
| **Mediator** | Reduce coupling between communicating objects | Chat rooms, UI coordination |
| **Chain of Responsibility** | Pass request along handler chain until one handles it | Middleware, validation pipelines |
| **Visitor** | New operation on a stable object structure | AST processing, serialization |
| **Memento** | Capture and restore internal state | Undo/redo, snapshots |
| **Interpreter** | Grammar interpretation | DSLs, parsers |

**Modern alternative:** Strategy → pass a lambda/closure. Observer → use reactive streams or event emitters. Command → functions are commands.

## Pattern Selection Guide

Ask these questions:
1. **What is changing?** Encapsulate what varies.
2. **What's the axis of change?** More types (OO) or more operations (functional)?
3. **Is there a simpler alternative?** A function parameter is often enough.
4. **Does the pattern add clarity or complexity?** Patterns justify themselves only if they reduce overall complexity.

## Modern Patterns (Post-GoF)

- **Dependency Injection** — pass dependencies in, don't create them internally
- **Repository** — abstraction over data access (not in GoF, but ubiquitous)
- **CQRS** — separate read and write models
- **Event Sourcing** — store events, derive state
- **Saga** — orchestrate distributed transactions
- **Circuit Breaker** — fail fast when downstream fails

## Deeper Reference

When the task calls for it, load:

- **[references/catalog.md](references/catalog.md)** — Full GoF pattern catalog with code examples, real-world usage, modern alternatives, and "when to NOT use" guidance for each pattern.

## Anti-patterns

- ❌ **Pattern for pattern's sake** — a simple function is better than a Strategy class with one implementation
- ❌ **God Singleton** — global state disguised as a pattern
- ❌ **AbstractFactoryFactory** — over-abstracting what should be a simple `new`
- ❌ **The Blob** — one class/function that does everything
