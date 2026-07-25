---
name: elysiajs
description: ElysiaJS (Bun) best practices — Eden Treaty, plugins, type-safe routes, Elysia validation, and middleware. Use when building ElysiaJS backend APIs. Triggers when working with this framework's files and patterns, not just explicit mentions."
---

# ElysiaJS Best Practices

## Project Structure

```
src/
├── modules/           # Feature modules
│   ├── users/
│   │   ├── routes.ts       # Elysia routes (thin)
│   │   ├── service.ts      # Business logic
│   │   └── repository.ts   # Data access
│   └── orders/
├── plugins/           # Custom Elysia plugins
├── lib/               # Shared utilities
├── db/                # Database schema, migrations
└── index.ts           # App entry point
```

## Route Definition (Type-Safe)

```typescript
import { Elysia, t } from 'elysia';
import { userService } from './service';

const users = new Elysia({ prefix: '/users' })
  .model({
    'user.create': t.Object({
      email: t.String({ format: 'email' }),
      name: t.Optional(t.String({ minLength: 1 })),
    }),
    'user.response': t.Object({
      id: t.String(),
      email: t.String(),
      name: t.Optional(t.String()),
    }),
  })
  .get('/', async ({ query }) => {
    const result = await userService.list(query);
    return result;
  }, {
    query: t.Object({
      page: t.Optional(t.Numeric({ minimum: 1 })),
      limit: t.Optional(t.Numeric({ minimum: 1, maximum: 100 })),
    }),
    response: t.Array(t.Ref('user.response')),
  })
  .post('/', async ({ body }) => {
    const user = await userService.create(body);
    return user;
  }, {
    body: t.Ref('user.create'),
    response: t.Ref('user.response'),
    detail: { summary: 'Create user', tags: ['Users'] },
  });

export { users };
```

## Eden Treaty (Full-Stack Type Safety)

```typescript
// Server (route definition inline above creates Eden types automatically)

// Client — automatically typed
import { treaty } from '@elysiajs/eden';
import type { App } from '../server';

const api = treaty<App>('http://localhost:3000');

// Fully typed — autocomplete for paths, params, response
const { data, error } = await api.users.index.get({ query: { page: 1, limit: 20 } });
// data is typed as UserResponse[]
```

## Plugins Pattern

```typescript
// Custom plugin — encapsulate cross-cutting concerns
import { Elysia } from 'elysia';

const authPlugin = (app: Elysia) =>
  app
    .decorate('auth', new AuthService())
    .derive(({ headers, auth }) => {
      const token = headers.authorization?.split(' ')[1];
      const user = token ? auth.verify(token) : null;
      return { user };
    })
    .onError(({ code, error }) => {
      if (code === 'VALIDATION') return { error: error.message };
    });

// Apply to app
const app = new Elysia()
  .use(authPlugin)
  .use(cors())
  .use(swagger())
  .group('/api/v1', (app) => app.use(users))
  .listen(3000);
```

## Validation

```typescript
import { t } from 'elysia';

// Reusable models
const PaginationModel = t.Object({
  page: t.Numeric({ minimum: 1, default: 1 }),
  limit: t.Numeric({ minimum: 1, maximum: 100, default: 20 }),
});

const ErrorModel = t.Object({
  error: t.String(),
  details: t.Optional(t.Array(t.Object({
    field: t.String(),
    message: t.String(),
  }))),
});

// Use `model()` to share across routes
const app = new Elysia()
  .model({
    pagination: PaginationModel,
    error: ErrorModel,
  });
```

## Error Handling

```typescript
import { Elysia, NotFoundError, ValidationError } from 'elysia';

const app = new Elysia()
  .onError(({ code, error, set }) => {
    switch (code) {
      case 'NOT_FOUND':
        set.status = 404;
        return { error: 'Resource not found' };
      case 'VALIDATION':
        set.status = 422;
        return { error: error.message };
      default:
        set.status = 500;
        console.error(error);
        return { error: 'Internal server error' };
    }
  });
```

## Performance

- **Elysia runs on Bun** — Bun is fast. No need for extra micro-optimizations initially.
- **Use `scoped: true`** for per-request state isolation.
- **Static routes** — use `staticPlugin` for serving files.
- **WebSocket** — built-in WS support, no extra lib needed.

## Testing

```typescript
import { describe, expect, it } from 'bun:test';
import { Elysia } from 'elysia';
import { userRoutes } from './routes';

const app = new Elysia().use(userRoutes);

describe('users', () => {
  it('returns 422 for invalid email', async () => {
    const res = await app
      .handle(new Request('http://localhost/users', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: 'not-an-email' }),
      }));
    expect(res.status).toBe(422);
  });
});
```

## Anti-patterns

- ❌ Business logic in route handlers — extract to service layer
- ❌ No validation on inputs — every route must have a schema
- ❌ Mixing Elysia/Express patterns — Elysia is not Express
- ❌ `any` types — Elysia's superpower is type-safety
- ❌ Global state in plugins — use decorator/derive for per-request state
- ❌ Using `t.Any()` — defeats validation
