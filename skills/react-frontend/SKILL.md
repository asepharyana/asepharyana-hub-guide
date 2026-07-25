---
name: react-frontend
description: React and frontend best practices — component patterns, hooks, state management, TanStack Query, React Router, performance, and testing. Use when building React components, designing state management, or whenever the user mentions "React," "hooks," "state management," "component," "JSX," "TanStack Query," "React Router," "Zustand," "Vite," "Next.js," or "Frontend."
---

# React Frontend Best Practices

## Component Patterns

### Composition over Inheritance
```typescript
// ✅ Prefer composition
function Layout({ sidebar, children }: { sidebar: ReactNode; children: ReactNode }) {
  return <div className="layout">{sidebar}<main>{children}</main></div>;
}

// ❌ Avoid inheritance patterns in React
```

### Container/Presentational Separation
```typescript
// Container: manages state, data fetching, business logic
function UserProfileContainer() {
  const { data: user } = useUserQuery(userId);
  const { mutate: update } = useUpdateUserMutation();
  return <UserProfile user={user!} onUpdate={update} />;
}

// Presentational: pure rendering, props-only
function UserProfile({ user, onUpdate }: UserProfileProps) {
  return <div>{user.name} <button onClick={onUpdate}>Edit</button></div>;
}
```

### Custom Hooks for Logic Extraction
```typescript
// Extract reusable logic into custom hooks
function useUserPermissions(userId: string) {
  const { data: user } = useUserQuery(userId);
  return useMemo(() => ({
    isAdmin: user?.role === 'admin',
    canEdit: user?.role === 'admin' || user?.role === 'editor',
    canDelete: user?.role === 'admin',
  }), [user]);
}
```

## Hooks Rules

- **Only call hooks at the top level** — not in conditions, loops, or callbacks.
- **Only call hooks from React functions** — component or custom hook.
- **Deps array matches reality** — include all values used inside.
- **`useMemo`** for expensive computations. **`useCallback`** for stable references.
- **`useEffect`** is for synchronization, not lifecycle. If you can compute from state, do it.

```typescript
// ❌ Unnecessary effect
const [fullName, setFullName] = useState('');
useEffect(() => { setFullName(`${first} ${last}`); }, [first, last]);

// ✅ Derived state
const fullName = `${first} ${last}`;
```

## Data Fetching (TanStack Query)

```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

// Query
function useUserQuery(id: string) {
  return useQuery({
    queryKey: ['users', id],
    queryFn: () => api.users.get({ params: { id } }),
    staleTime: 30_000,  // 30s before refetch
    gcTime: 5 * 60_000, // 5min cache
  });
}

// Mutation with optimistic update
function useUpdateUserMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: UpdateUserInput) => api.users.update({ body: data }),
    onMutate: async (newUser) => {
      await queryClient.cancelQueries({ queryKey: ['users', newUser.id] });
      const previous = queryClient.getQueryData(['users', newUser.id]);
      queryClient.setQueryData(['users', newUser.id], newUser);
      return { previous };
    },
    onError: (_, __, context) => {
      queryClient.setQueryData(['users', context.previous.id], context.previous);
    },
    onSettled: () => queryClient.invalidateQueries({ queryKey: ['users'] }),
  });
}
```

**Rules:**
- `staleTime` for read-through caching. Default 0 = refetch on mount.
- `gcTime` for garbage collection of unused data.
- `onMutate`/`onError`/`onSettled` for optimistic updates.
- Queries over custom fetch + useEffect in all cases.

## State Management Selection

| Need | Solution |
|------|----------|
| Server state | TanStack Query |
| URL state | React Router / TanStack Router |
| Form state | React Hook Form + Zod |
| Client state (global) | Zustand or Context |
| Client state (local) | `useState` / `useReducer` |
| Component communication | Props / lifting state up |

```typescript
// Zustand — lightweight, no boilerplate
import { create } from 'zustand';

interface UIStore {
  sidebarOpen: boolean;
  toggleSidebar: () => void;
}
const useUIStore = create<UIStore>((set) => ({
  sidebarOpen: true,
  toggleSidebar: () => set((s) => ({ sidebarOpen: !s.sidebarOpen })),
}));
```

## Routing (TanStack Router / React Router)

```typescript
// TanStack Router — type-safe, modern
const router = createRouter({
  routeTree: rootRoute.addChildren([
    indexRoute,
    usersRoute.addChildren([userRoute, userProfileRoute]),
  ]),
});
```

- **File-based routing** (Next.js App Router, Vite/Router) for simpler projects.
- **Type-safe routers** (TanStack Router) for larger apps.
- **Lazy load** route components — `React.lazy(() => import('./routes/Dashboard'))`.

## Performance

- **Virtual lists** — `@tanstack/react-virtual` for 100+ items.
- **React.memo** sparingly — only for components that re-render often with same props.
- **`useMemo` for expensive calculations** — not for every value.
- **Code splitting** — per route, per heavy component.
- **Bundle analysis** — `vite-bundle-visualizer` to find bloat.

## Testing (Vitest + Testing Library)

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { UserProfile } from './UserProfile';

describe('UserProfile', () => {
  it('renders user name', () => {
    render(<UserProfile user={{ name: 'Alice' }} />);
    expect(screen.getByText('Alice')).toBeInTheDocument();
  });

  it('calls onUpdate when edit clicked', async () => {
    const onUpdate = vi.fn();
    render(<UserProfile user={{ name: 'Alice' }} onUpdate={onUpdate} />);
    await userEvent.click(screen.getByRole('button', { name: /edit/i }));
    expect(onUpdate).toHaveBeenCalledTimes(1);
  });
});
```

- **Testing Library** for user-centric tests. Never test implementation details.
- **userEvent** over `fireEvent` — simulates real user interactions.
- **Component-level** tests for behavior, not storybook-style visual tests here.

## CSS / Styling

- **Tailwind CSS** for utility-first styling. Consistent, fast, small.
- **CSS Modules** when you need scoped component styles.
- **CSS-in-JS** (styled-components, emotion) — only for dynamic theming. Prefer Tailwind.

## Anti-patterns

- ❌ `useEffect` for data fetching — use TanStack Query
- ❌ Prop drilling beyond 3 levels — compose or context
- ❌ `useState` for derived data — compute from existing state
- ❌ Direct DOM manipulation — use React refs
- ❌ `any` in component props — always type props
- ❌ Large component files — split by responsibility
- ❌ `index` as key — breaks reconciliation on reorder
- ❌ `useEffect` without deps — runs every render
