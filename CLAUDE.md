# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A curated collection of Claude Code skills for Brian Chase teams. Skills are Markdown-based instruction bundles (not application code) that teach Claude Code how to accomplish specific tasks autonomously.

## Install & Update

### Via Marketplace (recommended)

```
/plugin marketplace add https://github.com/bchaseski/claude
/plugin install core-tools@zoominfo-claude-skills
/plugin install git-workflow@zoominfo-claude-skills
```

### Via install script (fallback)

```bash
./install.sh              # Install core skills (find-docs, resolve-comments)
./install.sh --git-help   # Install git workflow skills
./install.sh --all        # Install everything
./install.sh --uninstall  # Remove all installed skills
./install.sh --list       # List available skills
```

Requires `jq` for merging permissions into `~/.claude/settings.json`. Skills are copied to `~/.claude/skills/`.

Update: `git pull && ./install.sh`

## Architecture

### Plugin & Skill Structure

Skills are organized into **plugins** under `plugins/`:

```
plugins/
├── core-tools/             # Plugin: essential productivity skills
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── skills/
│       ├── find-docs/
│       ├── repo-context-files/
│       └── resolve-comments/
└── git-workflow/           # Plugin: git workflow helpers
    ├── .claude-plugin/
    │   └── plugin.json
    └── skills/
        ├── git-checkpoint/
        ├── git-feature-start/
        ├── git-resolve-conflicts/
        ├── git-submit-pr/
        └── git-sync-main/
```

Each skill directory contains a `SKILL.md` with YAML frontmatter (`name`, `description`, `allowed-tools`) and Markdown instructions. Supporting files go under `references/` or `scripts/`.

The marketplace manifest at `.claude-plugin/marketplace.json` catalogs both plugins. The installer auto-discovers skills by scanning `plugins/*/skills/` for directories containing `SKILL.md`.

### Two Plugins

- **core-tools** (default install): `find-docs`, `repo-context-files`, `resolve-comments`
- **git-workflow** (install with `--git-help`): `git-checkpoint`, `git-feature-start`, `git-resolve-conflicts`, `git-submit-pr`, `git-sync-main`

### resolve-comments Stack Modules

The `resolve-comments` skill auto-detects the project stack via `references/detect-stack.md` and loads a stack-specific module:

| Stack | Module | Detection |
|-------|--------|-----------|
| TypeScript/NestJS | `references/nestjs.md` | `package.json` with `@nestjs/core` |
| Node (non-NestJS) | `references/nestjs.md` | `package.json` without NestJS |
| Java | `references/java.md` | `pom.xml` or `build.gradle` |
| Python | `references/python.md` | `pyproject.toml`, `setup.py`, or `requirements.txt` |

### repo-context-files Skill

The `repo-context-files` skill analyzes a codebase and generates the full set of LLM-context documentation files so AI agents (Claude, Cursor, Copilot) write correct, idiomatic code. It runs `/init` if no `CLAUDE.md` exists, then generates and cross-links:

| Doc | Purpose |
|-----|---------|
| `CLAUDE.md` | The anchor — project purpose, commands, structure, key rules |
| `ARCHITECTURE.md` | Component map, data flows, technology decisions and *why*, intentional boundaries |
| `CODING_STANDARDS.md` | Prescriptive style contract — rules to follow going forward |
| `CONVENTIONS.md` | Descriptive — patterns observed in the existing code |
| `DEPENDENCIES.md` | Key libraries and why they were chosen |
| `TESTING.md` | Test frameworks, commands, fixture patterns |

It uses `references/detect-project.md` for stack/framework/feature detection (Node, Python, Java, Go, Rust, Ruby), template rubrics under `references/templates/`, and `references/agents_md_pattern.md` for the `AGENTS.md`/ADR patterns. The workflow has two checkpoints (CLAUDE.md and ARCHITECTURE.md) where it waits for user confirmation before building dependent docs. (This skill supersedes the former `bootstrap-docs` skill, folding in its detection and codebase-survey workflow.)

### Permissions

`claude/settings.json` defines pre-approved Bash command patterns (git, npm, docker, gh, etc.) that get merged into the user's global `~/.claude/settings.json` during install, so skills can run autonomously without permission prompts.

## Contributing

- The YAML frontmatter `name` field is the slash-command handle — don't rename it
- Keep stack-specific logic in stack modules under `references/`, not in the base `SKILL.md`
- Test against a real use case before pushing
- Update the skill's README if behavior changes meaningfully

## Adding a New Skill

1. Add a skill directory under the appropriate plugin: `plugins/<plugin>/skills/my-skill/`
2. Create `SKILL.md` with frontmatter (`name`, `description`) and instructions
3. Optionally add supporting files under `references/` or `scripts/`
4. Run `./install.sh` to copy into `~/.claude/skills/`
5. Use an existing skill like `resolve-comments` as a structural template
