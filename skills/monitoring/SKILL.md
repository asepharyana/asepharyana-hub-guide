---
name: monitoring
description: Monitoring and observability best practices — Prometheus, Grafana, alerts, dashboards, uptime monitoring, and incident response. Use when setting up monitoring infrastructure, designing dashboards, defining alerts, or whenever the user mentions "monitoring," "Prometheus," "Grafana," "alert," "dashboard," "uptime," "incident," "runbook," "SLA," "SLO," "SLI," or "on-call."
---

# Monitoring Best Practices

## Core Concepts

- **SLI** (Service Level Indicator) — what you measure (latency, error rate, uptime).
- **SLO** (Service Level Objective) — target value (p99 < 500ms, error rate < 0.1%).
- **SLA** (Service Level Agreement) — contractual commitment. Usually looser than SLO.

**Rule:** Set SLOs tighter than SLAs so you detect problems before customers do.

## Prometheus Setup (this repo)

```yaml
# Prometheus auto-discovers containers with this label
docker service create \
  --label prometheus.io/scrape=true \
  --label prometheus.io/path=/metrics \
  --label prometheus.io/port=8080 \
  ...
```

### Key Metrics to Export

Every service should expose a `/metrics` endpoint:

```prometheus
# Service metrics
http_requests_total{method="GET", path="/users", status="200"}
http_request_duration_seconds{quantile="0.5", quantile="0.9", quantile="0.99"}
http_requests_in_flight
errors_total{type="validation", type="database", type="auth"}

# Traefik metrics (auto-exposed via `--metrics.prometheus=true`)
traefik_service_request_duration_seconds{service="...", quantile="..."}
traefik_service_requests_total{service="...", code="..."}

# System
process_cpu_seconds_total
process_resident_memory_bytes
process_open_fds
```

### Recording Rules
```yaml
groups:
  - name: service
    rules:
      - record: service:error_rate_5m
        expr: rate(errors_total[5m]) / rate(http_requests_total[5m])
      - record: service:latency_p99_5m
        expr: histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))
```

## Grafana Dashboards

### Dashboard Components

| Panel | Metric | Good |
|-------|--------|------|
| **RPS** | `rate(http_requests_total[5m])` | Matches traffic patterns |
| **Error rate** | `service:error_rate_5m` | < 1% |
| **Latency** | `service:latency_p99_5m` | < 500ms |
| **CPU** | `process_cpu_seconds_total` | < 80% sustained |
| **Memory** | `process_resident_memory_bytes` | Steady, no leaks |
| **Active connections** | `http_requests_in_flight` | < configured max |
| **Open file descriptors** | `process_open_fds` | < 50% of limit |

### Dashboard Design Rules
- **Single pane of glass** — most important metrics visible without scrolling.
- **Red/yellow/green thresholds** — at a glance status.
- **Time range controls** — last 15m, 1h, 6h, 1d, 7d.
- **Template variables** — select by service, host, environment.
- **Annotations** — mark deployments, config changes on timeline.

## Alerting Rules

```yaml
groups:
  - name: alerts
    rules:
      - alert: HighErrorRate
        expr: service:error_rate_5m > 0.01
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "{{ $labels.service }} error rate is {{ $value | humanizePercentage }}"

      - alert: HighLatency
        expr: service:latency_p99_5m > 1.0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "{{ $labels.service }} p99 latency is {{ $value }}s"

      - alert: ServiceDown
        expr: up{job="~.*"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "{{ $labels.job }} has been down for >1 minute"
```

### Severity Levels

| Level | Response | Time to Acknowledge |
|-------|----------|---------------------|
| **P1 (Critical)** | Pages on-call | 5 min |
| **P2 (High)** | Alerts team during business hours | 30 min |
| **P3 (Medium)** | Ticket, next business day | 8 hours |
| **P4 (Low)** | Backlog, no deadline | N/A |

## Uptime Monitoring

- **Synthetic checks** — test critical user journeys every minute.
- **SSL certificate expiry** — alert when <30 days remaining.
- **Blackbox monitoring** — external service checking your endpoints.
- **Heartbeat** — cron job pings a Dead Man's Switch — if it stops, on-call is paged.

## Incident Response

### Runbook Template
```markdown
# Runbook: High Error Rate

## Symptoms
- >1% HTTP 5xx errors over 5 minutes
- Slack alert in #monitoring

## 1. Check Traefik logs
`docker logs traefik --tail 100 | grep "5[0-9][0-9]"`

## 2. Check service logs
`docker logs <service> --tail 200`

## 3. Check database
- Connection pool (Redis: `INFO clients`)
- Query performance (`EXPLAIN ANALYZE` on slow queries)

## 4. Rollback if needed
- Revert to previous stable image: `docker compose up -d <service>@sha256:<prev>`
```

### IR Checklist
1. **Acknowledge** — confirm you're investigating.
2. **Mitigate** — stop the bleeding (rollback, disable feature flag, scale up).
3. **Resolve** — apply the fix, verify metrics return to baseline.
4. **Review** — postmortem (blameless). What happened? Why? How to prevent?

## Logging Integration

- **Structured logs** (JSON) indexed by Loki or ELK.
- **Correlate logs with metrics** — trace_id in both.
- **Error sampling** — capture 100% of errors, 1-10% of successful requests.

## This Repo's Monitoring Stack

| Component | Role |
|-----------|------|
| **Prometheus** | Metrics + alerting (Docker SD auto-discovery) |
| **Jaeger** | Tracing (OTLP receiver, all-in-one) |
| **Traefik** | Exposes metrics (--metrics.prometheus=true) |
| **Docker labels** | `prometheus.io/scrape=true` for auto-discovery |
| **Dashboard** | `/dashboard` (auto-refresh 15s) |
| **Dashboard API** | `/api/dashboard` — JSON with containers, traces, metrics |

## Anti-patterns

- ❌ No SLOs — "everything should be fast" is not a target
- ❌ Dashboard overload — metrics vomit with no narrative
- ❌ Alert fatigue — 100 alerts per day means none are actionable
- ❌ No runbooks — "what do I do when this alert fires?"
- ❌ Only monitoring infrastructure — no business metrics (orders/min, signups)
- ❌ Not monitoring after hours — 24/7 service needs 24/7 monitoring
- ❌ No log retention policy — infinite logs = infinite cost
