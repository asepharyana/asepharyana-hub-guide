---
name: hub-guide
description: Guide for the Asepharyana Hub monorepo — submodule workflow, infrastructure stack (Traefik, Dapr, NATS, Redis), CI/CD pipelines, adding new services, and debugging tips. Use when working in the asepharyana-hub monorepo, managing submodules, dealing with Docker/infra setup, or whenever the user asks about "hub monorepo," "submodules," "Traefik," "Dapr," "NATS," "infrastructure," or "adding a new service."
---

# Hub Guide — Asepharyana Hub Monorepo

## Submodule Workflow

- Code changes go in the submodule repo, not here. The hub monorepo only tracks submodule pointers.
- After pushing changes to a submodule repo, update the pointer here:
  ```bash
  cd apps/<name> && git checkout main && git pull
  cd ../.. && git add apps/<name> && git commit -m "chore(deps): update <name> submodule"
  ```
- CI/CD auto-updates submodule pointers via `repository_dispatch`. Manual updates are fine for dev.

### Typical Submodule State

| State | Meaning |
|-------|---------|
| `(HEAD)` | Detached HEAD — submodule is at the committed pointer |
| `(main)` | On the default branch — you've done `cd apps/name && git checkout main` |
| Dirty | Uncommitted changes inside submodule |

To reset a submodule to its committed pointer:
```bash
git submodule update --init --recursive apps/<name>
```

## Development Quickstart

```bash
make init-submodules     # After fresh clone — fetches all submodules
make dev                 # Start Redis for local dev
docker compose -f infra/compose/shared.yml up -d   # Full infra stack
```

## Local vs Production

| Aspect | Local | Production (VPS) |
|--------|-------|------------------|
| DB | None (or local) | PostgreSQL on `imrnes` via Tailscale |
| Redis | `make dev` | Container on `orangevps` |
| Traefik | Not running | TLS-terminated on `orangevps` |
| DNS | `localhost` | `*.asepharyana.my.id`, `*.asepharya.web.id` |

## Debugging Tips

### Docker compose validation
```bash
for f in infra/compose/*.yml; do docker compose -f "$f" config >/dev/null && echo "OK $f"; done
```

### YAML syntax check
```bash
python -c "import pathlib, yaml; [yaml.safe_load(open(p)) for p in pathlib.Path('infra').rglob('*.yml')]"
```

### Check submodule pointers
```bash
git submodule status
  # Leading `-` = not initialized, `+` = different from committed hash, ` ` = matches
```

### Traefik route not working?
1. Check `infra/traefik/dynamic/apps.yaml` — router rule + service definition present?
2. Container labels in compose file include Traefik config?
3. Container on `app-shared-net`?

## Adding a New Service — Checklist

1. [ ] Create separate repo for app code
2. [ ] `git submodule add <url> apps/<name>`
3. [ ] Create Dockerfile in `infra/docker/`
4. [ ] Create compose file in `infra/compose/` (app + Dapr sidecar)
5. [ ] Add Traefik router in `infra/traefik/dynamic/apps.yaml`
6. [ ] Add build job in `.github/workflows/docker-build-push.yml`
7. [ ] Verify: `docker compose -f infra/compose/<name>.yml config`

See `docs/add-new-app.md` for full guide.

## Monitoring

- **Dashboard**: `/dashboard` on the hub site (auto-refresh 15s)
- **Dashboard API**: `/api/dashboard` — JSON with containers, traces, metrics
- **Prometheus**: Auto-discovers containers with `prometheus.io/scrape=true` label via Docker SD
- **Jaeger**: Traces via OTLP — check for cross-service latency

## Infrastructure Files Map

| Path | Purpose |
|------|---------|
| `infra/compose/*.yml` | One Docker Compose file per service |
| `infra/dapr/components/` | Dapr pub/sub, state store component configs |
| `infra/docker/*.Dockerfile` | Build files per service |
| `infra/traefik/dynamic/apps.yaml` | Traefik route definitions |
| `infra/traefik/traefik.yml` | Traefik static config (entrypoints, providers) |
| `.github/workflows/` | CI/CD pipelines |
| `docs/` | ADRs, deployment guide, new-app guide |

## Git Hook Scripts

Located in `scripts/`:
- `scripts/cleanup.sh` — prune old Docker images, clean temp files
- `scripts/update-deps.sh` — bump dependencies across submodules
- `scripts/setup-hooks.sh` — install local git hooks
