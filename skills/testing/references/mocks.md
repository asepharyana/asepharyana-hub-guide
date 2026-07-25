# Test Doubles — Mock, Stub, Fake, Spy, Dummy

Understanding the differences prevents tests that are brittle, misleading, or hard to maintain.

## The Taxonomy (Meszaros, xUnit Test Patterns)

| Term | What It Is | When to Use |
|------|-----------|-------------|
| **Dummy** | Passed but never used. Fills parameter lists. | Satisfy constructor/parameter requirements that aren't exercised by this test. |
| **Fake** | Working (but simplified) implementation. Uses real logic, just lighter. | In-memory DB, fake HTTP client, fake file system. **Preferred over mocks whenever possible.** |
| **Stub** | Returns canned answers to calls made during the test. | When you need a consistent response (user exists, payment succeeded). |
| **Mock** | Pre-programmed with expectations about *what calls will be made*. Verifies interactions. | When you need to verify that something was called correctly (e.g., notification was sent). |
| **Spy** | Records calls for later verification. Wraps a real object. | When you want the real behavior but also need to verify calls. |

## The Continuum of Fidelity

```
Minimal ──────────────────────────────────────────────→ Max fidelity
Dummy → Stub → Spy → Mock → Fake (in-memory) → Real (integration)
```

**Rule of thumb:** Use the **highest fidelity that's still fast and deterministic**. Prefer Fakes → Stubs → Mocks → Dummies. Default to fakes.

## Code Examples

### Dummy
```typescript
// Used only to satisfy type signature — never read in this test
it('creates order with items', async () => {
  const dummyNotifier = { send: vi.fn() }; // never called in this path
  const order = new CreateOrderUseCase(new InMemoryOrderRepo(), dummyNotifier);
  // ... test only cares about order creation, not notification
});
```

### Fake
```typescript
// Has real behavior, just in-memory. No DB, no network.
class FakeUserRepository implements UserRepository {
  private users = new Map<string, User>();

  async findById(id: string) { return this.users.get(id) ?? null; }
  async save(user: User) { this.users.set(user.id, user); return user; }
  async exists(email: string) { return [...this.users.values()].some(u => u.email === email); }
}

it('creates user', async () => {
  const repo = new FakeUserRepository();
  const svc = new UserService(repo);
  const user = await svc.create('a@b.com');
  expect(user.email).toBe('a@b.com');
  expect(await repo.exists('a@b.com')).toBe(true);
});
```

### Stub
```typescript
// Returns hardcoded answers — no real behavior, no verification
const stubbedRepo = {
  findById: vi.fn().mockResolvedValue({ id: '1', name: 'Alice' }),
  save: vi.fn().mockResolvedValue({ id: '1', name: 'Alice' }),
};

it('returns user when found', async () => {
  const svc = new UserService(stubbedRepo);
  const user = await svc.findById('1');
  expect(user?.name).toBe('Alice');
});
```

### Mock
```typescript
// Sets expectations about interactions. Use sparingly.
it('sends notification on order', async () => {
  const notifyMock = vi.fn();
  const svc = new OrderService(new FakeOrderRepo(), notifyMock);
  await svc.create({ userId: '1', items: [...] });
  expect(notifyMock).toHaveBeenCalledWith('1', expect.stringContaining('order'));
});
```

### Spy
```typescript
// Wraps real behavior, records calls
const repo = new FakeUserRepository();
const spy = vi.spyOn(repo, 'save');
const svc = new UserService(repo);
await svc.create('a@b.com');
expect(spy).toHaveBeenCalledOnce();
```

## When to Mock vs Use Fakes

| Scenario | Use |
|----------|-----|
| The collaborator is deterministic (math, calculation) | Fake or real |
| The collaborator touches external systems (DB, network, disk) | Fake (in-memory) or mock |
| You need to verify something was called | Mock or spy |
| You need a consistent response | Stub |
| The collaborator doesn't matter for this test | Dummy or ignore |

## Mocking Best Practices

1. **Mock roles, not objects** — mock the interface/port, not the concrete class.
2. **Don't mock domain objects** — use real entities/value objects. They have no IO, so there's no reason to mock them.
3. **Over-mocking is a smell** — if tests break on every refactor, you're testing implementation, not behavior.
4. **One mock per test, ideally** — many mocks means many expectations, means fragile tests.
5. **Prefer `mockResolvedValue` (once) over `mockResolvedValue` (always)** — be explicit about test context.

### The Over-Mocking Trap

```typescript
// ❌ Over-mocked — tests break when internals change
it('creates order', async () => {
  const repo = { save: vi.fn() };
  const calc = { calculate: vi.fn().mockReturnValue(100) };
  const notify = { send: vi.fn() };
  // ... mocks everywhere, tests know the implementation

// ✅ Better — fakes for real behavior, mock only for verification
it('creates order', async () => {
  const repo = new FakeOrderRepo();
  const calc = new PriceCalculator(); // real
  const notify = vi.fn(); // mock only what you need to verify
  // ...
});
```

## Testing Anti-Patterns

- ❌ **Mocking everything** — tests that don't test the real behavior
- ❌ **Mocking the SUT** — mocking the class you're testing
- ❌ **Over-specification** — `expect(mock).toHaveBeenCalledTimes(1)` when "at least once" is fine
- ❌ **Conditional mocks** — `mockReturnValueOnce` chains that break when order changes
- ❌ **Partial mocks** — mocking some methods but not others on the real object (spy is better)
