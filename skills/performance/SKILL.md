---
name: performance
description: Best practices for software performance — caching, query optimization, lazy loading, profiling, CDN, database indexing, and memory management. Use when optimizing slow endpoints, reducing load times, designing caching strategies, or whenever the user mentions "performance," "optimization," "slow," "cache," "lazy loading," "profiling," "bottleneck," "N+1," "latency," "throughput," or "scalability."
---

# Performance Best Practices

## Core Principle

**Measure before optimizing.** A guess is wrong more than half the time. Profile first, then fix the real bottleneck.

## Frontend Performance

### Loading
- **Lazy load** — images, components, routes, heavy modules. Only what's needed now.
- **Code splitting** — split by route (dynamic imports), not by random chunks.
- **Preload critical assets** — `<link rel="preload">` for fonts, hero images, critical CSS.
- **Prefetch likely navigations** — `<link rel="prefetch">` for pages user is likely to visit.

### Rendering
- **Virtual lists** — for 100+ items. windowing (react-window, tanstack-virtual).
- **Debounce/throttle** — search inputs (300ms debounce), scroll handlers (throttle 100ms).
- **Avoid layout thrashing** — batch DOM reads/writes. Use `requestAnimationFrame`.
- **CSS containment** — `contain: contents` isolates sub-trees from layout recalc.

### Assets
- **Images** — next-gen formats (WebP, AVIF), responsive (`srcset`), lazy loading (`loading="lazy"`).
- **Fonts** — `font-display: swap`, subset fonts, preload critical ones.
- **Bundles** — tree-shaking enabled, minification, compression (brotli > gzip).

## Backend Performance

### Database

| Issue | Fix |
|-------|-----|
| **N+1 queries** | Eager loading (`.with()`, `.include()`, `JOIN`) |
| **Missing index** | `EXPLAIN ANALYZE` to find sequential scans. Add indexes on `WHERE`/`JOIN`/`ORDER BY` columns |
| **Too many rows** | Pagination, cursor-based, limit queries |
| **Expensive joins** | Denormalize, materialized view, or caching layer |
| **Large JSON fields** | Only select columns needed, not `SELECT *` |

```sql
-- ❌ N+1
for each order: SELECT * FROM items WHERE order_id = ?
-- ✅ Eager load
SELECT * FROM items WHERE order_id IN (?, ?, ?, ...)
```

### Caching Strategy

```
Request → CDN (static assets) → API Gateway → App Cache → DB
```

| Layer | Cache | TTL | Invalidates |
|-------|-------|-----|-------------|
| **CDN** | Static assets, API responses | Long (1yr for assets) | Version hash |
| **HTTP** | `Cache-Control`, ETag | Varies | `If-None-Match` |
| **App** | Redis, in-memory | Seconds-minutes | Write-through / TTL |
| **DB** | Query cache, connection pool | Intrinsic | Row changes |

**Cache patterns:**
```typescript
// Cache-aside (most common)
async function getUser(id: string): Promise<User> {
  const cached = await cache.get(`user:${id}`);
  if (cached) return JSON.parse(cached);
  const user = await db.select().from(users).where(eq(users.id, id));
  await cache.set(`user:${id}`, JSON.stringify(user), 'EX', 300); // 5 min TTL
  return user;
}
```

### Connection Pooling
- **Database:** pool of 10-50 connections (not 1, not unlimited).
- **HTTP:** keep-alive, connection reuse. H2 multiplexing.
- **Redis:** single connection reused, not new connection per request.

## Network Performance

- **Compression** — brotli for static, gzip as fallback. Enable in Traefik (`compress` middleware).
- **HTTP/2** — multiplexing, header compression, server push. Enabled by default in Traefik.
- **CDN** — CloudFlare, Fastly, CloudFront for static assets and API edge caching.
- **Keep-alive** — reuse TCP connections. Default Timeout 60s.
- **Latency budget** — 200ms total is good for most apps. Track per service.

## Profiling

### When you think something is slow:
1. **Define the measurement** — what's slow? p50? p99? cold start?
2. **Profile** — flame graphs (pyroscope, pprof), APM (Jaeger spans).
3. **Find the bottleneck** — is it CPU? IO? Network? Database? Memory?
4. **Fix one thing** — measure again. If no improvement, revert and try next.

### Tools by Language

| Language | Profiling | Flame Graphs |
|----------|-----------|--------------|
| TypeScript | Chrome DevTools, Node `--prof` | `0x` tool |
| Rust | `perf`, `flamegraph`, `pprof-rs` | `cargo flamegraph` |
| Go | `pprof` (runtime built-in) | `go tool pprof -http` |
| Python | `cProfile`, `py-spy` | `flameprof` |

## Performance Budgets

Set measurable limits and enforce them:
- **Lighthouse** — 90+ Performance score
- **Bundle size** — <200KB JS (compressed), <50KB CSS
- **LCP** (Largest Contentful Paint) — <2.5s
- **FID** (First Input Delay) — <100ms
- **CLS** (Cumulative Layout Shift) — <0.1
- **API p99** — <500ms
- **First byte** — <200ms

## Anti-patterns

- ❌ **Premature optimization** — optimizing before measuring. "Make it work, make it right, make it fast."
- ❌ **Caching everything** — cache invalidation is hard. Cache what's expensive and stable.
- ❌ **Over-indexing** — too many indexes slow writes. Index what's queried, not every column.
- ❌ **SELECT *** — fetches columns you don't need. Increases memory and network.
- ❌ **Sync over async** — blocking calls in async context (Node event loop blocking).
- ❌ **Fat dependencies** — importing a 50KB library for one function. Prefer tree-shakeable modules.
