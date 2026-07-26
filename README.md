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

Skills activate automatically when Claude detects relevant context (language, framework, topic).

### Hooks for Auto-Activation

| Hook | Trigger | What It Does |
|------|---------|--------------|
| **Stop** | Before stopping | Verifies mandatory skills are being applied (engineering-principles, clean-code, clean-architecture, testing, error-handling, security, git-workflow, api-design) |

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
│   └── hooks.json            # Hook configuration (Stop prompt)
├── skills/
│   ├── clean-code/            # 23 more skill directories
│   └── ...
└── README.md
```

## Development

Skills are in `skills/<name>/SKILL.md` format (modern Claude Code plugin convention). Each skill includes:

- **Frontmatter** — `name` and `description` with trigger context
- **Lean body** — key rules, examples, and anti-patterns

The Stop hook injects reminders when mandatory skills aren't being applied.
