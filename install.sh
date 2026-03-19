#!/usr/bin/env bash
set -euo pipefail

SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Auto-detect skill directories (any directory containing a SKILL.md)
SKILL_DIRS=()
for dir in "$SCRIPT_DIR"/*/; do
    if [ -f "${dir}SKILL.md" ]; then
        SKILL_DIRS+=("$(basename "$dir")")
    fi
done

if [ ${#SKILL_DIRS[@]} -eq 0 ]; then
    echo "Error: No skills found in $SCRIPT_DIR" >&2
    exit 1
fi

# --help
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo "Usage: ./install.sh [--list | --uninstall | --help]"
    echo ""
    echo "Copies skills from this repo into $SKILLS_DIR"
    echo "without affecting skills from other sources."
    echo ""
    echo "Options:"
    echo "  --list        List available skills without installing"
    echo "  --uninstall   Remove skills installed by this repo"
    echo "  --help, -h    Show this help message"
    exit 0
fi

# --list
if [[ "${1:-}" == "--list" ]]; then
    echo "Available skills:"
    for skill in "${SKILL_DIRS[@]}"; do
        echo "  - $skill"
    done
    exit 0
fi

# --uninstall
if [[ "${1:-}" == "--uninstall" ]]; then
    for skill in "${SKILL_DIRS[@]}"; do
        if [ -d "$SKILLS_DIR/$skill" ]; then
            rm -rf "$SKILLS_DIR/$skill"
            echo "Removed: $skill"
        else
            echo "Not found (skipping): $skill"
        fi
    done
    exit 0
fi

# Install
mkdir -p "$SKILLS_DIR"

for skill in "${SKILL_DIRS[@]}"; do
    if [ -d "$SKILLS_DIR/$skill" ]; then
        echo "Updating: $skill"
    else
        echo "Installing: $skill"
    fi
    rm -rf "$SKILLS_DIR/$skill"
    cp -a "$SCRIPT_DIR/$skill" "$SKILLS_DIR/$skill"
done

echo ""
echo "Installed ${#SKILL_DIRS[@]} skill(s) to $SKILLS_DIR"

# Show other skills that were not touched
OTHER_SKILLS=()
for dir in "$SKILLS_DIR"/*/; do
    [ -d "$dir" ] || continue
    name="$(basename "$dir")"
    skip=false
    for skill in "${SKILL_DIRS[@]}"; do
        if [[ "$name" == "$skill" ]]; then
            skip=true
            break
        fi
    done
    if ! $skip; then
        OTHER_SKILLS+=("$name")
    fi
done

if [ ${#OTHER_SKILLS[@]} -gt 0 ]; then
    echo ""
    echo "Other skills present (not modified):"
    for other in "${OTHER_SKILLS[@]}"; do
        echo "  - $other"
    done
fi
