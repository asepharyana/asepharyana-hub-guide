#!/bin/bash
# hub-guide: inject best-practice skills into context at session start
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PROJECT_DIR="$(pwd)"
SKILL_NAMES=""

has_dep() { local n="$1"; grep -q "\"$n\"" package.json 2>/dev/null; }

# --- project detection ---
if [ -f "pnpm-workspace.yaml" ] || [ -f "lerna.json" ] || [ -f "nx.json" ] || [ -f "rush.json" ] || [ -f "turborepo.json" ]; then
  SKILL_NAMES="$SKILL_NAMES, monorepo"
fi
if [ -f "tsconfig.json" ] || [ -f "jsconfig.json" ]; then
  SKILL_NAMES="$SKILL_NAMES, typescript"
  if has_dep "next";        then SKILL_NAMES="$SKILL_NAMES, nextjs"; fi
  if has_dep "elysia";      then SKILL_NAMES="$SKILL_NAMES, elysiajs"; fi
  if has_dep "hono";        then SKILL_NAMES="$SKILL_NAMES, hono-backend"; fi
  if has_dep "drizzle-orm"; then SKILL_NAMES="$SKILL_NAMES, drizzle-database"; fi
fi
if [ -f "vite.config.ts" ] || [ -f "vite.config.js" ] || has_dep "react" 2>/dev/null; then
  case "$SKILL_NAMES" in *react-frontend*) ;; *) SKILL_NAMES="$SKILL_NAMES, react-frontend" ;; esac
fi
if [ -f "next.config.js" ] || [ -f "next.config.ts" ] || [ -f "next.config.mjs" ]; then
  case "$SKILL_NAMES" in *nextjs*) ;; *) SKILL_NAMES="$SKILL_NAMES, nextjs" ;; esac
fi
if [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ] || [ -f "Pipfile" ] || [ -f "poetry.lock" ] || [ -f "uv.lock" ]; then
  SKILL_NAMES="$SKILL_NAMES, python"
fi
if [ -f "Cargo.toml" ]; then                     SKILL_NAMES="$SKILL_NAMES, rust"; fi
if [ -f "go.mod" ]; then                         SKILL_NAMES="$SKILL_NAMES, go"; fi
if [ -f "Dockerfile" ] || [ -f "docker-compose.yml" ] || [ -f "compose.yml" ] || ls Dockerfile.* 2>/dev/null | grep -q .; then
  SKILL_NAMES="$SKILL_NAMES, docker"
fi
if [ -d ".github/workflows" ] || [ -f ".gitlab-ci.yml" ] || [ -f "Jenkinsfile" ] || [ -f "bitbucket-pipelines.yml" ]; then
  SKILL_NAMES="$SKILL_NAMES, ci-cd"
fi

MANDATORY="engineering-principles clean-code clean-architecture testing error-handling security git-workflow api-design"
SKILL_NAMES="${SKILL_NAMES#, }"

# --- read skill content ---
read_skill() {
  local f="${PLUGIN_ROOT}/skills/${1}/SKILL.md"
  [ -f "$f" ] && cat "$f" || echo ""
}

# Summary header (visible in session)
echo "📐 [hub-guide] detected: ${PROJECT_DIR}"
echo "📐 mandatory: ${MANDATORY}"
[ -n "$SKILL_NAMES" ] && echo "📐 active: ${SKILL_NAMES}"
echo ""

# ─────────────────────────────────────────────────────────────────
# SKILL INJECTION — hub-guide best-practice rules
# This content is loaded into context before any user interaction.
# Claude MUST treat these as active skill instructions for every
# code decision throughout this session.
# ─────────────────────────────────────────────────────────────────
echo "<EXTREMELY_IMPORTANT>"
echo "You have the following hub-guide skills loaded and active. They apply to every code decision, review, and architecture discussion in this session — regardless of what language the user speaks."

# Inject full MANDATORY skill content
for skill in $MANDATORY; do
  content=$(read_skill "$skill")
  if [ -n "$content" ]; then
    echo ""
    echo "=== hub-guide:${skill} ==="
    echo "$content"
  fi
done

# List detected skills (their content loads on demand via Skill tool)
if [ -n "$SKILL_NAMES" ]; then
  echo ""
  echo "=== hub-guide:detected ==="
  echo "The following skills are relevant to this project's tech stack."
  echo "Load them with the Skill tool when their topics come up: ${SKILL_NAMES}"
fi

echo ""
echo "For any skill not loaded above, use the Skill tool to load it."
echo "</EXTREMELY_IMPORTANT>"