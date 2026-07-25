---
name: logging-observability
description: Best practices for logging, metrics, tracing, alerting, and observability — structured logging, correlation IDs, Prometheus metrics, distributed tracing, and dashboard design. Use when adding logging, designing monitoring, setting up dashboards, debugging production issues. Detects from code context and project files — not dependent on specific language keywords."
---

# Logging & Observability

## The Three Pillars

```
Logs — discrete events: "user logged in at 10:32:14"
Metrics — aggregatable numbers: 50 req/s, 200ms p99 latency
Traces — request lifecycle across services: "order #123 took 400ms total"
```

All three are needed. None replaces the others.

## Structured Logging

**Log in JSON format** — machine-readable, parsable, searchable.

```json
// ❌ Unstructured (text search grey area)
"User 123 created order 456 for $50.99"

// ✅ Structured (parseable, filterable)
{
  "level": "info",
  "time": "2025-07-25T10:32:14Z",
  "message": "order created",
  "service": "order-service",
  "trace_id": "abc123def456",
  "user_id": "123",
  "order_id": "456",
  "amount": 50.99,
  "currency": "USD",
  "duration_ms": 45
}
```

### Log Levels — Use Consistently

| Level | When | Example |
|-------|------|---------|
| **ERROR** | Something is broken. Needs human attention. | DB connection failed, payment declined |
| **WARN** | Something unexpected but recoverable. | Retry succeeded, rate limit approaching |
| **INFO** | Notable lifecycle events. User-triggered actions. | Order created, user signed up, scheduled job ran |
| **DEBUG** | Detailed context for debugging. Off in prod. | SQL query, request body, iteration details |
| **TRACE** | Very fine-grained. For deep debugging only. | Function entry/exit, loop iterations |

### What to Log

- **Every error** with stack trace, context, and correlation ID.
- **Every request** at INFO — method, path, status, duration.
- **Business events** — state transitions (order created → paid → shipped).
- **Auth events** — login success/failure, token refresh, privilege change.
- **Third-party calls** — external API call duration, status.

### What NOT to Log (Security)

- ❌ Passwords, tokens, secrets, API keys
- ❌ PII beyond necessity (email, phone, SSN, address)
- ❌ Full request/response bodies (except DEBUG, and even then — sanitize)
- ❌ Database connection strings
- ❌ Internal IPs in public-facing systems

## Metrics (Prometheus)

### RED Method (for services)

| Metric | What | Good |
|--------|------|------|
| **Rate** | Requests per second | Flat line — load |
| **Errors** | Failed requests / total | <1% (target), <0.1% (excellent) |
| **Duration** | Latency distribution | p50 < 100ms, p99 < 500ms |

### USE Method (for infrastructure)

| Metric | What |
|--------|------|
| **Utilization** | CPU, RAM, disk, network bandwidth |
| **Saturation** | Queue depth, swap usage, load average |
| **Errors** | Disk IO errors, packet drops, OOM kills |

### Four Golden Signals (Google SRE)

1. **Latency** — time to serve a request
2. **Traffic** — demand on the system (RPS, active users)
3. **Errors** — explicit failures + implicit (200 with wrong data)
4. **Saturation** — how "full" the system is

### Key Metrics to Expose

```prometheus
# Service
http_requests_total{method, path, status}
http_request_duration_seconds{quantile="0.99"}
errors_total{type}
active_users

# Business
orders_created_total{currency}
revenue_total
jobs_failed_total

# System
process_cpu_seconds_total
process_resident_memory_bytes
process_open_fds
```

## Distributed Tracing (Jaeger / OpenTelemetry)

- **Every request gets a `trace_id`** — propagate through headers (`x-trace-id`, `traceparent`).
- **Span per operation** — HTTP handler, DB query, external API call.
- **Annotate spans** — with relevant metadata (user ID, order ID, error details).
- **Sampling:** sample 100% of errors, 1-10% of successful requests.
- **Dapr/Jaeger:** auto-injects trace headers across sidecars.

```typescript
// OpenTelemetry example
const tracer = opentelemetry.trace.getTracer('order-service');
const span = tracer.startSpan('createOrder', { attributes: { orderId } });
try {
  const result = await createOrder(input);
  span.setStatus({ code: SpanStatusCode.OK });
  return result;
} catch (e) {
  span.recordException(e);
  span.setStatus({ code: SpanStatusCode.ERROR });
  throw e;
} finally {
  span.end();
}
```

## Alerting

### Alert Design

- **Alert on symptoms, not causes** — "API error rate >1%" not "server CPU >90%"
- **Alert fatigue kills alerts** — every alert should need human action. If nobody acts, delete it.
- **Define SLOs** — 99.9% uptime, 95% requests <500ms. Alert when approaching breach.
- **Alert structure:**
  ```
  Title: [P1] High error rate on order-service
  Summary: Error rate = 5.2% (threshold: 1%) over last 5 minutes
  Runbook: /runbooks/high-error-rate.md
  Severity: P1 (critical, paging) / P2 (urgent, business hours) / P3 (warning, ticket)
  ```

### Common Alert Rules

| Rule | Severity | Threshold |
|------|----------|-----------|
| High error rate | P1 | >1% over 5min |
| High latency | P2 | p99 >1s over 5min |
| Service down | P1 | No metrics for 5min |
| Disk space | P2 | <10% free |
| Certificate expiring | P2 | <30 days |
| Rate limit hit rate | P3 | >10% of requests rate-limited |

## Observability Stack (for this repo)

| Component | Role |
|-----------|------|
| **Prometheus** | Metrics collection + alerting |
| **Jaeger** | Distributed tracing (all-in-one, OTLP receiver) |
| **Traefik** | Metrics endpoint (`--metrics.prometheus=true`) |
| **Docker labels** | Auto-discovery: `prometheus.io/scrape=true` |
| **Dashboard** | `/dashboard` — auto-refresh 15s, shows containers + traces + metrics |

## Anti-patterns

- ❌ **String interpolation in logs** — `log.info("User " + id + " logged in")` instead of structured fields
- ❌ **Logging in every function** — no, log at service boundaries and business events
- ❌ **No correlation IDs** — cannot trace request across services
- ❌ **Silent catch** — `catch (e) {}` swallows errors with no log
- ❌ **Alert fatigue** — 50 alerts daily means none are actionable
- ❌ **Dashboards without action** — beautiful dashboard but nobody knows what to do when a metric goes red
