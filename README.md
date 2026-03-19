# claude-skills

A curated collection of Claude Code skills for our engineering team. Covers automated workflows, code review tooling, and stack-specific development patterns.

## Installation

Clone this repo and run the install script to copy skills into your global Claude Code skills directory:

```bash
git clone git@<your-ghe-host>:<your-org>/claude-skills.git
cd claude-skills
./install.sh
```

This copies each skill into `~/.claude/skills/` without affecting skills from other sources. No restart required.

**Updating:**
```bash
cd /path/to/claude-skills && git pull && ./install.sh
```

**Uninstalling:**
```bash
cd /path/to/claude-skills && ./install.sh --uninstall
```

## Skills

| Skill | Description |
|---|---|
| [find-docs](./find-docs/) | Retrieves up-to-date technical documentation, API references, and code examples for any developer technology. |
| [resolve-comments](./resolve-comments/) | Autonomously resolves open PR review comments — fetches, fixes, verifies, and commits. Supports TypeScript/NestJS, Python, and Java. |

## Adding a Skill ** for Brian Only ;)

1. Create a directory under `<your-clone>/my-skill/`
2. Add a `SKILL.md` with YAML frontmatter (`name`, `description`) and instructions
3. Optionally add supporting files under `references/` or `scripts/`
4. Run `./install.sh` to copy it into `~/.claude/skills/`
5. Commit and push

```bash
mkdir -p my-skill
# create SKILL.md
./install.sh
git add my-skill/
git commit -m "feat: add my-skill"
git push
```

Refer to an existing skill like `resolve-comments` as a structural template.

## Skill Priority in Claude Code

Claude Code loads skills in this order (highest to lowest):

1. `.claude/skills/` inside the current project
2. `~/.claude/skills/` — **this repo**
3. Built-in skills

Project-level skills override global ones of the same name, which is useful for repo-specific overrides.

## Contributing

Skills in this repo are shared across the team. When editing an existing skill:

- Don't break the frontmatter `name` — it's the slash-command handle
- Test against at least one real use case before pushing
- Update the skill's `README.md` if behaviour changes meaningfully
- Keep stack-specific logic in stack modules under `references/` — not in the base `SKILL.md`
