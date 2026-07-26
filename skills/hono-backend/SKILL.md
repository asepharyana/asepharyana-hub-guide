---
name: hono-backend
description: Use when building Hono backend APIs — middleware, RPC, Zod validation, Drizzle integration, and project organization. Triggers from Hono file patterns and project config.
---

# Hono Backend Best Practices

## Project Structure

```
src/
├── modules/           # Feature modules
│   ├── users/
│   │   ├── routes.ts       # Hono routes (thin — validation + delegation)
│   │   ├── service.ts      # Business logic / use cases
│   │   └── repository.ts   # Data access (Drizzle queries)
│   └── orders/
├── middleware/         # Custom middleware
├── lib/               # Shared utilities (env, JWT, hashing)
├── db/                # Drizzle schema, migrations
└── index.ts           # App entry + composition root
```

## Route Definition

```typescript
import { Hono } from 'hono';
import { z } from 'zod';
import { zValidator } from '@hono/zod-validator';
import { userService } from './service';
import type { Env } from '../lib/env';

const users = new Hono<Env>()
  .get('/', async (c) => {
    const page = Number(c.req.query('page') || '1');
    const limit = Number(c.req.query('limit') || '20');
    const result = await userService.list({ page, limit });
    return c.json(result);
  })
  .post('/', zValidator('json', CreateUserSchema), async (c) => {
    const body = c.req.valid('json');
    const user = await userService.create(body);
    return c.json(user, 201);
  })
  .get('/:id', async (c) => {
    const id = c.req.param('id');
    const user = await userService.findById(id);
    if (!user) return c.json({ error: 'Not found' }, 404);
    return c.json(user);
  });

export { users };
```

## Zod Validation

```typescript
import { z } from 'zod';

// Define at the boundary
export const CreateUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100).optional(),
  role: z.enum(['admin', 'user']).default('user'),
});

export const PaginationSchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

// Infer types
export type CreateUserInput = z.infer<typeof CreateUserSchema>;
```

## Hono RPC (Type-Safe Client)

```typescript
// Server
import { hono } from 'hono';
import { routes } from './routes';

const app = new Hono().route('/api', routes);
export type App = typeof app;

// Client (no treaty needed — direct fetch wrapper)
import { hc } from 'hono/client';
import type { App } from '../server';

const client = hc<App>('http://localhost:3000');
const res = await client.api.users.$post({
  json: { email: 'test@example.com', name: 'Alice' },
});
// res is fully typed — status codes, response body
```

## Middleware

```typescript
import { Hono } from 'hono';

const app = new Hono()
  // Built-in
  .use('*', cors())
  .use('*', logger())

  // Custom
  .use('*', async (c, next) => {
    const start = Date.now();
    await next();
    const ms = Date.now() - start;
    c.header('X-Response-Time', `${ms}ms`);
  })

  // Auth middleware
  .use('/api/*', async (c, next) => {
    const auth = c.req.header('Authorization');
    if (!auth?.startsWith('Bearer ')) return c.json({ error: 'Unauthorized' }, 401);
    const user = await verifyToken(auth.slice(7));
    if (!user) return c.json({ error: 'Invalid token' }, 401);
    c.set('user', user);
    await next();
  });
```

## Error Handling

```typescript
import { HTTPException } from 'hono/http-exception';

app.onError((err, c) => {
  if (err instanceof HTTPException) {
    return c.json({ error: err.message }, err.status);
  }
  console.error(err); // log unexpected errors
  return c.json({ error: 'Internal server error' }, 500);
});

// In routes
app.post('/orders', async (c) => {
  const result = await orderService.create(body);
  if (!result.ok) {
    throw new HTTPException(422, { message: result.error.message });
  }
  return c.json(result.value, 201);
});
```

## OpenAI / Swagger Integration

```typescript
import { OpenAPIHono } from '@hono/zod-openapi';

const app = new OpenAPIHono();

app.openapi(
  createRoute({
    method: 'post',
    path: '/users',
    request: { body: { content: { 'application/json': { schema: CreateUserSchema } } } },
    responses: {
      201: { description: 'User created', content: { 'application/json': { schema: UserSchema } } },
      422: { description: 'Validation error' },
    },
  }),
  async (c) => {
    const body = c.req.valid('json');
    const user = await userService.create(body);
    return c.json(user, 201);
  },
);
```

## Testing

```typescript
import { describe, expect, it } from 'bun:test';
import { app } from '../src/index';

describe('users', () => {
  it('creates a user', async () => {
    const res = await app.request('/users', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'test@example.com' }),
    });
    expect(res.status).toBe(201);
    const body = await res.json();
    expect(body.email).toBe('test@example.com');
  });
});
```

## Anti-patterns

- ❌ Business logic in route handlers — routes validate + delegate
- ❌ No Zod validation on inputs — every route that accepts input must validate
- ❌ `c.req.raw` instead of Hono's `c.req.json/query/valid`
- ❌ Mixing Hono and Express middleware patterns
- ❌ Global error handled only at route level — use app-level `onError`
- ❌ Not using `c.set` for typed variables — declare `Env` type with bindings/variables
