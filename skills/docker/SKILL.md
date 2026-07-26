---
name: docker
description: Docker best practices — Dockerfile optimization, multi-stage builds, Docker Compose, networking, security, and image management. Use when writing Dockerfiles, designing container infrastructure, debugging docker issues. Triggers from project files and configuration, not just keyword matching."
---

# Docker Best Practices

## Dockerfile Best Practices

### Multi-Stage Builds

```dockerfile
# Stage 1: Build
FROM node:22-alpine AS builder
WORKDIR /app
COPY package.json bun.lock ./
RUN bun install --frozen-lockfile
COPY . .
RUN bun run build

# Stage 2: Production
FROM node:22-alpine AS runner
WORKDIR /app
RUN addgroup --system app && adduser --system app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
USER app
EXPOSE 3000
CMD ["node", "dist/index.js"]
```

**Rules:**
- **Minimal base image** — Alpine or `scratch` for binaries, `distroless` for runtimes.
- **Combine RUN commands** — each `RUN` creates a layer. Chain with `&&`.
- **Use `.dockerignore`** — exclude `node_modules`, `.git`, `*.md`, CI files.
- **Don't run as root** — `USER app` (not `root`).
- **Prefer COPY over ADD** — ADD has magic behavior (tar extraction, URL fetch).
- **Leverage build cache** — order `COPY` from least to most frequently changed.

### Optimize Layer Caching
```dockerfile
# 1. Install deps first (changes rarely)
COPY package.json bun.lock ./
RUN bun install --frozen-lockfile

# 2. Copy source (changes often — last)
COPY . .
RUN bun run build
```

## Docker Compose

```yaml
# Always join shared network
services:
  app:
    container_name: my-service
    build:
      context: .
      dockerfile: Dockerfile
    networks:
      - app-shared-net
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 5s
      retries: 3

networks:
  app-shared-net:
    external: true
```

### Typical Docker Compose Order
- **Data layer:** `db.yml`, `redis.yml` — stateful services first
- **Messaging:** `nats.yml`, `rabbitmq.yml` — message brokers
- **Infrastructure:** `traefik.yml`, `nginx.yml` — reverse proxy
- **Application:** `app.yml` — service containers

## Security

- **Don't run as root** — always `USER app` with least privileges.
- **Read-only root** — `--read-only` flag. Mount tmpfs for writable dirs.
- **No secrets in images** — use build args only for non-sensitive values. Secrets via env.
- **Image scanning** — `docker scout` or Trivy for CVE scanning.
- **Drop capabilities** — `--cap-drop=ALL --cap-add=NET_BIND_SERVICE` in compose.
- **Healthchecks** — prevent routing to dead containers.

## Image Tagging

```
# Pattern
sha-<short-sha>   # Immutable — for deterministic rollbacks
latest            # Mutable — convenience

# Example
ghcr.io/myorg/myproject/<service>:sha-a1b2c3d
ghcr.io/myorg/myproject/<service>:latest
```

## Networking

- **All containers** join the same Docker network (external bridge).
- **DNS resolution** via Docker DNS (container name = hostname).
- **Expose only needed ports** — reverse proxy handles external traffic on port 443.

## Debugging

```bash
# Inspect layers
docker history <image>

# Check image size
docker images <image>

# Check running container
docker inspect <container>

# Shell into container
docker exec -it <container> sh

# Check container logs
docker logs <container>

# Analyze build cache
docker build --no-cache-filter=production .
```

## Anti-patterns

- ❌ Running as root — security risk
- ❌ `latest` tag in production — use immutable SHA tags
- ❌ Large images — Alpine/multi-stage keeps them small
- ❌ Multiple services per container — one process per container
- ❌ Installing build tools in production image — use multi-stage
- ❌ Hardcoded secrets in Dockerfile — use env vars or secrets mount
- ❌ No `.dockerignore` — sends entire project context to daemon
