# SOLID Principles — Deep Reference

## Single Responsibility Principle (SRP)

> "A class should have one, and only one, reason to change." — Robert C. Martin

**Evolution of the definition:**
- 2000 (PPP): "one reason to change"
- 2008 (Clean Code): class does one thing
- 2017 (Clean Architecture): "responsible to one, and only one, **actor**" — where actor is a person or tightly coupled group (e.g., accounting dept, HR dept, DevOps team)

### Practical Test
If you cannot describe a module's responsibility in one sentence without "and," it violates SRP.

```typescript
// ❌ Two actors: Accounting (calculatePay) + HR (save)
class Employee {
  calculatePay(): Money { ... }
  save(): void { ... }
}

// ✅ Separated by actor
class EmployeePaymentCalc { calculatePay(emp: Employee): Money }
class EmployeeRepository { save(emp: Employee): void }
```

### When SRP Is Violated
- Mixed persistence + business logic in the same class
- A controller that validates, orchestrates, AND formats the response
- A module that imports from both `domain/` and `infra/` packages

---

## Open/Closed Principle (OCP)

> "Software entities should be open for extension, closed for modification." — Bertrand Meyer

New behavior is added through **new code** (new classes, new modules), not by **editing existing, tested code**.

### Strategy Pattern (canonical OCP)
```typescript
// ❌ Closed for extension without modification
function calculateDiscount(type: string, amount: number) {
  if (type === 'none') return 0;
  if (type === 'seasonal') return amount * 0.1;
  if (type === 'loyalty') return amount * 0.2;
}

// ✅ Open for extension — add new strategy, never touch this code
interface DiscountStrategy { apply(amount: number): number;
class SeasonalDiscount implements DiscountStrategy { apply(a) { return a * 0.1 } }
class LoyaltyDiscount implements DiscountStrategy { apply(a) { return a * 0.2 } }
class DiscountCalculator {
  constructor(private strategies: DiscountStrategy[]) {}
  calculate(amount: number) { return this.strategies.reduce((acc, s) => acc + s.apply(amount), 0); }
}
```

### OCP Warning Signs
- `if/else` or `switch` chains on a type/enum field
- Feature toggles mixed into business logic (use plugin architecture)
- Every new feature touches 5+ existing files

---

## Liskov Substitution Principle (LSP)

> "Objects of a superclass shall be replaceable with objects of its subclasses without breaking the system." — Barbara Liskov (1987)

**Revised (2020s):** "Subtypes must be substitutable for their base types." — applies to interfaces, protocols, and type parameters, not just class inheritance.

### The Square-Rectangle Problem (classic violation)
```typescript
class Rectangle { setWidth(w): void; setHeight(h): void }
class Square extends Rectangle {
  setWidth(w) { super.setWidth(w); super.setHeight(w); } // Breaks caller's expectation
}
```

### Rules for Substitutability
1. **Preconditions cannot be strengthened** in the subtype — subtype must accept everything the base accepts.
2. **Postconditions cannot be weakened** — subtype must guarantee at least what the base guarantees.
3. **Invariants must be preserved** — the base class's invariants must hold in the subtype.
4. **History constraint** (Meyer): subtype methods cannot introduce state changes the base type wouldn't allow.

### LSP in Practice
```typescript
// Violation: PostgresUserRepo expects a table name, InMemoryUserRepo doesn't — not substitutable
interface UserRepository {
  find(id: string): User;
}
class PostgresUserRepo implements UserRepository {
  constructor(private table: string) {} // extra constraint
}
```

---

## Interface Segregation Principle (ISP)

> "No client should be forced to depend on methods it does not use." — Robert C. Martin

Fat interfaces force implementors to stub out methods they don't need.

```typescript
// ❌ Fat interface — forces every worker to implement onError, even if they never fail
interface Worker { work(): void; eat(): void; onError(e: Error): void }

// ✅ Segregated — each interface has one job
interface Workable { work(): void }
interface Eatable { eat(): void }
interface ErrorHandler { onError(e: Error): void }
```

### When ISP Is Violated
- A single interface has methods from different concerns (CRUD + reporting + admin)
- Classes implement interface methods as `throw new UnsupportedOperationException`
- Interface methods are unused in 80% of callers (consider splitting input vs output ports)

---

## Dependency Inversion Principle (DIP)

> "Abstractions should not depend on details. Details should depend on abstractions." — Robert C. Martin

**Not to be confused with Dependency Injection** (which is one way to implement DIP).

### High-level policy should not import low-level detail
```typescript
// ❌ High-level module depends on low-level detail
class CreateOrderUseCase {
  private db = new PostgresConnection(); // violates DIP
}

// ✅ Both depend on abstraction
interface OrderRepository { save(order: Order): Promise<void> }
class CreateOrderUseCase {
  constructor(private repo: OrderRepository) {} // depends on abstraction
}
class PostgresOrderRepo implements OrderRepository {} // detail depends on abstraction
```

### The Dependency Rule (Clean Architecture)
Source code dependencies point **inward** — nothing in an inner circle knows about something in an outer circle:
- Domain → no imports from framework/infra/db
- Application → imports domain, declares ports (interfaces)
- Infrastructure → implements ports
- Framework → wires everything at the composition root

---

## Component Principles (for larger systems)

### Cohesion Principles
| Principle | Statement |
|-----------|-----------|
| **REP** (Reuse-Release Equivalence) | The unit of reuse is the unit of release |
| **CCP** (Common Closure Principle) | Classes that change together belong together |
| **CRP** (Common Reuse Principle) | Don't depend on things you don't use |

### Coupling Principles
| Principle | Statement |
|-----------|-----------|
| **ADP** (Acyclic Dependencies Principle) | No cycles in the dependency graph |
| **SDP** (Stable Dependencies Principle) | Depend in the direction of stability |
| **SAP** (Stable Abstractions Principle) | Stable components should be abstract |
