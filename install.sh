#!/usr/bin/env bash
set -euo pipefail

SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS_SOURCE="$SCRIPT_DIR/claude/settings.json"
SETTINGS_TARGET="${CLAUDE_SETTINGS_FILE:-$HOME/.claude/settings.json}"

PLUGINS_DIR="$SCRIPT_DIR/plugins"

# Auto-detect skill directories under plugins/*/skills/
ALL_SKILL_DIRS=()
CORE_SKILL_DIRS=()
GIT_SKILL_DIRS=()
# Map skill name -> source path for copying
declare -A SKILL_SOURCE_MAP

for plugin_dir in "$PLUGINS_DIR"/*/; do
    [ -d "$plugin_dir" ] || continue
    local_skills_dir="${plugin_dir}skills"
    [ -d "$local_skills_dir" ] || continue
    plugin_name="$(basename "$plugin_dir")"
    for skill_dir in "$local_skills_dir"/*/; do
        [ -d "$skill_dir" ] || continue
        if [ -f "${skill_dir}SKILL.md" ]; then
            name="$(basename "$skill_dir")"
            ALL_SKILL_DIRS+=("$name")
            SKILL_SOURCE_MAP["$name"]="$skill_dir"
            if [[ "$plugin_name" == "git-workflow" ]]; then
                GIT_SKILL_DIRS+=("$name")
            else
                CORE_SKILL_DIRS+=("$name")
            fi
        fi
    done
done

if [ ${#ALL_SKILL_DIRS[@]} -eq 0 ]; then
    echo "Error: No skills found in $PLUGINS_DIR" >&2
    exit 1
fi

# Merge repo permissions into user's settings (additive, order-preserving)
merge_permissions() {
    local source="$1"
    local target="$2"

    if ! command -v jq &>/dev/null; then
        echo ""
        echo "Warning: 'jq' not installed -- skipping permissions merge." >&2
        echo "  Install with: brew install jq  (or)  apt install jq" >&2
        echo "  Then re-run ./install.sh to merge permissions." >&2
        return 0
    fi

    local repo_perms
    repo_perms="$(jq -c '.permissions.allow // []' "$source")"
    if [ "$repo_perms" = "[]" ]; then
        return 0
    fi

    mkdir -p "$(dirname "$target")"

    local existing_json
    if [ -f "$target" ]; then
        existing_json="$(cat "$target")"
    else
        existing_json="{}"
    fi

    local count_before
    count_before="$(echo "$existing_json" | jq '.permissions.allow // [] | length')"

    local merged
    merged="$(echo "$existing_json" | jq --argjson repo_perms "$repo_perms" '
        (.permissions.allow // []) as $existing |
        .permissions.allow = (
            $existing +
            [$repo_perms[] | select(. as $r | $existing | index($r) | not)]
        )
    ')"

    local count_after
    count_after="$(echo "$merged" | jq '.permissions.allow | length')"

    echo "$merged" > "$target"

    local added=$((count_after - count_before))
    if [ "$added" -gt 0 ]; then
        echo "Added $added permission(s) to $target"
    else
        echo "Permissions already up to date in $target"
    fi
}

# Remove repo permissions from user's settings
remove_permissions() {
    local source="$1"
    local target="$2"

    if ! command -v jq &>/dev/null; then
        echo ""
        echo "Warning: 'jq' not installed -- skipping permissions removal." >&2
        return 0
    fi

    if [ ! -f "$target" ]; then
        return 0
    fi

    local repo_perms
    repo_perms="$(jq -c '.permissions.allow // []' "$source")"
    if [ "$repo_perms" = "[]" ]; then
        return 0
    fi

    local count_before
    count_before="$(jq '.permissions.allow // [] | length' "$target")"

    local merged
    merged="$(jq --argjson repo_perms "$repo_perms" '
        .permissions.allow = [
            (.permissions.allow // [])[] |
            select(. as $r | $repo_perms | index($r) | not)
        ]
    ' "$target")"

    local count_after
    count_after="$(echo "$merged" | jq '.permissions.allow | length')"

    echo "$merged" > "$target"

    local removed=$((count_before - count_after))
    if [ "$removed" -gt 0 ]; then
        echo "Removed $removed permission(s) from $target"
    else
        echo "No matching permissions to remove from $target"
    fi
}

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
    echo "Also merges permissions from claude/settings.json into"
    echo "~/.claude/settings.json (requires jq). Uninstall reverses this."
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
    # Remove repo permissions from user settings
    if [ -f "$SETTINGS_SOURCE" ]; then
        remove_permissions "$SETTINGS_SOURCE" "$SETTINGS_TARGET"
    fi
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
    cp -a "${SKILL_SOURCE_MAP[$skill]}" "$SKILLS_DIR/$skill"
done

# Merge permissions from repo settings into user settings
if [ -f "$SETTINGS_SOURCE" ]; then
    merge_permissions "$SETTINGS_SOURCE" "$SETTINGS_TARGET"
fi

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
