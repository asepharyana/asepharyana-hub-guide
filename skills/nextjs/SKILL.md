---
name: nextjs
description: Next.js App Router best practices — server components, client components, data fetching, routing, middleware, and deployment. Use when building Next.js applications. Triggers when working with this framework's files and patterns, not just explicit mentions.js," "App Router," "server component," "client component," "SSR," "SSG," "ISR," "Middleware," "layout," "page," "route handler," "next/navigation," or "server actions."
---

# Next.js Best Practices

## App Router Architecture

```
app/
├── (auth)/                  # Route group — no URL segment
│   ├── login/
│   │   └── page.tsx
│   └── register/
│       └── page.tsx
├── (dashboard)/
│   ├── layout.tsx           # Shared layout for all dashboard pages
│   ├── page.tsx             # /dashboard
│   └── settings/
│       └── page.tsx
├── api/                     # API route handlers
│   └── users/
│       └── route.ts
├── layout.tsx               # Root layout
└── page.tsx                 # Home page (/)
```

## Server Components (Default)

**Every component in App Router is a Server Component by default.** Use Client Components only when needed.

Server components can:
- ✅ `async` component — `async function Page() { const data = await fetch(); ... }`
- ✅ Direct database access — `await db.select().from(users)`
- ✅ Import server-only modules (DB, filesystem, tokens)
- ✅ `{children}` render client components

```typescript
// ✅ Server Component — no "use client" directive
export default async function UserPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const user = await db.select().from(users).where(eq(users.id, Number(id))).limit(1);
  if (!user[0]) return notFound();

  return (
    <div>
      <h1>{user[0].name}</h1>
      <UserActions user={user[0]} /> {/* Client component */}
    </div>
  );
}
```

## Client Components — When to Use

Add `'use client'` only when you need:
- 🔴 `useState` / `useReducer` — interactive UI state
- 🔴 `useEffect` — browser-side effects or synchronization
- 🔴 `useRouter` — programmatic navigation
- 🔴 Event handlers — `onClick`, `onSubmit`, `onChange`
- 🔴 Browser-only APIs — `localStorage`, `setInterval`, `IntersectionObserver`
- 🔴 Custom hooks that use any of the above

```typescript
'use client';

import { useState } from 'react';

export function UserActions({ user }: { user: User }) {
  const [isEditing, setIsEditing] = useState(false);
  return (
    <button onClick={() => setIsEditing(true)}>Edit {user.name}</button>
  );
}
```

## Data Fetching Patterns

### Server-side (preferred)
```typescript
// Direct DB access in server component — no waterfall, no loading states
export default async function Dashboard() {
  const [stats, recentOrders, topUsers] = await Promise.all([
    getStats(), getRecentOrders(), getTopUsers(),
  ]);
  return <DashboardView stats={stats} orders={recentOrders} users={topUsers} />;
}
```

### React Cache (deduplication)
```typescript
import { cache } from 'react';

export const getItem = cache(async (id: string) => {
  const item = await db.select().from(items).where(eq(items.id, id)).limit(1);
  return item[0];
});
```

### Revalidation
```typescript
// Time-based (ISR)
export const revalidate = 3600; // seconds

// On-demand
import { revalidatePath, revalidateTag } from 'next/cache';

export async function updateUser(formData: FormData) {
  'use server';
  await db.update(users).set({ name: formData.get('name') }).where(eq(users.id, id));
  revalidatePath(`/users/${id}`); // Revalidate the page
  revalidateTag('users'); // Revalidate all fetch calls with this tag
}
```

## Route Handlers (APIs)

```typescript
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';

const CreateUserSchema = z.object({
  email: z.string().email(),
});

export async function POST(request: NextRequest) {
  const body = await request.json();
  const parsed = CreateUserSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: parsed.error.flatten() }, { status: 422 });
  }
  const user = await db.insert(users).values(parsed.data).returning();
  return NextResponse.json(user[0], { status: 201 });
}
```

## Server Actions

```typescript
// app/users/actions.ts
'use server';

import { z } from 'zod';
import { db } from '@/db';
import { users } from '@/db/schema';
import { revalidatePath } from 'next/cache';

const CreateUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1),
});

export async function createUser(formData: FormData) {
  const parsed = CreateUserSchema.safeParse(Object.fromEntries(formData));
  if (!parsed.success) return { error: parsed.error.flatten() };

  await db.insert(users).values(parsed.data);
  revalidatePath('/users');
  return { success: true };
}
```

## Middleware

```typescript
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const token = request.cookies.get('session')?.value;
  const { pathname } = request.nextUrl;

  // Protected routes
  if (pathname.startsWith('/dashboard') && !token) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  // Redirect logged-in users away from login
  if (pathname === '/login' && token) {
    return NextResponse.redirect(new URL('/dashboard', request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/dashboard/:path*', '/login'],
};
```

## Performance

- **Server Components** over Client Components whenever possible.
- **Streaming** — use `loading.tsx` and `Suspense` boundaries.
- **Image optimization** — `next/image` with `priority` for above-the-fold.
- **Font optimization** — `next/font` (self-hosted, no layout shift).
- **Bundle analysis** — `@next/bundle-analyzer` for tracking bloat.
- **Link prefetch** — `<Link>` prefetches by default. Disable with `prefetch={false}` for low-priority links.

## Testing

```typescript
// Vitest + Testing Library (not Next.js's built-in jest-config)
import { render, screen } from '@testing-library/react';
import Page from './page';

// Mock server component — render with test data
vi.mock('@/db', () => ({ select: () => ({ from: () => ({ where: () => ({ limit: () => [mockUser] }) }) }) }));

describe('UserPage', () => {
  it('renders user name', async () => {
    const page = await Page({ params: Promise.resolve({ id: '1' }) });
    render(page);
    expect(screen.getByText('Alice')).toBeInTheDocument();
  });
});
```

## Anti-patterns

- ❌ `'use client'` on every component — most components can be server components
- ❌ Data fetching in client components — prefer server components for data
- ❌ `useEffect` for data fetching — use server components or TanStack Query
- ❌ Importing server-only code in client components (DB, tokens, env)
- ❌ Large client bundles — lazy load heavy components with `next/dynamic`
- ❌ Not using `notFound()` — always handle missing data
- ❌ `router.push` for navigation that should use `<Link>` prefetch
