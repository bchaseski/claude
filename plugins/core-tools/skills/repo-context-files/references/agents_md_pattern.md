# AGENTS.md Pattern

## The Problem

Multiple AI coding tools read different files:
- **Claude Code** reads `CLAUDE.md` (also reads `AGENTS.md` as fallback)
- **OpenAI Codex** reads `AGENTS.md`
- **GitHub Copilot** reads `.github/copilot-instructions.md`
- **Cursor** reads `.cursorrules`

Maintaining four separate files is unsustainable — they will drift.

## Recommended Pattern

**Canonical source: `CLAUDE.md`**

If you need AGENTS.md for tool compatibility, make it thin and reference CLAUDE.md:

```markdown
# AGENTS.md

This project's AI agent instructions are maintained in [CLAUDE.md](./CLAUDE.md).
Please read that file for the full context.

<!-- If your tool doesn't follow relative links, paste CLAUDE.md content here
     and add a comment: "Synced from CLAUDE.md on <date> — update both" -->
```

## If You Must Maintain AGENTS.md Independently

Only do this if your team is primarily using non-Claude tools. In that case:
- Keep AGENTS.md as the source of truth
- Add a note at the top of CLAUDE.md: "See AGENTS.md for authoritative agent instructions"
- Enforce sync via CI: `diff CLAUDE.md AGENTS.md` (if they're near-identical)

## What AGENTS.md Uniquely Needs

If you're writing AGENTS.md for a CI/automation context (vs. interactive IDE use),
add these sections that don't belong in CLAUDE.md:

```markdown
## Autonomous Operation Rules
- Do not make changes outside the scope of the assigned task
- Do not create new files without checking if a similar one exists
- Do not modify configuration files without explicit instruction
- Always run tests before marking a task complete

## Tool Use Restrictions
- <List any tools the agent is NOT allowed to use in CI>
- <List any bash commands that require human confirmation>

## Escalation Criteria
- Escalate if the task requires changing more than 5 files
- Escalate if a dependency upgrade is needed
- Escalate if tests cannot be made to pass
```

## ADR Template (docs/decisions/)

Architecture Decision Records prevent agents from undoing intentional choices.

**File naming:** `docs/decisions/NNN-short-title.md` where NNN is zero-padded (001, 002...)

```markdown
# NNN: <Decision Title>

**Date:** YYYY-MM-DD
**Status:** Accepted | Superseded by [NNN](./NNN-...) | Deprecated

## Context
<What situation forced this decision? What constraints existed?>

## Options Considered
1. **<Option A>** — <brief description>
   - Pros: <...>
   - Cons: <...>
2. **<Option B>** — <brief description>
   - Pros: <...>
   - Cons: <...>

## Decision
We chose **<Option A>** because <reason>.

## Consequences
- <Positive consequence>
- <Negative consequence / trade-off accepted>
- <What this rules out in the future>
```
