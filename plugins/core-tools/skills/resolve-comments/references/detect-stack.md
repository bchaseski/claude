# Stack Detection

Probe the repository root to identify the primary stack. Run these checks in
order — stop at the first match.

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)

# 1. TypeScript / NestJS
if [ -f "$REPO_ROOT/package.json" ]; then
  if grep -q "\"@nestjs/core\"" "$REPO_ROOT/package.json" 2>/dev/null; then
    echo "STACK=nestjs"
  else
    echo "STACK=node"   # plain Node — use nestjs module as closest fit, note it
  fi

# 2. Java (Maven)
elif [ -f "$REPO_ROOT/pom.xml" ]; then
  echo "STACK=java-maven"

# 3. Java (Gradle)
elif [ -f "$REPO_ROOT/build.gradle" ] || [ -f "$REPO_ROOT/build.gradle.kts" ]; then
  echo "STACK=java-gradle"

# 4. Python (modern packaging)
elif [ -f "$REPO_ROOT/pyproject.toml" ] || [ -f "$REPO_ROOT/setup.py" ] || \
     [ -f "$REPO_ROOT/setup.cfg" ] || [ -f "$REPO_ROOT/requirements.txt" ]; then
  echo "STACK=python"

# 5. Unknown
else
  echo "STACK=unknown"
fi
```

## Monorepo / Mixed-Stack Handling

If the repo root has no clear indicator but the **changed files** sit in a
subdirectory, re-run the checks scoped to that subdirectory:

```bash
# Find the common ancestor directory of all changed files
CHANGED_DIR=$(git diff --name-only HEAD | xargs -I{} dirname {} | sort -u | head -1)
# Re-run probes with $CHANGED_DIR as the base instead of $REPO_ROOT
```

If two stacks are present (e.g., a Python service and a Java service in the same
repo), identify which stack owns the **majority of changed files** and use that.
Note the mixed-stack situation in the final summary.

## Module Mapping

| STACK value     | Load module          |
|-----------------|----------------------|
| `nestjs`        | `references/nestjs.md` |
| `node`          | `references/nestjs.md` (note: no NestJS-specific DI rules apply) |
| `java-maven`    | `references/java.md`   |
| `java-gradle`   | `references/java.md`   |
| `python`        | `references/python.md` |
| `unknown`       | none — proceed with base skill only |
