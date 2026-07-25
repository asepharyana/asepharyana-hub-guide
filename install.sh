#!/bin/bash
# install.sh — hub-guide plugin installer for Claude Code
#
# Usage:
#   ./install.sh                           # Install to ~/.claude/plugins/ + register in settings.json
#   ./install.sh --link                    # Symlink (edits in this repo are live)
#   ./install.sh --no-hooks                # Skills only, skip hooks
#   ./install.sh clean-code testing        # Install specific skills only
#
# Requires: Claude Code, python3 (for JSON manipulation)

set -euo pipefail

PLUGIN_NAME="hub-guide"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Determine target
if [ "${1:-}" = "--link" ]; then
  LINK_MODE=true
  TARGET_DIR="${HOME}/.claude/plugins"
  shift
else
  TARGET_DIR="${HOME}/.claude/plugins"
fi

LINK_MODE="${LINK_MODE:-false}"
INSTALL_HOOKS=true
FILTER_SKILLS=()

# Parse remaining args
for arg in "$@"; do
  case "$arg" in
    --no-hooks) INSTALL_HOOKS=false ;;
    --link) LINK_MODE=true ;;
    --*) echo "Unknown option: $arg"; exit 1 ;;
    *) FILTER_SKILLS+=("$arg") ;;
  esac
done

echo "📐 hub-guide installer"

# Ensure target dir exists
mkdir -p "${TARGET_DIR}/${PLUGIN_NAME}"

install_item() {
  local src="$1"
  local dst="${TARGET_DIR}/${PLUGIN_NAME}/${src#${SCRIPT_DIR}/}"

  if [ "$LINK_MODE" = true ]; then
    mkdir -p "$(dirname "$dst")"
    ln -sf "$src" "$dst"
  else
    rm -rf "$dst"
    cp -r "$src" "$dst"
  fi
}

# Install manifest
echo "  .claude-plugin/ → ${TARGET_DIR}/${PLUGIN_NAME}/"
install_item "${SCRIPT_DIR}/.claude-plugin"

# Install hooks
if [ "$INSTALL_HOOKS" = true ]; then
  echo "  hooks/ → ${TARGET_DIR}/${PLUGIN_NAME}/hooks/"
  if [ "$LINK_MODE" = true ]; then
    ln -sf "${SCRIPT_DIR}/hooks" "${TARGET_DIR}/${PLUGIN_NAME}/hooks"
  else
    cp -r "${SCRIPT_DIR}/hooks" "${TARGET_DIR}/${PLUGIN_NAME}/"
  fi
fi

# Install skills
if [ ${#FILTER_SKILLS[@]} -gt 0 ]; then
  # Install only specified skills
  for skill in "${FILTER_SKILLS[@]}"; do
    skill_name=$(basename "$skill")
    skill_src="${SCRIPT_DIR}/skills/${skill_name}"
    if [ -d "$skill_src" ]; then
      echo "  skills/${skill_name}/ → ${TARGET_DIR}/${PLUGIN_NAME}/skills/"
      if [ "$LINK_MODE" = true ]; then
        ln -sf "$skill_src" "${TARGET_DIR}/${PLUGIN_NAME}/skills/${skill_name}"
      else
        mkdir -p "${TARGET_DIR}/${PLUGIN_NAME}/skills"
        cp -r "$skill_src" "${TARGET_DIR}/${PLUGIN_NAME}/skills/"
      fi
    else
      echo "  ⚠️  Skill '${skill_name}' not found at ${skill_src}"
    fi
  done
else
  # Install all skills
  echo "  skills/ (all 26) → ${TARGET_DIR}/${PLUGIN_NAME}/skills/"
  if [ "$LINK_MODE" = true ]; then
    ln -sf "${SCRIPT_DIR}/skills" "${TARGET_DIR}/${PLUGIN_NAME}/skills"
  else
    cp -r "${SCRIPT_DIR}/skills" "${TARGET_DIR}/${PLUGIN_NAME}/"
  fi
fi

# Register in settings.json so Claude Code loads the plugin
SETTINGS_FILE="${HOME}/.claude/settings.json"
if [ "$TARGET_DIR" = "${HOME}/.claude/plugins" ] && [ -f "$SETTINGS_FILE" ]; then
  if grep -q "\"${PLUGIN_NAME}\"" "$SETTINGS_FILE" 2>/dev/null; then
    echo "  ⏭️  ${PLUGIN_NAME} already registered in settings.json"
  else
    # Add to enabledPlugins using Python for reliable JSON manipulation
    python3 -c "
import json, sys
with open('$SETTINGS_FILE') as f: cfg = json.load(f)
cfg.setdefault('enabledPlugins', {})['${PLUGIN_NAME}'] = True
with open('$SETTINGS_FILE', 'w') as f: json.dump(cfg, f, indent=2)
" && echo "  ✅ Registered ${PLUGIN_NAME} in settings.json enabledPlugins"
  fi
fi

echo ""
echo "✅ hub-guide installed to ${TARGET_DIR}/${PLUGIN_NAME}/"
if [ "$LINK_MODE" = true ]; then
  echo "   (symlink — edits in this repo are live)"
fi
echo ""
echo "   Restart Claude Code or run /reload to activate."
echo "   Skills auto-trigger when you work — no commands needed."
