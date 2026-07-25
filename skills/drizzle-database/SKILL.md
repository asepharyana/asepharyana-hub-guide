---
name: drizzle-database
description: Drizzle ORM best practices — schema design, queries, migrations, relations, and performance. Use when designing database schemas, writing Drizzle queries, managing migrations. Triggers when working with this framework's files and patterns, not just explicit mentions."
---

# Drizzle ORM Best Practices

## Schema Design

```typescript
import { pgTable, serial, text, timestamp, boolean, integer, jsonb } from 'drizzle-orm/pg-core';
import { relations } from 'drizzle-orm';

// Tables with explicit foreign keys
export const users = pgTable('users', {
  id: serial('id').primaryKey(),
  email: text('email').notNull().unique(),
  name: text('name'),
  role: text('role', { enum: ['admin', 'user'] }).default('user').notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export const orders = pgTable('orders', {
  id: serial('id').primaryKey(),
  userId: integer('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  status: text('status', { enum: ['pending', 'paid', 'shipped'] }).default('pending').notNull(),
  total: integer('total').notNull(), // in cents
  metadata: jsonb('metadata'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

// Relations
export const usersRelations = relations(users, ({ many }) => ({
  orders: many(orders),
}));

export const ordersRelations = relations(orders, ({ one }) => ({
  user: one(users, { fields: [orders.userId], references: [users.id] }),
}));
```

**Rules:**
- `serial` for auto-increment PKs, `uuid` for distributed/public IDs.
- `timestamp` with `defaultNow()` for created/updated.
- JSONB for flexible metadata (Postgres). Text JSON for SQLite.
- Enums as `text` with `enum` constraint (not Postgres `CREATE TYPE` — easier migrations).

## Queries

### Basic CRUD
```typescript
import { eq, and, or, like, gte, lte, asc, desc, sql, inArray } from 'drizzle-orm';

// Create
const [user] = await db.insert(users).values({ email: 'a@b.com' }).returning();

// Read
const allUsers = await db.select().from(users);
const user = await db.select().from(users).where(eq(users.id, id)).limit(1);
const admins = await db.select().from(users).where(eq(users.role, 'admin')).orderBy(desc(users.createdAt));

// Update
const [updated] = await db.update(users).set({ name }).where(eq(users.id, id)).returning();

// Delete
await db.delete(users).where(eq(users.id, id));
```

### Joins
```typescript
// One-to-many
const result = await db.select()
  .from(users)
  .leftJoin(orders, eq(users.id, orders.userId))
  .where(eq(users.id, id));

// With relations (prepared — uses multiple queries or JOINs internally)
const userWithOrders = await db.query.users.findFirst({
  where: eq(users.id, id),
  with: { orders: { limit: 5 } },
});
```

### Aggregations
```typescript
import { count, sum, avg, min, max, sql } from 'drizzle-orm';

const stats = await db.select({
  total: count(),
  totalRevenue: sum(orders.total),
  avgOrderValue: avg(orders.total),
  byStatus: sql`${orders.status}::text`,
}).from(orders)
  .groupBy(orders.status);
```

## Migrations (drizzle-kit)

```jsonc
// drizzle.config.ts
import { defineConfig } from 'drizzle-kit';

export default defineConfig({
  dialect: 'postgresql',
  schema: './src/db/schema/*.ts',
  out: './src/db/migrations',
  dbCredentials: { url: process.env.DATABASE_URL! },
});
```

```bash
# Commands
bunx drizzle-kit generate     # Generate migration from schema changes
bunx drizzle-kit migrate      # Apply migrations to database
bunx drizzle-kit push         # Push schema (dev only — no migration files)
bunx drizzle-kit studio       # Drizzle Studio (GUI for DB inspection)
```

**Rules:**
- Generate migrations, then apply. Use `drizzle-kit push` only in dev.
- Code review migration files before applying to production.
- Write custom SQL for complex migrations (backfills, data transformations).
- Never edit generated migration files manually (unless you know what you're doing).

## Performance

### Indexes
```typescript
import { index, uniqueIndex } from 'drizzle-orm/pg-core';

export const users = pgTable('users', {
  id: serial('id').primaryKey(),
  email: text('email').notNull().unique(),
  // ...
}, (table) => ({
  emailIdx: uniqueIndex('users_email_idx').on(table.email),
  roleIdx: index('users_role_idx').on(table.role),
  // Composite index for common queries
  createdRoleIdx: index('users_created_role_idx').on(table.createdAt, table.role),
}));
```

### N+1 Prevention
```typescript
// ❌ N+1 — one query per order item
for (const order of orders) {
  const items = await db.select().from(orderItems).where(eq(orderItems.orderId, order.id));
}

// ✅ Eager with `IN`
const orderIds = orders.map(o => o.id);
const allItems = await db.select().from(orderItems).where(inArray(orderItems.orderId, orderIds));
```

### Prepared Statements
```typescript
const findUserByEmail = db.select().from(users).where(eq(users.email, sql.placeholder('email'))).prepare();

// Reuse
const user1 = await findUserByEmail.execute({ email: 'a@b.com' });
const user2 = await findUserByEmail.execute({ email: 'c@d.com' });
```

## Repository Pattern

```typescript
// Always accessed through repository — never direct db calls from routes
export class UserRepository {
  constructor(private db: DB) {}

  async findByEmail(email: string): Promise<User | null> {
    const result = await this.db.select().from(users).where(eq(users.email, email)).limit(1);
    return result[0] ?? null;
  }

  async create(input: CreateUserInput): Promise<User> {
    const [user] = await this.db.insert(users).values(input).returning();
    return user;
  }

  async update(id: number, data: Partial<User>): Promise<User | null> {
    const [user] = await this.db.update(users).set({ ...data, updatedAt: new Date() }).where(eq(users.id, id)).returning();
    return user ?? null;
  }
}
```

## Anti-patterns

- ❌ Raw SQL strings instead of Drizzle query builder when Drizzle provides it
- ❌ `select *` in production — name specific columns
- ❌ No repository layer — Drizzle queries in route handlers
- ❌ Missing indexes on foreign keys and filtered columns
- ❌ `await` in loops for sequential queries — use `Promise.all` or `IN` queries
- ❌ Editing generated migration files
- ❌ Using `serial` for user-facing IDs — use `uuid` for public IDs
