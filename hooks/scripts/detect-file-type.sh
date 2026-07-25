#!/bin/bash
# hub-guide: detect file extension from tool input and suggest language-specific rules
# Runs before Write/Edit to inject best-practice context

TOOL_INPUT="$1"

# Extract file path from tool input (looks for "file_path" in JSON)
FILE_PATH=$(echo "$TOOL_INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
EXT="${FILE_PATH##*.}"

case "$EXT" in
  ts|tsx)
    echo "📐 [hub-guide] TypeScript file — apply typescript skill rules (strict types, no-any, proper generics)"
    ;;
  py)
    echo "📐 [hub-guide] Python file — apply python skill rules (type hints, PEP 8, no wildcard imports)"
    ;;
  rs)
    echo "📐 [hub-guide] Rust file — apply rust skill rules (ownership, error handling, clippy clean)"
    ;;
  go)
    echo "📐 [hub-guide] Go file — apply go skill rules (idiomatic Go, interfaces, error handling)"
    ;;
  js|jsx)
    echo "📐 [hub-guide] JavaScript file — apply typescript skill rules (ESM, modern JS)"
    ;;
  dockerfile|Dockerfile)
    echo "📐 [hub-guide] Dockerfile — apply docker skill rules (multi-stage, minimal layers, no root)"
    ;;
  yml|yaml)
    echo "📐 [hub-guide] YAML file — check ci-cd and docker skill rules"
    ;;
esac
