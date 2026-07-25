#!/bin/bash
# hub-guide: load best-practice skills at session start
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PROJECT_DIR="$(pwd)"
SKILL_NAMES=""

# Helper: check if a package.json field contains a dependency name
has_dep() { local n="$1"; grep -q "\"$n\"" package.json 2>/dev/null; }

# --- project detection ---
if [ -f "pnpm-workspace.yaml" ] || [ -f "lerna.json" ] || [ -f "nx.json" ] || [ -f "rush.json" ] || [ -f "turborepo.json" ]; then
  SKILL_NAMES="$SKILL_NAMES, monorepo"
fi
if [ -f "tsconfig.json" ] || [ -f "jsconfig.json" ]; then
  SKILL_NAMES="$SKILL_NAMES, typescript"
  if has_dep "next";             then SKILL_NAMES="$SKILL_NAMES, nextjs"; fi
  if has_dep "elysia";           then SKILL_NAMES="$SKILL_NAMES, elysiajs"; fi
  if has_dep "hono";             then SKILL_NAMES="$SKILL_NAMES, hono-backend"; fi
  if has_dep "drizzle-orm";      then SKILL_NAMES="$SKILL_NAMES, drizzle-database"; fi
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
if [ -f "Cargo.toml" ]; then            SKILL_NAMES="$SKILL_NAMES, rust"; fi
if [ -f "go.mod" ]; then                SKILL_NAMES="$SKILL_NAMES, go"; fi
if [ -f "Dockerfile" ] || [ -f "docker-compose.yml" ] || [ -f "compose.yml" ] || ls Dockerfile.* 2>/dev/null | grep -q .; then
  SKILL_NAMES="$SKILL_NAMES, docker"
fi
if [ -d ".github/workflows" ] || [ -f ".gitlab-ci.yml" ] || [ -f "Jenkinsfile" ] || [ -f "bitbucket-pipelines.yml" ]; then
  SKILL_NAMES="$SKILL_NAMES, ci-cd"
fi

MANDATORY="engineering-principles clean-code clean-architecture testing error-handling security git-workflow api-design"
SKILL_NAMES="${SKILL_NAMES#, }"

# --- load skill content for context injection ---
load_skill() {
  local f="${PLUGIN_ROOT}/skills/${1}/SKILL.md"
  [ -f "$f" ] && cat "$f" || echo "(skill $1 not found)"
}

# Output summary (visible in session)
echo "📐 [hub-guide] detected: ${PROJECT_DIR}"
echo "📐 mandatory: ${MANDATORY}"
[ -n "$SKILL_NAMES" ] && echo "📐 active: ${SKILL_NAMES}"
echo "📐 When in doubt — ask instead of assuming."

# Inject full skill content into conversation context.
# Everything printed here is visible to Claude at session start.
echo ""
echo "<hub-guide-skills>"

for skill in $MANDATORY; do
  echo "<skill name=\"${skill}\">"
  load_skill "$skill"
  echo "</skill>"
done

if [ -n "$SKILL_NAMES" ]; then
  echo "<detected-skills>${SKILL_NAMES}</detected-skills>"
fi
echo "</hub-guide-skills>"
echo ""
echo "Skills above are loaded. Apply these best-practice rules throughout this session."
echo "When in doubt about intent or approach — ask instead of assuming."
