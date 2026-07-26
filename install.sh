#!/bin/bash
# install.sh — hub-guide installer for Claude Code
# Installs skills to ~/.claude/skills/ + configures hooks in settings.local.json
# Usage:
#   ./install.sh              # Copy + hooks
#   ./install.sh --link       # Symlink (edits live) + hooks
#   ./install.sh --no-hooks   # Skills only, no hook setup
# Requires: Claude Code, python3

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="${HOME}/.claude/skills"
LINK_MODE=false
NO_HOOKS=false

for arg in "$@"; do
  case "$arg" in
    --link) LINK_MODE=true ;;
    --no-hooks) NO_HOOKS=true ;;
    --*) echo "Unknown: $arg"; exit 1 ;;
  esac
done

echo "hub-guide installer"
echo "  target: ${SKILLS_DIR}/hub-guide/"
echo "  mode: $([ "$LINK_MODE" = true ] && echo 'symlink' || echo 'copy')"

# --- install skills ---
mkdir -p "$SKILLS_DIR"
DST="${SKILLS_DIR}/hub-guide"

if [ "$LINK_MODE" = true ]; then
  rm -rf "$DST"
  ln -sf "$SCRIPT_DIR" "$DST"
else
  rm -rf "$DST"
  cp -r "$SCRIPT_DIR" "$DST"
fi

echo "  skills installed to ${DST}/"
if [ "$LINK_MODE" = true ]; then
  echo "  (symlink)"
fi

# --- configure hooks in settings.local.json ---
if [ "$NO_HOOKS" = false ]; then
  HOOKS_DIR="${DST}/hooks"
  SETTINGS_FILE="${HOME}/.claude/settings.local.json"

  python3 << PYEOF
import json, os

dst = "${DST}"
settings_file = os.path.expanduser("${SETTINGS_FILE}")

# Read existing settings or create empty
settings = {}
if os.path.exists(settings_file):
    with open(settings_file) as f:
        settings = json.load(f)

# Ensure hooks key exists
if "hooks" not in settings:
    settings["hooks"] = {}

hooks_config = {
    "SessionStart": [{
        "matcher": "startup|resume|compact",
        "hooks": [{
            "type": "command",
            "command": "bash \"" + dst + "/hooks/scripts/detect-project.sh\"",
            "timeout": 10,
            "async": False
        }]
    }],
    "PreToolUse": [{
        "matcher": "Write|Edit",
        "hooks": [{
            "type": "command",
            "command": "bash \"" + dst + "/hooks/scripts/detect-file-type.sh\"",
            "timeout": 10
        }]
    }]
}

# Merge hooks into settings (update existing, don't overwrite unrelated hooks)
for event, handlers in hooks_config.items():
    settings["hooks"][event] = handlers

os.makedirs(os.path.dirname(settings_file), exist_ok=True)
with open(settings_file, 'w') as f:
    json.dump(settings, f, indent=2)

print("  hooks configured in " + settings_file)
PYEOF
fi

echo ""
echo "Done. Restart Claude Code or run /reload."
echo "Skills auto-trigger when you work."
