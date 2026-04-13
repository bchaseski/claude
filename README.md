# claude-skills

A curated collection of Claude Code skills for our engineering team. Covers automated workflows, code review tooling, and stack-specific development patterns.

## Installation

### Via Plugin Marketplace (recommended)

Register this repo as a marketplace in Claude Code, then install plugins directly:

```
/plugin marketplace add https://git.zoominfo.com/brian-chase/claude
/plugin install core-tools@zoominfo-claude-skills
/plugin install git-workflow@zoominfo-claude-skills
```

Updates happen automatically when changes are pushed to this repo.

### Via Install Script

Clone this repo and run the install script to copy skills into your global Claude Code skills directory:

```bash
git clone https://git.zoominfo.com/brian-chase/claude.git
cd claude
./install.sh              # Install core skills
./install.sh --git-help   # Install git workflow skills
./install.sh --all        # Install everything
```

This copies each skill into `~/.claude/skills/` without affecting skills from other sources. No restart required.

The install script also merges permissions from `claude/settings.json` into `~/.claude/settings.json`, auto-allowing common safe commands (git, npm, docker, etc.). Existing permissions are preserved. Requires `jq` (`brew install jq` / `apt install jq`) -- if missing, a warning is printed and skills are still installed.

**Updating:**
```bash
cd /path/to/claude-skills && git pull && ./install.sh
```

**Uninstalling:**
```bash
cd /path/to/claude-skills && ./install.sh --uninstall             # Remove all skills from this repo
cd /path/to/claude-skills && ./install.sh --uninstall --git-help  # Remove only git workflow skills
```

## Skills

| Skill | Description |
|---|---|
| [find-docs](./plugins/core-tools/skills/find-docs/) | Retrieves up-to-date technical documentation, API references, and code examples for any developer technology. |
| [resolve-comments](./plugins/core-tools/skills/resolve-comments/) | Autonomously resolves open PR review comments — fetches, fixes, verifies, and commits. Supports TypeScript/NestJS, Python, and Java. |

### Git Workflow Skills

Optional set of skills that guide common git operations. Install with `./install.sh --git-help`.

| Skill | Description |
|---|---|
| [git-checkpoint](./plugins/git-workflow/skills/git-checkpoint/) | Save/commit current work with a clear commit message. |
| [git-feature-start](./plugins/git-workflow/skills/git-feature-start/) | Start a new feature branch from an up-to-date base. |
| [git-submit-pr](./plugins/git-workflow/skills/git-submit-pr/) | Push the current branch and open a pull request via GitHub CLI. |
| [git-sync-main](./plugins/git-workflow/skills/git-sync-main/) | Sync the current branch with the latest changes from its base branch. |

## Adding a Skill ** for Brian Only ;)

1. Add a skill directory under the appropriate plugin: `plugins/<plugin>/skills/my-skill/`
2. Add a `SKILL.md` with YAML frontmatter (`name`, `description`) and instructions
3. Optionally add supporting files under `references/` or `scripts/`
4. Run `./install.sh` to copy it into `~/.claude/skills/`
5. Commit and push

```bash
mkdir -p plugins/core-tools/skills/my-skill
# create SKILL.md
./install.sh
git add plugins/core-tools/skills/my-skill/
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
