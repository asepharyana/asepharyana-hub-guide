---
name: monorepo
description: Monorepo best practices — tooling, workspace configuration, shared dependencies, CI/CD, and dependency management. Use when working in monorepos (pnpm workspaces, moon, turborepo, Nx), managing shared packages, or whenever the user mentions "monorepo," "workspace," "pnpm workspace," "moon," "turborepo," "nx," "shared package," "dependency management," or "submodule."
---

# Monorepo Best Practices

## Tool Selection

| Tool | Best For | Why |
|------|----------|-----|
| **pnpm workspaces** | Package management | Strict, fast, disk-efficient |
| **moon** | Monorepo orchestration | Task orchestration + caching |
| **turborepo** | Task orchestration | Simple caching, good for JS/TS |
| **Nx** | Full monorepo framework | Generators, dependency graph, affected commands |
| **Git submodules** | Multi-repo coordination | Separate repos imported together (this repo's pattern) |

## Workspace Structure (pnpm + moon)

```
├── apps/
│   ├── hub/            # Next.js app (submodule)
│   └── scraper/        # Rust API (submodule)
├── packages/           # Shared libraries (when not submodules)
├── infra/              # Shared infra config
├── pnpm-workspace.yaml
├── moon.yml
└── package.json
```

### pnpm-workspace.yaml
```yaml
packages:
  - 'apps/*'
  - 'packages/*'
```

### moon.yml (root)
```yaml
$schema: 'https://moonrepo.dev/schemas/project.json'
language: 'typescript'
type: 'application'
```

## Shared Dependencies

```bash
# Install a shared dependency
pnpm add -w typescript

# Install in a specific package
pnpm add --filter @scope/package zod

# Run in all packages
pnpm -r run build
```

**Rules:**
- **One version of a dependency across the monorepo** — use `pnpm overrides` or `resolution`.
- **Root `devDependencies`** for shared tooling (TypeScript, Biome, ESLint).
- **Explicit `dependencies`** — never rely on hoisting.
- **Lock file** (`pnpm-lock.yaml`) committed — immutable installs.

## Git Submodules (this repo's pattern)

```
asepharyana-hub/
├── apps/
│   ├── hub/          → asepharyana/asepharyana-hub-hub
│   └── scraper/      → asepharyana/asepharyana-hub-scraper
```

### Submodule Workflow
```bash
# Init after clone
git submodule update --init --recursive

# Update all submodules to latest
git submodule foreach git pull origin main

# Update one submodule
cd apps/hub && git checkout main && git pull
cd ../.. && git add apps/hub && git commit -m "chore(deps): update hub submodule"
git push
```

**State indicators:**
- `(HEAD)` — detached at committed pointer (normal state).
- `(main)` — on a branch (you've done `cd apps/name && git checkout main`).
- Dirty — uncommitted changes inside submodule.

### When to Use Submodules vs Workspaces

| Need | Use |
|------|-----|
| Independent repos, separate deploy | Submodules |
| Shared code within one repo | Workspaces |
| Tightly coupled, always deploy together | Workspaces |
| Loosely coupled, different teams | Submodules |

## CI/CD for Monorepos

### Selective Builds
```yaml
# Only run relevant workflows based on changed paths
on:
  push:
    branches: [main]
    paths:
      - 'apps/hub/**'
      - 'infra/docker/hub.Dockerfile'
```

### Affected Commands (Nx/Turborepo/Moon)
```bash
moon ci               # Runs affected tasks based on changes
npx nx affected:test   # Nx style
turbo run build        # Turborepo — leverages cache
```

### Caching
- **moon/turborepo** cache task outputs by file hash + env.
- **pnpm** caches node_modules.
- **Docker layer caching** — Registry-based caching for Docker builds.

## Shared Configuration

### TypeScript
```jsonc
// tsconfig.base.json at root — extended by all packages
{
  "compilerOptions": {
    "strict": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "moduleResolution": "bundler"
  }
}
```

### ESLint / Biome
```jsonc
// biome.json at root — shared config for all packages
{
  "formatter": { "indentStyle": "tab", "lineWidth": 120 },
  "linter": { "rules": { "recommended": true } }
}
```

## Dependency Management

- **Dependabot / Renovate** — automate dependency updates.
- **`pnpm dedupe`** — deduplicate after updates.
- **Check for duplicates** — `pnpm ls -r` or `pnpm why <package>`.
- **When to upgrade:**
  - Patch: auto-merge.
  - Minor: update weekly.
  - Major: scheduled migration, document breaking changes.

## Anti-patterns

- ❌ Different dependency versions across packages — inconsistent builds
- ❌ Hoisting assumptions — code works in dev but not in CI because of missing deps
- ❌ Monolithic `package.json` — each package declares its own dependencies
- ❌ No `.npmrc` with `shamefully-hoist=true` — defeats pnpm's strictness
- ❌ Circular dependencies between packages — extract shared code
- ❌ Every change rebuilds everything — use affected commands and caching
- ❌ Submodule pointer drift — always commit after updating submodules
