#!/bin/bash
# hub-guide: detect project and prime skills at session start
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

# --- build minimal context injection via Python ---
python3 << PYEOF
import json, os, sys

project_dir = """${PROJECT_DIR}"""
mandatory = """${MANDATORY}"""
skill_names = """${SKILL_NAMES}"""
plugin_root = """${PLUGIN_ROOT}"""

# Read just the foundational skill (engineering-principles) as the primer
foundational_skill = ""
f_path = os.path.join(plugin_root, "skills", "engineering-principles", "SKILL.md")
try:
    with open(f_path) as f:
        foundational_skill = f.read()
except:
    foundational_skill = "(engineering-principles skill not found)"

context = f"""<EXTREMELY_IMPORTANT>
You have the hub-guide best-practice skills loaded.

=== MANDATORY (always active) ===
{mandatory}

=== FOUNDATIONAL ===
{foundational_skill}

=== PROJECT-SPECIFIC ===
{skill_names if skill_names else "(none detected)"}

Use the Skill tool for any other hub-guide skill when its topic comes up.
Never assume or guess. Always find evidence in the codebase or docs.
</EXTREMELY_IMPORTANT>"""

if os.environ.get("CLAUDE_PLUGIN_ROOT") and not os.environ.get("COPILOT_CLI"):
    output = {
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": context
        }
    }
    json.dump(output, sys.stdout, ensure_ascii=False)
    print()
else:
    print("hub-guide skills: " + ", ".join([m for m in mandatory.split()] + ([skill_names] if skill_names else [])))
PYEOF
exit 0
