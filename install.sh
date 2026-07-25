#!/bin/bash
# install.sh — hub-guide skill installer for Claude Code
#
# Skills go to ~/.claude/skills/<name>/ where Claude Code auto-discovers them.
# Hooks can be configured manually (see README).
#
# Usage:
#   ./install.sh                        # Copy all 26 skills to ~/.claude/skills/
#   ./install.sh --link                 # Symlink (edits in this repo are live)
#   ./install.sh clean-code testing     # Install specific skills only
#   ./install.sh --link clean-code      # Symlink specific skills
#
# Requires: Claude Code

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="${HOME}/.claude/skills"
LINK_MODE=false
FILTER_SKILLS=()

# Parse args
for arg in "$@"; do
  case "$arg" in
    --link) LINK_MODE=true ;;
    --*) echo "Unknown option: $arg"; exit 1 ;;
    *) FILTER_SKILLS+=("$arg") ;;
  esac
done

echo "📐 hub-guide installer"
echo "   Target: ${SKILLS_DIR}/"
echo "   Mode: $([ "$LINK_MODE" = true ] && echo 'symlink' || echo 'copy')"
echo ""

# Ensure target dir exists
mkdir -p "$SKILLS_DIR"

if [ ${#FILTER_SKILLS[@]} -gt 0 ]; then
  INSTALL_LIST=()
  for skill in "${FILTER_SKILLS[@]}"; do
    skill_name=$(basename "$skill")
    src="${SCRIPT_DIR}/skills/${skill_name}"
    if [ -d "$src" ]; then
      INSTALL_LIST+=("$skill_name")
    else
      echo "  ⚠️  Skill '${skill_name}' not found"
    fi
  done
else
  # Gather all skills from source
  INSTALL_LIST=()
  for d in "${SCRIPT_DIR}/skills/"*/; do
    INSTALL_LIST+=("$(basename "$d")")
  done
fi

installed=0
for skill_name in "${INSTALL_LIST[@]}"; do
  src="${SCRIPT_DIR}/skills/${skill_name}"
  dst="${SKILLS_DIR}/${skill_name}"

  if [ "$LINK_MODE" = true ]; then
    rm -rf "$dst"
    ln -sf "$src" "$dst"
  else
    rm -rf "$dst"
    mkdir -p "$(dirname "$dst")"
    cp -r "$src" "$dst"
  fi
  echo "  ✅ ${skill_name}"
  installed=$((installed + 1))
done

echo ""
echo "✅ ${installed} skill(s) installed to ${SKILLS_DIR}/"
if [ "$LINK_MODE" = true ]; then
  echo "   (symlink — edits in this repo are live)"
fi
echo ""
echo "   Restart Claude Code or run /reload."
echo "   Skills auto-trigger when you work — no commands needed."
echo ""
echo "📌 Hooks (auto-detect project):"
echo "   For hooks support, add to ~/.claude/settings.local.json or"
echo "   run: ./setup-hooks.sh"
