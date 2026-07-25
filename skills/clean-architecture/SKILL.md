---
name: clean-architecture
description: Apply Clean Architecture, hexagonal architecture, and SOLID principles when designing system boundaries, modules, or microservices. Use when structuring a new service, deciding what a component should own, untangling framework coupling, or whenever the user mentions "clean architecture," "hexagonal architecture," "onion architecture," "ports and adapters," "SOLID," "Dependency Rule," or "architecture boundaries."
---

# Clean Architecture

Keep business rules independent of frameworks, databases, and UI.

## The Dependency Rule

**Source code dependencies must point inward.** Nothing in an inner circle can know about something in an outer circle.

```
┌──────────────────────────────┐
│  Framework / DB / UI / IO     │  ← outer: frameworks, drivers, devices
│ ┌──────────────────────────┐  │
│ │  Interface Adapters      │  │  ← presenters, controllers, gateways
│ │ ┌──────────────────────┐ │  │
│ │ │  Application (Use Cases) │ │  ← orchestrate business flows
│ │ │ ┌──────────────────┐ │ │  │
│ │ │ │  Domain / Entities│ │ │  │  ← pure business rules, no deps
│ │ │ └──────────────────┘ │ │  │
│ │ └──────────────────────┘ │  │
│ └──────────────────────────┘  │
└──────────────────────────────┘
```

## Key Rules

1. **Domain layer** contains business entities and value objects. Zero framework imports. Zero database imports. Pure types and functions.
2. **Application layer** contains use cases — orchestrate domain objects to fulfill business flows. Depends only on domain. Declares ports (interfaces) for IO.
3. **Interface adapters** translate between use cases and the outside world — controllers, presenters, gateways. Depends on application layer + frameworks.
4. **Infrastructure/Framework layer** implements the ports declared by the application layer — database repos, HTTP clients, message queues.
5. **Screaming Architecture:** the project structure should scream "this is a [domain context]" — not "this is a Spring/Next.js/Django project."

## How to Check

- Can you swap the database without changing business logic? If not, boundary is violated.
- Can you unit-test a use case without spinning up a framework? If not, your use case depends on infrastructure.
- Do business entities import anything from the web framework or ORM? If so, revert that dependency.

## Practical Patterns

### Port-Adapter
```typescript
// Domain/Application port (declared here, implemented outside)
interface UserRepository {
  findById(id: string): Promise<User | null>;
}
// Infrastructure adapter (implemented in infra layer)
class PostgresUserRepository implements UserRepository { ... }
```

### Use Case
```typescript
class CreateOrderUseCase {
  constructor(private readonly repo: OrderRepository) {}
  async execute(input: CreateOrderInput): Promise<Order> {
    const order = Order.create(input.items, input.customerId);
    return this.repo.save(order);
  }
}
```

### Dependency Injection
Wire dependencies at the composition root — never in use cases or domain.
```typescript
// Composition Root
const orderRepo = new PostgresOrderRepository(db);
const createOrder = new CreateOrderUseCase(orderRepo);
```

## SOLID (Quick Ref)

- **SRP:** A class has one reason to change (one actor).
- **OCP:** Open for extension, closed for modification (polymorphism + strategy).
- **LSP:** Subtypes must be substitutable for their base types.
- **ISP:** Don't depend on interfaces you don't use (keep interfaces focused).
- **DIP:** Depend on abstractions, not concretions. Business rules don't import frameworks.

## Deeper Reference

When the task calls for it, load:

- **[references/solid.md](references/solid.md)** — Full SOLID treatment (SRP, OCP, LSP, ISP, DIP). Component principles (REP, CCP, CRP, ADP, SDP, SAP). Examples for each principle, historical evolution, and practical tests for violations.

## Ask When Ambiguous

When the module boundary is unclear, ask rather than guessing:
- "Should this live in domain or application layer? Is it a pure business rule or an orchestration concern?"
- "Is this a port (interface declared by application) or an adapter (implementation in infrastructure)?"
- If you're not sure which layer a piece of logic belongs to, flag it with a brief question. A wrong boundary assumption is expensive to refactor later.

## Anti-patterns

- ❌ Business logic in route handlers or controllers
- ❌ ORM entities directly exposed to the UI
- ❌ Database queries mixed into use cases
- ❌ Framework decorators on domain entities
- ❌ "Everything is a CRUD" — missing use case layer
