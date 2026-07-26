# code-guide — Comprehensive Programming Best-Practice Plugin

A Claude Code plugin serving as a complete engineering guide for **all programming situations** — monorepo, standalone, any language, any framework.

## Features

### 24 Best-Practice Skills

| Category | Skills |
|----------|--------|
| **Core Engineering** | clean-code, clean-architecture, design-patterns, testing, error-handling, security, api-design, git-workflow, documentation, logging-observability, performance |
| **Languages** | typescript, python, rust, go |
| **Frameworks** | react-frontend, elysiajs, hono-backend, drizzle-database, nextjs |
| **Infrastructure** | docker, ci-cd, monitoring |
| **Monorepo** | monorepo (patterns + submodules + workspace tooling) |

Skills activate automatically when Claude detects relevant context.

### SessionStart Hook

A SessionStart command hook (identical to Superpowers' pattern) injects the full `engineering-principles` skill content into context at every session start — all 29 principles covering correctness, YAGNI, KISS, DRY, never assume (show evidence), never suppress lints, root-cause fixes, and more. These rules are active from turn 1.

## Installation

### Quick Install

```bash
# From anywhere with access to the plugin directory
./install.sh

# Or symlink (edits in this repo are live)
./install.sh --link
```

## Usage

Skills are **auto-triggered** — Claude loads them when you mention relevant topics or work with matching file types.

Example triggers:
- *"Refactor this function"* → `clean-code` activates
- *"Write a test for this"* → `testing` activates
- *"Design an API endpoint"* → `api-design` activates
- Working with `.ts` files → `typescript` activates
- Project with `Cargo.toml` → `rust` activates

## Structure

```
code-guide/
├── .claude-plugin/
│   └── plugin.json           # Plugin manifest
├── hooks/
│   ├── hooks.json            # SessionStart command hook config
│   ├── run-hook.cmd          # Cross-platform polyglot wrapper
│   └── session-start         # Injects engineering-principles into context
├── skills/
│   ├── engineering-principles/  # Auto-injected at session start
│   ├── clean-code/
│   ├── ...
└── README.md
```

## How It Works

- **SessionStart hook** runs `hooks/run-hook.cmd session-start` which reads `skills/engineering-principles/SKILL.md` and injects it into the conversation context wrapped in `<EXTREMELY_IMPORTANT>` tags (same pattern as Superpowers' `using-superpowers`).
- All 24 skills are auto-discovered from the `skills/` directory.
- Skills activate when Claude detects relevant context — no manual commands needed.
