# code-guide — Comprehensive Programming Best-Practice Plugin

A Claude Code plugin serving as a complete engineering guide for **all programming situations** — monorepo, standalone, any language, any framework.

All best-practice guides are **injected directly into the system prompt** at every session start via a `SessionStart` hook (same pattern as the `explanatory-output-style` plugin). No manual skill invocation needed — all guides are always active.

## Features

### 25 Best-Practice Guides (Always Active)

| Category | Guides |
|----------|--------|
| **Core Engineering** | engineering-principles, clean-code, clean-architecture, design-patterns, testing, error-handling, security, api-design, git-workflow, documentation, logging-observability, performance |
| **Languages** | typescript, python, rust, go |
| **Frameworks** | react-frontend, elysiajs, hono-backend, drizzle-database, nextjs |
| **Infrastructure** | docker, ci-cd, monitoring |
| **Monorepo** | monorepo (patterns + submodules + workspace tooling) |

### SessionStart Hook (All Skills Injected)

A SessionStart command hook reads **every** `skills/*/SKILL.md` file and injects all content into the conversation context at session start — wrapped in `<CODE_GUIDE_SKILLS>` tags (same pattern as `explanatory-output-style`'s `additionalContext` injection). All 25 guides are active from turn 1, no separate invocation needed.

## Installation

### Quick Install

```bash
# From anywhere with access to the plugin directory
./install.sh

# Or symlink (edits in this repo are live)
./install.sh --link
```

## Usage

All guides are **always present in context** — Claude automatically applies the relevant guidance based on the current task, file types, and project structure.

Skills activate automatically when the task matches their domain:
- *"Refactor this function"* → `clean-code` guides apply
- *"Write a test for this"* → `testing` guides apply
- *"Design an API endpoint"* → `api-design` guides apply
- Working with `.ts` files → `typescript` guides apply
- Project with `Cargo.toml` → `rust` guides apply

## Structure

```
code-guide/
├── .claude-plugin/
│   └── plugin.json           # Plugin manifest (no skills auto-discovery)
├── hooks/
│   ├── hooks.json            # SessionStart command hook config
│   ├── run-hook.cmd          # Cross-platform polyglot wrapper
│   └── session-start         # Injects ALL skills/*/SKILL.md into context
├── skills/                   # Source files read by the SessionStart hook
│   ├── engineering-principles/
│   ├── clean-code/
│   ├── ...
└── README.md
```

## How It Works

1. **SessionStart hook** runs `hooks/run-hook.cmd session-start`.
2. The hook script iterates over **all** `skills/*/SKILL.md` files.
3. Each skill's content is combined and injected as `additionalContext` wrapped in `<CODE_GUIDE_SKILLS>` tags — same `hookSpecificOutput.additionalContext` pattern as `explanatory-output-style`.
4. All 25 guides are **always present** in the system prompt — no separate skill invocation needed.
