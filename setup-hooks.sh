#!/bin/bash
# setup-hooks.sh — Configure code-guide hooks in Claude Code
#
# Adds code-guide hooks to ~/.claude/settings.local.json
# This allows Claude to auto-detect your project and suggest relevant skills.
#
# Usage: ./setup-hooks.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS_FILE="${HOME}/.claude/settings.local.json"

echo "code-guide hooks setup"

python3 << PYEOF
import json, os

script_dir = os.path.dirname(os.path.abspath(__file__))
settings_file = os.path.expanduser("~/.claude/settings.local.json")

# Read existing or create empty
if os.path.exists(settings_file):
    with open(settings_file) as f:
        cfg = json.load(f)
else:
    cfg = {}

# Build hooks config
cfg["hooks"] = {
    "SessionStart": [{
        "hooks": [{
            "type": "command",
            "command": f"bash \"{script_dir}/hooks/scripts/detect-project.sh\"",
            "timeout": 10
        }]
    }],
    "PreToolUse": [{
        "matcher": "Write|Edit",
        "hooks": [{
            "type": "command",
            "command": f"bash \"{script_dir}/hooks/scripts/detect-file-type.sh\" \"\$TOOL_INPUT\"",
            "timeout": 10
        }]
    }]
}

# Ensure parent dir exists
os.makedirs(os.path.dirname(settings_file), exist_ok=True)

with open(settings_file, 'w') as f:
    json.dump(cfg, f, indent=2)

print(f"Hooks configured in {settings_file}")
PYEOF

echo ""
echo "Restart Claude Code or run /reload to activate hooks."
