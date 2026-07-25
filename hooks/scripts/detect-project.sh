#!/bin/bash
# hub-guide: detect project type and suggest relevant skills
# Runs at SessionStart to prime best-practice skills

PROJECT_DIR="$(pwd)"
SKILLS=""

# Helper: check if a package.json field contains a dependency name
has_dep() {
  local name="$1"
  grep -q "\"$name\"" package.json 2>/dev/null
}

# Monorepo indicators
if [ -f "pnpm-workspace.yaml" ] || [ -f "lerna.json" ] || [ -f "nx.json" ] || [ -f "rush.json" ] || [ -f "turborepo.json" ]; then
  SKILLS="$SKILLS, monorepo"
fi

# TypeScript / JavaScript
if [ -f "tsconfig.json" ] || [ -f "jsconfig.json" ]; then
  SKILLS="$SKILLS, typescript"
  # Framework detection from package.json dependencies
  if has_dep "next";    then SKILLS="$SKILLS, nextjs"; fi
  if has_dep "elysia";  then SKILLS="$SKILLS, elysiajs"; fi
  if has_dep "hono";    then SKILLS="$SKILLS, hono-backend"; fi
  if has_dep "drizzle-orm"; then SKILLS="$SKILLS, drizzle-database"; fi
fi

# React (detect even without tsconfig)
if [ -f "vite.config.ts" ] || [ -f "vite.config.js" ] || has_dep "react" 2>/dev/null; then
  # avoid double-adding if already caught by typescript block
  case "$SKILLS" in *react-frontend*) ;; *) SKILLS="$SKILLS, react-frontend" ;; esac
fi

# Next.js config file — catches JS-only projects too
if [ -f "next.config.js" ] || [ -f "next.config.ts" ] || [ -f "next.config.mjs" ]; then
  case "$SKILLS" in *nextjs*) ;; *) SKILLS="$SKILLS, nextjs" ;; esac
fi

# Python
if [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "setup.cfg" ] || [ -f "requirements.txt" ] || [ -f "Pipfile" ] || [ -f "poetry.lock" ] || [ -f "uv.lock" ]; then
  SKILLS="$SKILLS, python"
fi

# Rust
if [ -f "Cargo.toml" ]; then
  SKILLS="$SKILLS, rust"
fi

# Go
if [ -f "go.mod" ]; then
  SKILLS="$SKILLS, go"
fi

# Docker
if [ -f "Dockerfile" ] || [ -f "docker-compose.yml" ] || [ -f "compose.yml" ] || ls Dockerfile.* 2>/dev/null | grep -q .; then
  SKILLS="$SKILLS, docker"
fi

# CI/CD
if [ -d ".github/workflows" ] || [ -f ".gitlab-ci.yml" ] || [ -f "Jenkinsfile" ] || [ -f "bitbucket-pipelines.yml" ]; then
  SKILLS="$SKILLS, ci-cd"
fi

# Always-active core skills (loaded every session)
CORE="engineering-principles, clean-code, clean-architecture, testing, error-handling, security, git-workflow, api-design"

SKILLS="${SKILLS#, }"  # strip leading ", "

echo "📐 [hub-guide] detected: ${PROJECT_DIR}"
echo "📐 [hub-guide] mandatory: ${CORE}"
if [ -n "$SKILLS" ]; then
  echo "📐 [hub-guide] project-specific: ${SKILLS}"
fi
echo "📐 [hub-guide] Apply these best-practice rules throughout this session."
echo "📐 [hub-guide] When in doubt about intent or approach — ask instead of assuming."
echo "📐 [hub-guide] All skills work regardless of your spoken language — they trigger from code context and project files, not just English keywords."
