#!/bin/bash
# hub-guide: inject best-practice skill content at session start
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

# --- build context and output via Python for reliable JSON ---
python3 << PYEOF
import json, os, sys

project_dir = """${PROJECT_DIR}"""
mandatory = """${MANDATORY}"""
skill_names = """${SKILL_NAMES}"""
plugin_root = """${PLUGIN_ROOT}"""

def read_skill(name):
    path = os.path.join(plugin_root, "skills", name, "SKILL.md")
    try:
        with open(path) as f:
            return f.read()
    except:
        return ""

# Build summary
summary = f"[hub-guide] detected: {project_dir}\n[hub-guide] mandatory: {mandatory}"
if skill_names:
    summary += f"\n[hub-guide] active: {skill_names}"
summary += "\n[hub-guide] When in doubt — ask instead of assuming."
summary += "\n[hub-guide] Never assume — show evidence for everything."
summary += "\n[hub-guide] All skills work regardless of your spoken language."

# Build skill content
content_parts = []
content_parts.append("<EXTREMELY_IMPORTANT>")
content_parts.append("You have the following hub-guide skills loaded and active. They apply to every code decision, review, and architecture discussion in this session — regardless of what language the user speaks.")

for skill in mandatory.split():
    c = read_skill(skill.strip())
    content_parts.append(f"\n=== hub-guide:{skill} ===\n{c}")

if skill_names:
    content_parts.append(f"\n=== hub-guide:detected ===\nThe following skills are relevant to this project. If their topics come up, use the Skill tool to load them: {skill_names}")

content_parts.append("\nIMPORTANT: Never assume or guess. Always find evidence in the codebase, documentation, or by asking the user. Show your sources.\n</EXTREMELY_IMPORTANT>")

skill_content = "\n".join(content_parts)
full_context = f"{summary}\n\n{skill_content}"

# Output
if os.environ.get("CLAUDE_PLUGIN_ROOT") and not os.environ.get("COPILOT_CLI"):
    output = {
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": full_context
        }
    }
    json.dump(output, sys.stdout, ensure_ascii=False)
    print()
else:
    print(f"[hub-guide] detected: {project_dir}")
    print(f"[hub-guide] mandatory: {mandatory}")
    if skill_names:
        print(f"[hub-guide] active: {skill_names}")
    print("[hub-guide] When in doubt — ask instead of assuming.")
    print()
    print(skill_content)
PYEOF
exit 0
