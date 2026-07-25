---
name: testing
description: Best practices for software testing — TDD, test pyramid, F.I.R.S.T. principles, mocking strategies, and test organization. Use when writing tests, designing test strategy, refactoring under test. Detects from code context and project files — not dependent on specific language keywords."
---

# Testing Best Practices

## The Test Pyramid

```
     ╱╲
    ╱ E2E ╲          Few — critical user journeys
   ╱────────╲
  ╱ Integration ╲    Some — API, DB, external service boundaries
 ╱────────────────╲
╱   Unit Tests     ╲  Many — domain logic, utilities, pure functions
╱────────────────────╲
```

- **Unit tests** — fast, isolated, test one behavior. 70%+ of tests.
- **Integration tests** — test boundaries (DB queries, API contracts, file IO).
- **E2E tests** — critical paths only. Slow and brittle — minimize.

## Three Laws of TDD

1. Don't write production code until you have a failing test.
2. Don't write more of a test than is sufficient to fail.
3. Don't write more production code than is sufficient to pass.

The cycle: Red (failing test) → Green (passing) → Refactor.

## F.I.R.S.T. Principles

- **Fast** — tests run quickly. If slow, they won't be run.
- **Independent** — no test depends on another. Any order, any subset.
- **Repeatable** — same result every time, in any environment.
- **Self-validating** — pass/fail is binary. No manual inspection.
- **Timely** — written *before* (or at the same time as) production code.

## Test Structure

### Arrange-Act-Assert (AAA)
```typescript
// Arrange
const user = new User('test@example.com');
const service = new AuthService(mockRepo);

// Act
const result = await service.login(user);

// Assert
expect(result.success).toBe(true);
```

### Naming
```typescript
describe('CreateOrderUseCase', () => {
  it('throws when inventory is insufficient', async () => { ... });
  it('creates order with correct total', async () => { ... });
  it('deducts inventory on successful order', async () => { ... });
});
```

### One assertion per test? No — one *concept* per test.
Group related assertions for the same behavior:
```typescript
it('returns complete user profile', () => {
  const profile = service.getProfile(userId);
  expect(profile.name).toBe('Alice');
  expect(profile.email).toBe('alice@example.com');
  expect(profile.role).toBe('admin');
});
```

## What to Test

| Test | What | Example |
|------|------|---------|
| Domain logic | Business rules, calculations, validations | `PriceCalculator.calculateTotal()` |
| Edge cases | Empty state, null, max values, error paths | `Order.create({ items: [] })` |
| Public contracts | API endpoints, method signatures | `POST /orders returns 201` |
| Error handling | Expected failures, retry, fallback | `Repository.save() when DB down` |

## What NOT to Test

- ❌ Framework internals (React, Express, Drizzle — they have their own tests)
- ❌ Implementation details (private methods — test through public API)
- ❌ Simple one-liners with no logic (`getters`, `toString`)
- ❌ Configuration constants

## Mocking Strategies

- **Mock external boundaries only** — database, network, filesystem, clock.
- **Don't mock domain objects** — use real entities/value objects.
- **Mock roles, not objects** — mock the interface/port, not the concrete class.
- **Prefer fakes over mocks** for test doubles that have real behavior (e.g., in-memory DB).
- **Over-mocking is a smell** — tests that break on every refactor are testing implementation, not behavior.

### Mock Levels
```typescript
// ❌ Over-mocked: tests break on refactor, test internal wiring
const mockRepo = { save: vi.fn() };
const useCase = new CreateOrder(mockRepo);
mockRepo.save.mockResolvedValueOnce({ id: '1' });

// ✅ Better: test behavior through real fakes
class InMemoryOrderRepo implements OrderRepository {
  private orders = new Map<string, Order>();
  async save(o: Order) { this.orders.set(o.id, o); return o; }
  async findById(id: string) { return this.orders.get(id) ?? null; }
}
```

## Test Coverage Guidelines

- **80-90% line coverage** is healthy for production code
- **100% is a red flag** — likely testing trivia and implementation details
- **Focus coverage on domain logic** (business rules) over infrastructure wrappers
- **Coverage is a lagging indicator** — good tests aren't about coverage, they're about confidence

## Deeper Reference

When the task calls for it, load:

- **[references/mocks.md](references/mocks.md)** — Complete test double taxonomy (Dummy, Fake, Stub, Mock, Spy). Code examples, when to use each, over-mocking traps, and anti-patterns.

## Language-Specific Directives

- **TypeScript:** Use Vitest over Jest (faster, ESM-native). Use `vi.fn()` sparingly.
- **Python:** Use pytest (not unittest). Fixtures over setup/teardown.
- **Rust:** Unit tests inline in module. Integration tests in `tests/` directory.
- **Go:** Tests in `_test.go` files. Table-driven tests for multiple cases.
