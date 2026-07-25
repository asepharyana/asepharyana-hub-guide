# hub-guide — Comprehensive Programming Best-Practice Plugin

A Claude Code plugin serving as a complete engineering guide for **all programming situations** — monorepo, standalone, any language, any framework.

## Features

### 🧠 24 Best-Practice Skills

| Category | Skills |
|----------|--------|
| **Core Engineering** | clean-code, clean-architecture, design-patterns, testing, error-handling, security, api-design, git-workflow, documentation, logging-observability, performance |
| **Languages** | typescript, python, rust, go |
| **Frameworks** | react-frontend, elysiajs, hono-backend, drizzle-database, nextjs |
| **Infrastructure** | docker, ci-cd, monitoring |
| **Monorepo** | monorepo (patterns + submodules + workspace tooling) |
| **Hub-specific** | hub-guide (Asepharyana Hub monorepo infra & workflow) |

Skills activate automatically when Claude detects relevant context (language, framework, topic).

### ⚡ Hooks for Auto-Detection

| Hook | Trigger | What It Does |
|------|---------|--------------|
| **SessionStart** | Session begins | Detects project type from files (package.json, Cargo.toml, go.mod, etc.) and activates relevant skills |
| **PreToolUse** | Before Write/Edit | Detects file extension and injects language-specific best-practice rules |

## Installation

### Quick Install

```bash
# Clone
git clone https://github.com/asepharyana/asepharyana-hub-hub-guide.git
cd asepharyana-hub-hub-guide

# Copy all 26 skills (recommended)
./install.sh

# Or symlink (edits in this repo are live)
./install.sh --link

# Install only specific skills
./install.sh clean-code testing docker

# Configure hooks (auto-detect project type on session start)
./setup-hooks.sh
```

## Usage

Skills are **auto-triggered** — Claude loads them when you mention relevant topics or work with matching file types.

Example triggers:
- *"Refactor this function"* → `clean-code` activates
- *"Write a test for this"* → `testing` activates
- *"Design an API endpoint"* → `api-design` activates
- Working with `.ts` files → `typescript` activates
- Project with `Cargo.toml` → `rust` activates (SessionStart hook)

## Auto-Detection (Hooks)

When you start a session in a project, the SessionStart hook scans for:

| File | Skills Activated |
|------|-----------------|
| `tsconfig.json` | typescript, react-frontend, elysiajs, hono-backend, drizzle-database |
| `Cargo.toml` | rust |
| `go.mod` | go |
| `pyproject.toml` | python |
| `pnpm-workspace.yaml` | monorepo |
| `Dockerfile` | docker |
| `.github/workflows/` | ci-cd |

## Structure

```
hub-guide/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── hooks/
│   ├── hooks.json           # Hook configuration
│   └── scripts/
│       ├── detect-project.sh    # SessionStart auto-detection
│       └── detect-file-type.sh  # PreToolWrite language detection
├── skills/
│   ├── clean-code/          # +23 more skill directories
│   ├── ...
│   └── hub-guide/           # Existing hub monorepo guide
└── README.md
```

## Development

Skills are in `skills/<name>/SKILL.md` format (modern Claude Code plugin convention). Each skill includes:

- **Frontmatter** — `name` and `description` with specific trigger phrases
- **Lean body** — key rules, examples, and anti-patterns (~1500-2000 words)

Hooks use bash scripts. Edits to hooks/scripts/ take effect immediately when installed as a symlink.

## Related

Based on patterns from [kana-best-practice-engineering](https://github.com/asepharyana/kana-best-practice-engineering).
