#!/bin/bash
# install.sh — hub-guide installer for Claude Code
# Installs the entire hub-guide directory as one unit into ~/.claude/skills/.
# Skills auto-discover, hooks auto-load from hooks/hooks.json.
# Usage:
#   ./install.sh              # Copy hub-guide to ~/.claude/skills/
#   ./install.sh --link       # Symlink (edits live)
# Requires: Claude Code

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="${HOME}/.claude/skills"
LINK_MODE=false

for arg in "$@"; do
  case "$arg" in
    --link) LINK_MODE=true ;;
    --*) echo "Unknown: $arg"; exit 1 ;;
  esac
done

echo "code-guide installer"
echo "  target: ${SKILLS_DIR}/code-guide/"
echo "  mode: $([ "$LINK_MODE" = true ] && echo 'symlink' || echo 'copy')"

mkdir -p "$SKILLS_DIR"
DST="${SKILLS_DIR}/hub-guide"

if [ "$LINK_MODE" = true ]; then
  rm -rf "$DST"
  ln -sf "$SCRIPT_DIR" "$DST"
else
  rm -rf "$DST"
  cp -r "$SCRIPT_DIR" "$DST"
fi

echo "  installed to ${DST}/"
if [ "$LINK_MODE" = true ]; then
  echo "  (symlink — edits in this repo are live)"
fi
echo ""
echo "Done. Restart Claude Code or run /reload."
echo "Skills auto-trigger. Hooks auto-load from hooks/hooks.json."
