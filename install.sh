#!/usr/bin/env bash
set -euo pipefail

SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Auto-detect skill directories (any directory containing a SKILL.md)
ALL_SKILL_DIRS=()
CORE_SKILL_DIRS=()
GIT_SKILL_DIRS=()
for dir in "$SCRIPT_DIR"/*/; do
    if [ -f "${dir}SKILL.md" ]; then
        name="$(basename "$dir")"
        ALL_SKILL_DIRS+=("$name")
        if [[ "$name" == git-* ]]; then
            GIT_SKILL_DIRS+=("$name")
        else
            CORE_SKILL_DIRS+=("$name")
        fi
    fi
done

if [ ${#ALL_SKILL_DIRS[@]} -eq 0 ]; then
    echo "Error: No skills found in $SCRIPT_DIR" >&2
    exit 1
fi

# Parse arguments
ACTION=""
SCOPE="core"
SCOPE_SET=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)    ACTION="help" ;;
        --list)       ACTION="list" ;;
        --uninstall)  ACTION="uninstall" ;;
        --git-help)   SCOPE="git-help"; SCOPE_SET=true ;;
        --core)       SCOPE="core"; SCOPE_SET=true ;;
        --all)        SCOPE="all"; SCOPE_SET=true ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Run './install.sh --help' for usage." >&2
            exit 1
            ;;
    esac
    shift
done

ACTION="${ACTION:-install}"

# Uninstall defaults to all skills unless a scope was explicitly set
if [[ "$ACTION" == "uninstall" && "$SCOPE_SET" == "false" ]]; then
    SCOPE="all"
fi

# Build target skill list based on scope
TARGET_SKILLS=()
case "$SCOPE" in
    core)
        if [ ${#CORE_SKILL_DIRS[@]} -gt 0 ]; then
            TARGET_SKILLS=("${CORE_SKILL_DIRS[@]}")
        fi
        ;;
    git-help)
        if [ ${#GIT_SKILL_DIRS[@]} -gt 0 ]; then
            TARGET_SKILLS=("${GIT_SKILL_DIRS[@]}")
        fi
        ;;
    all)
        if [ ${#ALL_SKILL_DIRS[@]} -gt 0 ]; then
            TARGET_SKILLS=("${ALL_SKILL_DIRS[@]}")
        fi
        ;;
esac

# --help
if [[ "$ACTION" == "help" ]]; then
    echo "Usage: ./install.sh [options]"
    echo ""
    echo "Copies skills from this repo into $SKILLS_DIR"
    echo "without affecting skills from other sources."
    echo ""
    echo "By default, installs core skills only."
    echo ""
    echo "Options:"
    echo "  --git-help    Target git workflow skills (git-checkpoint, git-feature-start, etc.)"
    echo "  --all         Target all skills (core + git-help)"
    echo "  --core        Target core skills only (default)"
    echo "  --list        List available skills without installing"
    echo "  --uninstall   Remove targeted skills installed by this repo"
    echo "  --help, -h    Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./install.sh              Install core skills"
    echo "  ./install.sh --git-help   Install git workflow skills"
    echo "  ./install.sh --all        Install all skills"
    echo "  ./install.sh --list       List all available skills"
    echo "  ./install.sh --uninstall  Remove all skills from this repo"
    exit 0
fi

# --list (always shows both categories for discoverability)
if [[ "$ACTION" == "list" ]]; then
    echo "Core skills:"
    if [ ${#CORE_SKILL_DIRS[@]} -eq 0 ]; then
        echo "  (none)"
    else
        for skill in "${CORE_SKILL_DIRS[@]}"; do
            echo "  - $skill"
        done
    fi
    echo ""
    echo "Git-help skills:"
    if [ ${#GIT_SKILL_DIRS[@]} -eq 0 ]; then
        echo "  (none)"
    else
        for skill in "${GIT_SKILL_DIRS[@]}"; do
            echo "  - $skill"
        done
    fi
    exit 0
fi

# --uninstall
if [[ "$ACTION" == "uninstall" ]]; then
    if [ ${#TARGET_SKILLS[@]} -eq 0 ]; then
        echo "No skills found for scope '$SCOPE'."
        exit 0
    fi
    for skill in "${TARGET_SKILLS[@]}"; do
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
if [ ${#TARGET_SKILLS[@]} -eq 0 ]; then
    echo "No skills found for scope '$SCOPE'." >&2
    exit 1
fi

mkdir -p "$SKILLS_DIR"

for skill in "${TARGET_SKILLS[@]}"; do
    if [ -d "$SKILLS_DIR/$skill" ]; then
        echo "Updating: $skill"
    else
        echo "Installing: $skill"
    fi
    rm -rf "$SKILLS_DIR/$skill"
    cp -a "$SCRIPT_DIR/$skill" "$SKILLS_DIR/$skill"
done

echo ""
echo "Installed ${#TARGET_SKILLS[@]} skill(s) to $SKILLS_DIR"

# Show other skills that were not touched
OTHER_SKILLS=()
for dir in "$SKILLS_DIR"/*/; do
    [ -d "$dir" ] || continue
    name="$(basename "$dir")"
    skip=false
    for skill in "${TARGET_SKILLS[@]}"; do
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
