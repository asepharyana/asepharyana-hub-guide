#!/bin/bash
# hub-guide: detect file extension from tool input and suggest language-specific rules
# Runs before Write/Edit to inject best-practice context

TOOL_INPUT="$1"

# Extract file path from tool input (looks for "file_path" in JSON)
FILE_PATH=$(echo "$TOOL_INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
EXT="${FILE_PATH##*.}"

case "$EXT" in
  ts|tsx)   echo "📐 .${EXT} → typescript:strict" ;;
  py)       echo "📐 .py → python:strict" ;;
  rs)       echo "📐 .rs → rust:strict" ;;
  go)       echo "📐 .go → go:strict" ;;
  js|jsx)   echo "📐 .${EXT} → typescript:esm" ;;
  Dockerfile|dockerfile) echo "📐 Dockerfile → docker:minimal" ;;
  yml|yaml) echo "📐 .${EXT} → ci-cd+docker" ;;
esac
