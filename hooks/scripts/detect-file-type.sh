#!/bin/bash
# hub-guide: detect file extension and suggest language-specific rules
# Reads PreToolUse event JSON from stdin.
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
EXT="${FILE_PATH##*.}"

case "$EXT" in
  ts|tsx)                        echo "[hub-guide] .${EXT} -> typescript" ;;
  py)                            echo "[hub-guide] .py -> python" ;;
  rs)                            echo "[hub-guide] .rs -> rust" ;;
  go)                            echo "[hub-guide] .go -> go" ;;
  js|jsx)                        echo "[hub-guide] .${EXT} -> typescript" ;;
  Dockerfile|dockerfile)         echo "[hub-guide] Dockerfile -> docker" ;;
  yml|yaml)                      echo "[hub-guide] .${EXT} -> ci-cd+docker" ;;
esac
