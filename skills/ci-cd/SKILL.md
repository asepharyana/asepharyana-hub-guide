---
name: ci-cd
description: CI/CD best practices — GitHub Actions, pipeline design, Docker build + push, deployment workflows, testing in CI, and environment management. Use when designing CI/CD pipelines, debugging workflow failures. Triggers from project files and configuration, not just keyword matching."
---

# CI/CD Best Practices

## Pipeline Design Principles

1. **Fast feedback** — failing fast is better than failing comprehensively.
2. **Deterministic** — same commit = same result, same artifacts.
3. **Immutable artifacts** — build once, promote through environments.
4. **Idempotent deployments** — deploying the same artifact again produces the same result.
5. **Security gates** — scan dependencies, secrets, and code before production.

## GitHub Actions Structure

```
.github/workflows/
├── lint.yml                     # Quick checks — runs in <2 min
├── docker-build-push.yml        # Build + push images
├── deploy-docker.yml            # Deploy to VPS
├── security.yml                 # CodeQL + dependency scan
├── update-submodule.yml         # Update submodule pointer
└── ...other workflows
```

### Workflow Patterns

**Lint (fast — gates everything else)**
```yaml
name: Lint
on: [push, pull_request]
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: oven-sh/setup-bun@v2
      - run: bun install --frozen-lockfile
      - run: bun run ci     # Biome lint + format
```

**Build + Push (on push to main)**
```yaml
name: Build Docker
on:
  push:
    branches: [main]
    paths: ['apps/**', 'infra/**']
  repository_dispatch:
    types: [build]

jobs:
  build:
    strategy:
      matrix:
        service: [scraper, hub]
    steps:
      - uses: actions/checkout@v4
      - run: |
          docker build \
            -f infra/docker/${{ matrix.service }}.Dockerfile \
            -t ghcr.io/.../${{ matrix.service }}:sha-${{ github.sha }} \
            -t ghcr.io/.../${{ matrix.service }}:latest \
            .
      - run: docker push --all-tags ghcr.io/.../${{ matrix.service }}
```

**Deploy (after build)**
```yaml
name: Deploy
on:
  workflow_run:
    workflows: ['Build Docker']
    types: [completed]
  push:
    branches: [main]
    paths: ['infra/**']

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.VPS_HOST }}
          username: ${{ secrets.VPS_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd ${{ secrets.VPS_TARGET_DIR }}
            docker compose pull <service>
            docker compose up -d <service>
```

## Key Patterns

### Matrix Builds
```yaml
jobs:
  build:
    strategy:
      matrix:
        service: [scraper, hub, api]
      fail-fast: false  # Let others complete even if one fails
```

### Conditional Jobs
```yaml
jobs:
  deploy:
    if: github.event.workflow_run.conclusion == 'success'
```

### Caching
```yaml
- uses: actions/cache@v4
  with:
    path: ~/.bun/install/cache
    key: ${{ runner.os }}-bun-${{ hashFiles('bun.lock') }}
    restore-keys: |
      ${{ runner.os }}-bun-
```

### Secrets
```yaml
# All secrets in GitHub Secrets, never in code
secrets:
  SSH_PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY }}
  VPS_HOST: ${{ secrets.VPS_HOST }}
  ENV_FILE_PRODUCTION: ${{ secrets.ENV_FILE_PRODUCTION }}
```

## Environment Strategy

| Environment | Purpose | Deploy Method |
|-------------|---------|---------------|
| `development` | Local dev | Manual `docker compose up` |
| `staging` | Pre-production | Auto-deploy from PR branches |
| `production` | Live | Auto-deploy from main |

## Quality Gates (run order)

1. **Lint** (<1 min) — Biome/Ruff/clippy + format check
2. **Type check** (<2 min) — tsc/pyright/cargo check
3. **Unit tests** (<3 min) — fast, no external deps
4. **Build** (<5 min) — compile/transpile, build Docker images
5. **Integration tests** (<10 min) — with DB, external services
6. **Security scan** (<5 min) — CodeQL, dependency audit, secret scan
7. **Deploy** (<2 min) — SSH, pull, restart

## Deployment (this repo's pattern)

1. SSH to VPS (`orangevps`)
2. Pull latest images from GHCR
3. Restart specific container (not all)
4. Health check after restart
5. Rollback if health check fails

## Anti-patterns

- ❌ **Large CI configs** — extract repeated blocks into actions. Use YAML anchors.
- ❌ **Building in deployment** — build once in CI, deploy artifact. Avoid `docker compose build` on production.
- ❌ **Hardcoded values** — use env vars, secrets, and GitHub variables.
- ❌ **Skipping lint** — lint should run first and gate everything.
- ❌ **No caching** — each run fetches deps fresh = 2x+ slower.
- ❌ **Manual deployment steps** — automate everything. If it's manual, it will be wrong.
- ❌ **Deploying untested artifacts** — run tests before build, not after.
