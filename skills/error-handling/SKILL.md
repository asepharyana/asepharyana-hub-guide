---
name: error-handling
description: Best practices for error handling across languages — exceptions, Result types, input validation, error boundaries, null safety, and observability. Use when designing error strategies, writing validation logic, handling API errors, or whenever the user mentions "error handling," "exception," "try-catch," "Result," "Option," "Either," "null check," "validation," "panic," or "error boundary."
---

# Error Handling

Good error handling makes failures predictable, debuggable, and safe.

## Core Principles

1. **Fail fast** — detect and report errors at the nearest boundary.
2. **Never swallow errors** — empty catches, ignored error returns, and silent fallbacks hide bugs.
3. **Errors are values** — propagate them explicitly (Result types, error returns) over exceptions for normal code paths.
4. **Recoverable vs unrecoverable** — use Result/Option/recovery for expected failures; crash for truly unrecoverable states.

## Pattern by Context

```
Context Layer     │ Pattern
──────────────────┼──────────────────────
Domain / Business │ Result types — expected business logic failures
Application       │ Exceptions (wrapped) — infrastructure failures
API Boundary      │ Caught + mapped to error responses
UI Layer          │ Error boundaries / graceful degradation
```

### Use Result Types (preferred) for Business Logic
```typescript
// TypeScript — discriminated union
type Result<T, E> = { ok: true; value: T } | { ok: false; error: E };

function createOrder(input: unknown): Result<Order, ValidationError> {
  if (!input || typeof input !== 'object') return { ok: false, error: { field: 'input', message: 'Invalid' } };
  return { ok: true, value: new Order(input) };
}
```

```rust
// Rust — native Result
fn create_order(input: CreateOrderInput) -> Result<Order, ValidationError> {
    validate(input)?;
    Ok(Order::new(input))
}
```

```python
# Python — custom exceptions for recoverable failures
class ValidationError(Exception): ...
class NotFoundError(Exception): ...

def create_order(input: dict) -> Order:
    if not input.get("items"):
        raise ValidationError("items required")
    return Order(items=input["items"])
```

### Use Exceptions for Infrastructure Failures
```typescript
class DatabaseConnectionError extends Error {
  constructor(public readonly cause: unknown) {
    super('Database connection failed');
  }
}

class CreateOrderUseCase {
  async execute(input: CreateOrderInput): Promise<Result<Order, AppError>> {
    try {
      const user = await this.userRepo.findById(input.userId);
      if (!user) return { ok: false, error: new NotFoundError('User') };
      return { ok: true, value: Order.create(user, input.items) };
    } catch (e) {
      throw new DatabaseConnectionError(e); // wrap tech errors
    }
  }
}
```

## Input Validation

- **Validate at system boundaries** — API entry points, CLI args, file reads, form submissions.
- **Use validation libraries** — Zod (TS), Pydantic (Python), serde (Rust), go-playground/validator.
- **Don't validate in domain entities** — validate at boundary, pass typed objects inward.
- **Fail early** — validate all fields, return all errors, not just the first.

```typescript
// TS with Zod
const CreateUserSchema = z.object({
  email: z.string().email(),
  age: z.number().int().positive().max(150),
});
type CreateUserInput = z.infer<typeof CreateUserSchema>;

app.post('/users', (c) => {
  const parsed = CreateUserSchema.safeParse(await c.req.json());
  if (!parsed.success) return c.json({ errors: parsed.error.flatten() }, 400);
  const result = await createUserUseCase.execute(parsed.data);
  if (!result.ok) return c.json({ error: result.error.message }, 422);
  return c.json(result.value, 201);
});
```

## Null Safety

- **Don't return null** — return `Option<T>`, `undefined`, empty collection, or throw.
- **Don't accept null** — fail fast at the boundary if a parameter is required.
- **Languages with null safety**: enable strict mode (TypeScript `strict`, Kotlin, Swift, Rust).
- **Languages without**: use `Optional` wrappers.

## Error Boundaries (UI)

```typescript
// React — catch rendering errors
class ErrorBoundary extends React.Component {
  state = { error: null };
  static getDerivedStateFromError(error: Error) {
    return { error };
  }
  render() {
    if (this.state.error) return <ErrorFallback error={this.state.error} />;
    return this.props.children;
  }
}
```

## Observability in Errors

- **Every error should be logged** with context: operation, input (sanitized), stack trace.
- **Structured logging** — machine-readable error fields, not just strings.
- **Correlation IDs** — trace errors across services (Dapr/Jaeger trace ID).
- **Never log secrets** — sanitize errors before logging.

## Language Quick Reference

| Language | Pattern | Null Safety |
|----------|---------|-------------|
| TypeScript | Result unions or exceptions | `strict: true`, optional chaining |
| Python | Exceptions | Optional[x] (type hint only) |
| Rust | `Result<T, E>`, `Option<T>` | Ownership system |
| Go | `value, err := f()` | No — check `err != nil` |

## Anti-patterns

- ❌ **Empty catch** (`catch(e) {}`) — hides errors.
- ❌ **Swallowing errors** — returning default values silently.
- ❌ **Using exceptions for control flow** — exceptions should never be expected.
- ❌ **Generic error messages** — `"Something went wrong"` with no context.
- ❌ **Mixing error strategies** — some functions return null, some throw, some return Result.
- ❌ **Too broad catches** — `catch (Exception e)` catches absolutely everything.
