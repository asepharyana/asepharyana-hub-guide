---
name: typescript
description: TypeScript best practices — strict mode, type patterns, generics, module system, async patterns, and project organization. Use when writing TypeScript code, configuring tsconfig, or whenever the user mentions "TypeScript," "TS," "ESM," "deno," "bun," "type annotation," "generics," "interface," "type," "strict mode," or "tsconfig."
---

# TypeScript Best Practices

## Configuration

```jsonc
// tsconfig.json — strict mode is non-negotiable
{
  "compilerOptions": {
    "strict": true,           // Enable all strict checks
    "noUncheckedIndexedAccess": true, // Accessing arrays/objects is safe
    "exactOptionalPropertyTypes": true,
    "noImplicitReturns": true,
    "esModuleInterop": true,
    "moduleResolution": "bundler", // or "node16" for ESM
    "target": "ESNext",
    "isolatedModules": true,
    "skipLibCheck": true      // Fast, skip node_modules type check
  }
}
```

## Types vs Interfaces

```typescript
// Prefer `interface` for public API contracts (extends, implements)
interface User {
  id: string;
  email: string;
}

// Prefer `type` for unions, intersections, complex types
type Result<T> = { ok: true; value: T } | { ok: false; error: Error };
type Status = 'active' | 'inactive' | 'suspended';
type CreateUserInput = { name: string } & BaseInput;
```

**Rule of thumb:** `interface` for objects, `type` for everything else.

## Generics — Use Intentionally

```typescript
// ✅ Good — specific enough
function mapValues<K extends string, V, R>(
  obj: Record<K, V>,
  fn: (value: V, key: K) => R
): Record<K, R> { ... }

// ❌ Bad — over-generic, loses type info
function identity(value: any): any { ... }

// ✅ Good — preserves type
function identity<T>(value: T): T { return value; }
```

## Async Patterns

- **Top-level await** — OK in ESM modules, but prefer `main()` pattern.
- **Promise.all for parallel** — don't `await` in sequence if requests are independent.
- **Errors** — always handle Promise rejections. No unhandled promises.
- **Async iterators** — `for await (const item of stream)` for paginated data.

```typescript
// ❌ Sequential
const a = await fetchA();
const b = await fetchB(); // waits for A

// ✅ Parallel
const [a, b] = await Promise.all([fetchA(), fetchB()]);
```

## No `any`

```typescript
// ❌ Never — disables all type checks
function parse(input: any): any { ... }

// ✅ Use `unknown` instead — forces type narrowing before use
function parse(input: unknown): Result<Data, ParseError> { ... }

// ✅ Use `never` for exhaustive checks
function assertNever(x: never): never { throw new Error('Unexpected: ' + x); }
```

## Module System

- **ESM only.** No `require()`. Use `import` / `export`.
- **Named exports** over default exports (better tree-shaking, rename safety).
- **Barrel exports** (`index.ts`) — use sparingly. Can cause circular deps and slow builds.
- **Path aliases** — `@/` or `~/` for internal imports. Configure in tsconfig.

```typescript
// Always use .js/.mjs extension for relative imports in ESM
import { User } from './user.js';
import { createOrder } from '@/use-cases/create-order.js';
```

## Project Structure

```
src/
├── domain/           # Pure business logic, entities, value objects
│   ├── user.ts
│   └── order.ts
├── application/      # Use cases, ports
│   ├── create-order.ts
│   └── user-repository.ts  # port (interface)
├── infrastructure/   # Adapters (DB, HTTP, queue)
│   └── postgres-user-repo.ts
├── api/              # HTTP handlers, middleware
│   ├── routes/
│   └── middleware/
├── lib/              # Shared utilities (pure, no framework deps)
└── index.ts          # Composition root, entry point
```

## Enum vs Union

```typescript
// ❌ Enums — runtime overhead, not tree-shakeable, const enum has issues
enum Status { Active, Inactive }

// ✅ Union types — zero-cost, works everywhere
type Status = 'active' | 'inactive';

// ✅ Const objects with `as const` — when you need both type and runtime
const STATUS = { ACTIVE: 'active', INACTIVE: 'inactive' } as const;
type Status = (typeof STATUS)[keyof typeof STATUS];
```

## Branded Types for IDs

```typescript
// Type-safe IDs — prevents mixing up different entity IDs
type Brand<T, B> = T & { __brand: B };
type UserId = Brand<string, 'UserId'>;
type OrderId = Brand<string, 'OrderId'>;

function getUser(id: UserId) { ... }
function getOrder(id: OrderId) { ... }
getUser('abc' as UserId); // OK
getUser(orderId); // ❌ Type error — OrderId not assignable to UserId
```

## Error Handling

```typescript
// Domain errors as discriminated unions
type CreateUserError = ValidationError | DuplicateEmailError | DatabaseError;
type ValidationError = { kind: 'validation'; field: string; message: string };
type DuplicateEmailError = { kind: 'duplicate_email'; email: string };

function createUser(input: CreateUserInput): Result<User, CreateUserError> { ... }

// Use branded Result in use cases, throw for unexpected infrastructure errors
class DatabaseError extends Error { constructor(cause: unknown) { super(); this.cause = cause; } }
```

## Testing

- **Vitest** over Jest (faster, ESM-native, TypeScript-native).
- **`vi.fn()`** for mocks. Prefer fakes (in-memory implementations).
- **Cover 'as const', `satisfies`, `z.infer` patterns** — they are compile-time only.

## Anti-patterns

- ❌ `any` — disables the type system entirely
- ❌ `as` type assertions (`value as Type`) — use proper narrowing or Zod parsing
- ❌ `!` non-null assertion (`user!.name`) — defeats strict null checks
- ❌ Namespace — use ES modules instead
- ❌ `Function` type — use typed function signature `(args: Args) => Result`
- ❌ Optional chaining chains — `a?.b?.c?.d` is fragile. Narrow earlier.
