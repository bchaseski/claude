# resolve-comments

Autonomously resolves open PR review comments on the current branch. Fetches
unresolved threads via the GitHub CLI, implements fixes, runs stack-appropriate
verification, and commits — repeating up to 3 rounds to catch comments posted
after the push.

## Invocation

Claude Code triggers this skill automatically when you say things like:

- `resolve comments`
- `address the review feedback`
- `fix the PR comments`
- `respond to the review`

## What It Does

1. **Fetches** all unresolved review threads (inline + top-level) via `gh` CLI and GraphQL
2. **Triages** each comment — code change, question, nit, architectural disagreement, or already fixed
3. **Implements** fixes file-by-file, batching all changes to the same file in one pass
4. **Replies** to each thread with what was done (or why nothing was changed)
5. **Verifies** with stack-appropriate lint, type-check, build, and tests — stops on first failure
6. **Commits and pushes** only on a clean verification pass
7. **Waits 5 minutes** then repeats for any new comments, up to 3 rounds total

## Stack Support

The skill auto-detects the project stack and loads the appropriate module:

| Stack | Detection | Module |
|---|---|---|
| TypeScript / NestJS | `package.json` with `@nestjs/core` | `references/nestjs.md` |
| Python | `pyproject.toml`, `requirements.txt`, etc. | `references/python.md` |
| Java (Maven) | `pom.xml` | `references/java.md` |
| Java (Gradle) | `build.gradle` / `build.gradle.kts` | `references/java.md` |

Each stack module defines both the framework-specific guidance (what to watch
for when resolving comments) and the exact verification commands to run.

## Prerequisites

- `gh` CLI authenticated (`gh auth status`)
- On a feature branch with an open PR
- Not on `main`, `master`, or `develop`

## Files

```
resolve-comments/
  SKILL.md                  ← base skill (universal workflow)
  references/
    detect-stack.md         ← stack detection logic
    nestjs.md               ← TypeScript/NestJS guidance + npm verification
    python.md               ← Python guidance + ruff/mypy/pytest verification
    java.md                 ← Java guidance + Maven/Gradle verification
```

## Adding a New Stack

1. Create `references/<stack>.md` using an existing module as a template
2. Add detection logic to `references/detect-stack.md`
3. Add the new stack to the module mapping table in `detect-stack.md`
4. Update this README's stack support table
