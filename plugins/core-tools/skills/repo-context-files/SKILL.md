---
name: repo-context-files
description: >
  Generate the essential LLM-context documentation files for a repository: CLAUDE.md,
  ARCHITECTURE.md, CODING_STANDARDS.md, CONVENTIONS.md, DEPENDENCIES.md, and TESTING.md.
  Analyzes the codebase first (stack/framework detection + source survey), runs /init if no
  CLAUDE.md exists, then layers on supplemental docs and cross-links them. Use this skill
  whenever someone asks about CLAUDE.md, AGENTS.md, repo documentation for AI, LLM context
  files, setting up a repo for AI-assisted development, coding standards files, architecture
  docs, or wants to "bootstrap docs", "onboard this project", "generate architecture docs",
  "prepare this repo for Claude", or "set up their repo for Claude/Cursor/Copilot". Also
  trigger when someone asks what files an AI agent needs to understand a codebase, or asks
  to generate/update any of these files from scratch or from existing code.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# Repo Context Files

Generates the documentation files that give LLM agents the context they need to write
correct, idiomatic code in a repo — without hallucinating conventions or making decisions
that conflict with your architecture. The skill **analyzes the codebase first**, then
generates each file from real evidence (sampled source, manifests, CI config) rather than
generic boilerplate.

**Output files:**

| File | Purpose |
|------|---------|
| `CLAUDE.md` | The anchor. Project purpose, commands, structure, key rules. Agents read it every session. |
| `ARCHITECTURE.md` | Component map, data flows, technology decisions and *why*, intentional boundaries. |
| `CODING_STANDARDS.md` | The prescriptive style contract — the rules to follow going forward. |
| `CONVENTIONS.md` | The patterns actually observed in the existing code (descriptive, not prescriptive). |
| `DEPENDENCIES.md` | Key libraries, why they were chosen, version constraints. |
| `TESTING.md` | Test frameworks, real commands, file conventions, fixture patterns. |

Plus: update `README.md` if stale, and optionally generate Tier 3 files (`AGENTS.md`,
ADRs, `CONTRIBUTING.md`, `SECURITY.md`) when the project warrants them.

> **CODING_STANDARDS.md vs CONVENTIONS.md** — they are deliberately different. CODING_STANDARDS
> is *prescriptive*: the contract for how new code should be written. CONVENTIONS is
> *descriptive*: what the current codebase actually does, inferred from sampled files (including
> legacy patterns to follow or avoid). Keep them distinct — do not generate one as a clone of
> the other.

---

## The File Hierarchy (and Why It Matters)

Before generating anything, understand the purpose of each file. Do NOT treat them as
interchangeable or generate them all as clones of each other.

### Tier 1 — Non-negotiable for any AI-assisted repo

#### `CLAUDE.md` ← The most important file
**What it is:** The primary AI agent instruction file. Claude Code auto-loads this from the
repo root (and from subdirectories). Every agent session starts by reading it.

**What belongs here:**
- Project purpose in 1–3 sentences
- Tech stack (language, framework, major libraries + versions)
- Critical commands: how to build, test, lint, run locally
- Project structure overview (what each top-level dir does)
- Key conventions the AI *must* follow
- Hard "do not do this" rules (forbidden patterns, libraries to avoid)
- Where to find more detailed docs (links to ARCHITECTURE.md, CODING_STANDARDS.md, etc.)

**What does NOT belong here:** Exhaustive style rules, full architecture diagrams, decision
history. Keep it scannable — agents read this on every session.

**On AGENTS.md:** Some tools (OpenAI Codex, some CI runners) look for `AGENTS.md` instead
of `CLAUDE.md`. Rather than maintaining two full files (which will drift), the recommended
pattern is: put everything in `CLAUDE.md`, then create a minimal `AGENTS.md` that simply
references it. See `references/agents_md_pattern.md`.

#### `README.md`
Standard human entry point. Agents also read this. Keep it accurate — stale READMEs
actively mislead agents. Minimum: what the project does, how to set it up, how to run it.

---

### Tier 2 — Required for any non-trivial project

#### `ARCHITECTURE.md`
The system's structural intent. Prevents the agent from making architectural choices that
violate your design — adding a database when you're serverless, calling services in the
wrong direction. Holds: component responsibilities, data flow, technology decisions *and
why*, deployment topology, and what is intentionally NOT in the system.
**Template:** `references/templates/ARCHITECTURE.md.template`.

#### `CODING_STANDARDS.md`
The detailed, prescriptive style contract. CLAUDE.md carries the rules that matter most;
this file carries the rest — naming, organization, error handling, logging, testing
requirements, security conventions, language idioms to use and avoid.
**Template:** `references/templates/CODING_STANDARDS.md.template`.

**Small project shortcut:** For small repos, fold a condensed version directly into
CLAUDE.md under a `## Coding Standards` section rather than maintaining a separate file.
Only split it out when the rules grow long enough that CLAUDE.md becomes hard to scan.

#### `CONVENTIONS.md`
The patterns *observed* in the existing code — what the codebase actually does today,
including legacy patterns to follow or migrate away from. This is the descriptive
counterpart to CODING_STANDARDS.md's prescription.
**Template:** `references/templates/CONVENTIONS.md.template`.

#### `DEPENDENCIES.md`
Key libraries grouped by purpose, with version constraints and the *why* behind notable
choices (and what NOT to add).
**Template:** `references/templates/DEPENDENCIES.md.template`.

#### `TESTING.md`
Test stack, exact runnable commands (extracted from CI/scripts — never guessed), file
conventions, and the patterns real test files use.
**Template:** `references/templates/TESTING.md.template`.

---

### Tier 3 — Add as the team/project grows

Generate these only when the project warrants it (ask the user, or offer them in the summary).

- **`docs/decisions/` (ADRs)** — A chronological log of *why* decisions were made. Prevents
  agents (and engineers) from relitigating settled questions. Template in
  `references/agents_md_pattern.md`.
- **`AGENTS.md`** — Thin compatibility file for non-Claude tools. See
  `references/agents_md_pattern.md`.
- **`CONTRIBUTING.md`** — PR process, branch naming, review expectations.
- **`SECURITY.md`** — Security model, attack surfaces, what never to log/expose.

---

## Generation Workflow

### Phase 0 — CLAUDE.md Check

Check whether `CLAUDE.md` exists at the repo root:

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
[ -f "$REPO_ROOT/CLAUDE.md" ] && echo "CLAUDE_MD=exists" || echo "CLAUDE_MD=missing"
```

- **If missing:** Tell the user: "No CLAUDE.md found. Running /init to create a baseline
  before generating the rest." Then run `/init` and wait for it to complete. You will refine
  and extend it in Phase 3.
- **If exists:** Read it and note what sections it already contains. You will update it in
  Phase 3 — never delete existing content.

### Phase 1 — Detect Project

**Read `references/detect-project.md` and follow its instructions** to identify stack,
framework, features (Docker, CI/CD, ORM, monorepo, API specs), test framework + file
patterns, and linter/formatter config. Report the detection results to the user in the
format that file specifies. If any field is `unknown`, say so — do not guess.

### Phase 2 — Survey Codebase

Gather the evidence the documents will be built from. Do all of these:

- **Directory structure** — top 2–3 levels, excluding `node_modules`, `.git`, `dist`,
  `build`, `.next`, `coverage`, `__pycache__`, `target`, `.venv`, `vendor`.
- **Sample source files** — read 8–12 representative files across different modules
  (moderate length, real application code, not tests/config). These drive CONVENTIONS.md.
- **Package manifest** — `package.json` / `pyproject.toml` / `requirements.txt` / `pom.xml`
  / `build.gradle` / `go.mod` / `Cargo.toml` / `Gemfile`. Drives DEPENDENCIES.md.
- **CI configuration** — `.github/workflows/*.yml`, `.gitlab-ci.yml`, `Jenkinsfile`,
  `.circleci/config.yml`. The most reliable source for build/test/lint commands.
- **Linter/formatter config** — `.eslintrc*`, `eslint.config.*`, `.prettierrc*`, `ruff.toml`,
  `pyproject.toml [tool.ruff]`, `.editorconfig`.
- **Existing docs** — `README.md`, `ARCHITECTURE.md`, `CONTRIBUTING.md`, etc. Note what
  already exists so you extend rather than duplicate.

### Phase 3 — Generate CLAUDE.md (Anchor, Checkpoint)

`CLAUDE.md` is the anchor every other file references — generate it first.

**Read `references/templates/CLAUDE.md.template`** and fill it from Phases 1–2. If `/init`
produced a baseline in Phase 0, refine and extend it rather than overwriting wholesale.

Then **checkpoint**: show the user the CLAUDE.md you produced and ask:

> "Here's the CLAUDE.md anchor. Does the project purpose, stack, and command list look right?
> Everything else references this file, so I want it correct before continuing."

**Wait for confirmation or corrections.** Apply corrections before proceeding.

### Phase 4 — Generate ARCHITECTURE.md (Checkpoint)

**Read `references/templates/ARCHITECTURE.md.template`** and follow the rubric. Use the
directory structure (2.1), sampled files (2.2), and manifest (2.3) to build an accurate
component map, data flow, and — most valuable for agents — the technology-decision table
with *why* each choice was made and the intentional boundaries (what's deliberately absent).

Check for an existing file first (`[ -f "$REPO_ROOT/ARCHITECTURE.md" ]`). If it exists, show
what you'd change and ask before overwriting.

Then **checkpoint**:

> "Here's the architecture document. Does this capture the structure and the key decisions
> correctly? I'll carry this understanding into the remaining docs."

**Wait for confirmation or corrections** before continuing. A corrected architecture
understanding flows into every subsequent file.

### Phase 5 — Generate Standards & Supplemental Docs

Generate the remaining documents. For each, check for an existing file first and ask before
overwriting (same pattern as Phase 4).

- **`CODING_STANDARDS.md`** — `references/templates/CODING_STANDARDS.md.template`. The
  prescriptive contract. Make it specific to this stack, not generic advice.
- **`CONVENTIONS.md`** — `references/templates/CONVENTIONS.md.template`. Inferred from the
  sampled source: real naming, import ordering, error handling, logging, patterns to
  follow, and legacy patterns to avoid. Cite specific files.
- **`DEPENDENCIES.md`** — `references/templates/DEPENDENCIES.md.template`. From the manifest;
  group by purpose, include version constraints and the *why* behind notable choices.
- **`TESTING.md`** — `references/templates/TESTING.md.template`. Extract real commands from
  CI/scripts (verify they exist — never invent), read 3–5 test files for patterns.
- **`README.md`** — generate if missing; if it exists and is stale, propose updates and ask
  before changing.

### Phase 6 — Cross-link & AGENTS.md

The files form a linked system, not independent silos. Ensure:

- `CLAUDE.md` → links to ARCHITECTURE.md and CODING_STANDARDS.md, and carries a compact
  "Key Conventions" section with the top ~5 rules from CODING_STANDARDS.md (the ones Claude
  should always have in context).
- `ARCHITECTURE.md` → references the tech stack from CLAUDE.md.
- `CODING_STANDARDS.md` → notes where CLAUDE.md's rules end and this file extends them.
- `CONVENTIONS.md` / `DEPENDENCIES.md` / `TESTING.md` → linked from CLAUDE.md's documentation
  index.

If the team uses non-Claude tools (Codex, Copilot, Cursor), offer to create a thin
`AGENTS.md` per `references/agents_md_pattern.md` rather than a second full file.

### Phase 7 — Validate & Summarize

Check for common failure modes:

- [ ] CLAUDE.md has actual runnable commands (not placeholders)
- [ ] CLAUDE.md is under ~150 lines (if longer, push detail into Tier 2 files)
- [ ] ARCHITECTURE.md has a Mermaid diagram (even a simple one)
- [ ] CODING_STANDARDS.md is specific to this stack, and CONVENTIONS.md reflects real
      sampled code — the two are not duplicates
- [ ] TESTING.md commands were verified against scripts/CI
- [ ] No two files say the same thing — shared rules are referenced, not repeated

Then print a summary:

```
=== repo-context-files complete ===

Project: <name>
Stack:   <stack> / <framework>

Generated / updated:
  ✓ CLAUDE.md           (new | updated — anchor + docs index + key conventions)
  ✓ ARCHITECTURE.md     (new | updated)
  ✓ CODING_STANDARDS.md (new | updated)
  ✓ CONVENTIONS.md      (new | updated)
  ✓ DEPENDENCIES.md     (new | updated)
  ✓ TESTING.md          (new | updated)
  ✓ README.md           (updated, if applicable)

Optional (Tier 3) — say the word and I'll add:
  • AGENTS.md, docs/decisions/ (ADRs), CONTRIBUTING.md, SECURITY.md

Next steps:
  1. Review each file and correct any inaccuracies
  2. Commit the docs when you're satisfied
  3. Re-run after major structural changes to refresh
```

---

## Common Mistakes to Avoid

**Don't make CLAUDE.md a brain dump.** An agent reading a 500-line CLAUDE.md loses the
signal in the noise. If it's getting long, split into linked files.

**Don't duplicate rules across files.** If a rule is in CODING_STANDARDS.md, CLAUDE.md should
reference that file, not repeat it. Duplication guarantees drift.

**Don't write generic advice.** "Use meaningful variable names" is useless. "Use snake_case
for Python variables, SCREAMING_SNAKE for module-level constants, prefix private functions
with `_`" is useful.

**Don't omit the negative space.** The most valuable lines are often "never do X" and "do
not use library Y because Z." This prevents the agent from confidently doing the wrong thing.

**Don't forget commands.** The #1 thing agents need and most READMEs bury: exact,
copy-pasteable commands to build, test, and lint. Put them front-and-center in CLAUDE.md.

---

## Hard Rules

1. **Analyze before writing.** Every file is built from Phase 1–2 evidence. Never generate a
   document from generic boilerplate without surveying the actual codebase.
2. **Never overwrite an existing file** without showing the user what will change and getting
   confirmation first.
3. **Never fabricate information** — use `<!-- TODO: fill in -->` placeholders for anything
   you cannot verify from the codebase.
4. **Never include secrets**, credentials, API keys, or environment variable values.
5. **Prefer specific over generic** — every statement should reference actual files,
   directories, or patterns from this codebase.
6. **Include a generation header** with today's date in every generated file.
7. **CLAUDE.md updates are additive** — never delete existing content; append or update the
   documentation index and key-conventions sections.
8. **Never modify files outside the repo root** — only write to the project directory.
9. **Respect the two checkpoints** (CLAUDE.md in Phase 3, ARCHITECTURE.md in Phase 4) — wait
   for user confirmation before building dependent docs on top of them.
10. **Stop and ask** if project detection returns `unknown` for both stack and framework —
    the skill may not be useful for this project type.
