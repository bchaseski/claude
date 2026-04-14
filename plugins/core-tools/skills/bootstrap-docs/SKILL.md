---
name: bootstrap-docs
description: >
  Analyzes a codebase and generates documentation files (ARCHITECTURE.md,
  CONVENTIONS.md, DEPENDENCIES.md, TESTING.md) that help Claude Code work
  more effectively in future conversations. Runs /init if no CLAUDE.md exists,
  then layers on supplemental docs and updates CLAUDE.md with a documentation
  index. Use when asked to "bootstrap docs", "onboard this project", "generate
  architecture docs", or "prepare this repo for Claude".
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# Bootstrap Project Documentation

Analyse a codebase and generate documentation files that give Claude Code
deeper context for future conversations. Produces four supplemental docs
and updates `CLAUDE.md` with an index pointing to them.

**Output files:**

| File | Purpose |
|------|---------|
| `ARCHITECTURE.md` | Component map, data flows, service boundaries, entry points |
| `CONVENTIONS.md` | Naming, error handling, import ordering, patterns to follow/avoid |
| `DEPENDENCIES.md` | Key libraries, why they were chosen, version constraints |
| `TESTING.md` | Test frameworks, commands, file conventions, fixture patterns |

---

## Phase 0 — CLAUDE.md Check

Check whether `CLAUDE.md` exists at the repo root:

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
[ -f "$REPO_ROOT/CLAUDE.md" ] && echo "CLAUDE_MD=exists" || echo "CLAUDE_MD=missing"
```

- **If missing:** Tell the user: "No CLAUDE.md found. Running /init to create a
  baseline before generating supplemental docs." Then run `/init` and wait for
  it to complete before proceeding.
- **If exists:** Read it and note what sections it already contains. You will
  append to it in Phase 5 — never delete existing content.

---

## Phase 1 — Detect Project

**Read `references/detect-project.md` and follow its instructions** to identify:
- Stack (Node, Python, Java, Go, Rust, Ruby)
- Framework (NestJS, Next.js, Django, Spring Boot, etc.)
- Features (Docker, CI/CD, ORM, monorepo, API specs, etc.)
- Test framework and file patterns
- Linter/formatter configuration

Report the detection results to the user:

```
=== Project Detection Results ===
Stack:      node
Framework:  nestjs
Language:   typescript
Features:   docker, prisma, github-actions
CI:         github-actions
Tests:      jest
Test files: colocated (.spec.ts)
Monorepo:   no
Configs:    eslint, prettier
```

If any field is `unknown`, note it. Do not guess.

---

## Phase 2 — Survey Codebase

Gather information needed for document generation. Do all of these:

### 2.1 Directory Structure

```bash
# Get the top 2 levels of the directory tree, excluding common noise
find "$REPO_ROOT" -maxdepth 2 -type d \
  ! -path '*/node_modules/*' \
  ! -path '*/.git/*' \
  ! -path '*/dist/*' \
  ! -path '*/build/*' \
  ! -path '*/.next/*' \
  ! -path '*/coverage/*' \
  ! -path '*/__pycache__/*' \
  ! -path '*/target/*' \
  ! -path '*/.venv/*' \
  ! -path '*/vendor/*' \
  | sort
```

### 2.2 Sample Source Files

Read 8-12 representative source files across different areas of the codebase.
Choose files that are:
- In different top-level directories/modules
- Of moderate length (50-200 lines — skip tiny config files and huge generated files)
- Representative of the main application code (not tests, not config)

These samples are used to infer conventions in Phase 4.

### 2.3 Package Manifest

Read the main package manifest:
- `package.json` (Node)
- `pyproject.toml` or `requirements.txt` (Python)
- `pom.xml` or `build.gradle` (Java)
- `go.mod` (Go)
- `Cargo.toml` (Rust)
- `Gemfile` (Ruby)

### 2.4 CI Configuration

If CI is detected, read the CI config files:
- `.github/workflows/*.yml`
- `.gitlab-ci.yml`
- `Jenkinsfile`
- `.circleci/config.yml`

Extract build, test, and lint commands from these — they are the most reliable
source for what commands actually work.

### 2.5 Linter/Formatter Configuration

If detected, read configs: `.eslintrc*`, `eslint.config.*`, `.prettierrc*`,
`ruff.toml`, `pyproject.toml [tool.ruff]`, `.editorconfig`, etc.

### 2.6 Existing Documentation

Read any existing docs: `README.md`, `ARCHITECTURE.md`, `CONTRIBUTING.md`, etc.
Note what already exists so you don't duplicate it.

---

## Phase 3 — Generate ARCHITECTURE.md (Checkpoint)

**Read `references/templates/architecture.md`** and follow the rubric to generate
the architecture document.

Use the directory structure from Phase 2.1, sampled files from Phase 2.2, and
package manifest from Phase 2.3 to build an accurate component map.

### Pre-write check for existing file

```bash
[ -f "$REPO_ROOT/ARCHITECTURE.md" ] && echo "EXISTS" || echo "NEW"
```

- **If exists:** Read it, show the user what you would change, and ask before
  overwriting.
- **If new:** Generate and write the file.

### Checkpoint

After generating ARCHITECTURE.md, present it to the user and ask:

> "Here's the architecture document I generated. Does this capture the project
> structure correctly? I'll use this understanding for the remaining docs.
> Let me know if anything needs correction."

**Wait for the user to confirm or provide corrections before continuing.**
If corrections are provided, apply them to ARCHITECTURE.md first, then carry
the corrected understanding into the remaining phases.

---

## Phase 4 — Generate Remaining Docs

After the user confirms the architecture (or you apply their corrections),
generate the remaining three documents.

### 4.1 CONVENTIONS.md

**Read `references/templates/conventions.md`** and follow the rubric.

Use the sampled source files from Phase 2.2 to infer real patterns:
- Compare naming across files to identify consistent conventions
- Look at import blocks to determine ordering conventions
- Search for error handling patterns (`throw`, `catch`, `raise`, custom errors)
- Search for logging patterns (`logger`, `console.log`, `logging`)

Check for existing file before writing (same pattern as Phase 3).

### 4.2 DEPENDENCIES.md

**Read `references/templates/dependencies.md`** and follow the rubric.

Use the package manifest from Phase 2.3. For each key dependency:
- Note the version constraint
- Check how it's used in the codebase (grep for imports)
- Infer its purpose from usage context

Check for existing file before writing.

### 4.3 TESTING.md

**Read `references/templates/testing.md`** and follow the rubric.

Use test detection from Phase 1 and CI config from Phase 2.4:
- Read 3-5 actual test files to identify patterns
- Extract test commands from `package.json` scripts, `Makefile`, or CI config
- Verify commands exist before documenting them

Check for existing file before writing.

---

## Phase 5 — Update CLAUDE.md

Read the current `CLAUDE.md` and check whether it already has a
"Project Documentation" section.

### If no documentation index exists — append one:

Add the following section at the end of `CLAUDE.md`:

```markdown
## Project Documentation

Read these docs when working on related tasks:

- **ARCHITECTURE.md** — Component map, data flows, service boundaries. Read when navigating unfamiliar areas or adding new modules.
- **CONVENTIONS.md** — Naming, error handling, import patterns. Read before writing or reviewing code.
- **DEPENDENCIES.md** — Key libraries and why they were chosen. Read when adding dependencies or suggesting alternatives.
- **TESTING.md** — Frameworks, commands, fixture patterns. Read before writing or modifying tests.
```

### If a documentation index already exists — update it:

Merge any new entries into the existing section. Do not duplicate entries.

### Add critical conventions inline

Also add a compact "Key Conventions" section to `CLAUDE.md` with the top 5
most important conventions from `CONVENTIONS.md`. These are the ones Claude
should always have in context. Example:

```markdown
## Key Conventions

- Use camelCase for variables/functions, PascalCase for classes/types
- Imports: stdlib → external → internal → relative (blank line between groups)
- Errors: throw `AppError` subclasses, never raw `Error`
- All public API endpoints require `@Auth()` decorator
- Tests co-located as `*.spec.ts` next to source files
```

---

## Phase 6 — Summary

Print a clear summary of everything generated:

```
=== bootstrap-docs complete ===

Project: <project name>
Stack:   <stack> / <framework>

Generated files:
  ✓ ARCHITECTURE.md  (new | updated)
  ✓ CONVENTIONS.md   (new | updated)
  ✓ DEPENDENCIES.md  (new | updated)
  ✓ TESTING.md       (new | updated)
  ✓ CLAUDE.md        (updated — added documentation index + key conventions)

Next steps:
  1. Review each generated file and correct any inaccuracies
  2. Commit the docs when you're satisfied
  3. Re-run /bootstrap-docs after major structural changes to refresh
```

---

## Hard Rules

1. **Never overwrite an existing file** without showing the user what will
   change and getting confirmation first
2. **Never fabricate information** — use `<!-- TODO: fill in -->` placeholders
   for anything you cannot verify from the codebase
3. **Never include secrets**, credentials, API keys, or environment variable
   values in generated docs
4. **Prefer specific over generic** — every statement should reference actual
   files, directories, or patterns from this codebase
5. **Always include the generation header** with today's date in every
   generated file
6. **CLAUDE.md updates are additive** — never delete existing content in
   CLAUDE.md, only append or update the documentation index section
7. **Never modify files outside the repo root** — only write to the project
   directory
8. **Stop and ask** if project detection returns `unknown` for both stack and
   framework — the skill may not be useful for this project type
