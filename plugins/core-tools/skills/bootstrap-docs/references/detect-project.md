# Project Detection

Probe the repository to identify the stack, framework, features, and test setup.
Run these checks from the repo root.

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
```

## 1. Stack & Framework Detection

Run these checks in order — stop at the first match.

```bash
# 1. TypeScript / JavaScript
if [ -f "$REPO_ROOT/package.json" ]; then
  if grep -q '"@nestjs/core"' "$REPO_ROOT/package.json" 2>/dev/null; then
    echo "STACK=node FRAMEWORK=nestjs"
  elif grep -q '"next"' "$REPO_ROOT/package.json" 2>/dev/null; then
    echo "STACK=node FRAMEWORK=nextjs"
  elif grep -q '"express"' "$REPO_ROOT/package.json" 2>/dev/null; then
    echo "STACK=node FRAMEWORK=express"
  elif grep -q '"fastify"' "$REPO_ROOT/package.json" 2>/dev/null; then
    echo "STACK=node FRAMEWORK=fastify"
  elif grep -q '"react"' "$REPO_ROOT/package.json" 2>/dev/null; then
    echo "STACK=node FRAMEWORK=react"
  elif grep -q '"vue"' "$REPO_ROOT/package.json" 2>/dev/null; then
    echo "STACK=node FRAMEWORK=vue"
  elif grep -q '"angular"' "$REPO_ROOT/package.json" 2>/dev/null; then
    echo "STACK=node FRAMEWORK=angular"
  else
    echo "STACK=node FRAMEWORK=none"
  fi

# 2. Python
elif [ -f "$REPO_ROOT/pyproject.toml" ] || [ -f "$REPO_ROOT/setup.py" ] || \
     [ -f "$REPO_ROOT/setup.cfg" ] || [ -f "$REPO_ROOT/requirements.txt" ]; then
  if grep -rql "django" "$REPO_ROOT/pyproject.toml" "$REPO_ROOT/requirements.txt" 2>/dev/null; then
    echo "STACK=python FRAMEWORK=django"
  elif grep -rql "fastapi" "$REPO_ROOT/pyproject.toml" "$REPO_ROOT/requirements.txt" 2>/dev/null; then
    echo "STACK=python FRAMEWORK=fastapi"
  elif grep -rql "flask" "$REPO_ROOT/pyproject.toml" "$REPO_ROOT/requirements.txt" 2>/dev/null; then
    echo "STACK=python FRAMEWORK=flask"
  else
    echo "STACK=python FRAMEWORK=none"
  fi

# 3. Java (Maven)
elif [ -f "$REPO_ROOT/pom.xml" ]; then
  if grep -q "spring-boot" "$REPO_ROOT/pom.xml" 2>/dev/null; then
    echo "STACK=java FRAMEWORK=spring-boot"
  else
    echo "STACK=java FRAMEWORK=none"
  fi

# 4. Java (Gradle)
elif [ -f "$REPO_ROOT/build.gradle" ] || [ -f "$REPO_ROOT/build.gradle.kts" ]; then
  GRADLE_FILE=$(ls "$REPO_ROOT"/build.gradle* 2>/dev/null | head -1)
  if grep -q "spring-boot" "$GRADLE_FILE" 2>/dev/null; then
    echo "STACK=java FRAMEWORK=spring-boot"
  else
    echo "STACK=java FRAMEWORK=none"
  fi

# 5. Go
elif [ -f "$REPO_ROOT/go.mod" ]; then
  if grep -q "gin-gonic" "$REPO_ROOT/go.mod" 2>/dev/null; then
    echo "STACK=go FRAMEWORK=gin"
  elif grep -q "labstack/echo" "$REPO_ROOT/go.mod" 2>/dev/null; then
    echo "STACK=go FRAMEWORK=echo"
  elif grep -q "go-chi/chi" "$REPO_ROOT/go.mod" 2>/dev/null; then
    echo "STACK=go FRAMEWORK=chi"
  else
    echo "STACK=go FRAMEWORK=none"
  fi

# 6. Rust
elif [ -f "$REPO_ROOT/Cargo.toml" ]; then
  if grep -q "actix-web" "$REPO_ROOT/Cargo.toml" 2>/dev/null; then
    echo "STACK=rust FRAMEWORK=actix"
  elif grep -q "axum" "$REPO_ROOT/Cargo.toml" 2>/dev/null; then
    echo "STACK=rust FRAMEWORK=axum"
  elif grep -q "rocket" "$REPO_ROOT/Cargo.toml" 2>/dev/null; then
    echo "STACK=rust FRAMEWORK=rocket"
  else
    echo "STACK=rust FRAMEWORK=none"
  fi

# 7. Ruby
elif [ -f "$REPO_ROOT/Gemfile" ]; then
  if grep -q "rails" "$REPO_ROOT/Gemfile" 2>/dev/null; then
    echo "STACK=ruby FRAMEWORK=rails"
  elif grep -q "sinatra" "$REPO_ROOT/Gemfile" 2>/dev/null; then
    echo "STACK=ruby FRAMEWORK=sinatra"
  else
    echo "STACK=ruby FRAMEWORK=none"
  fi

# 8. Unknown
else
  echo "STACK=unknown FRAMEWORK=unknown"
fi
```

## 2. Feature Detection

Check for the presence of these features. Report all that apply.

```bash
# Language type (for Node projects)
if [ -f "$REPO_ROOT/tsconfig.json" ]; then echo "LANG=typescript"; else echo "LANG=javascript"; fi

# API specs
ls "$REPO_ROOT"/openapi.* "$REPO_ROOT"/swagger.* "$REPO_ROOT"/**/openapi.* 2>/dev/null && echo "FEATURE=openapi"

# ORM / Database
[ -f "$REPO_ROOT/prisma/schema.prisma" ] && echo "FEATURE=prisma"
grep -rql "typeorm\|TypeORM" "$REPO_ROOT/package.json" 2>/dev/null && echo "FEATURE=typeorm"
grep -rql "sequelize" "$REPO_ROOT/package.json" 2>/dev/null && echo "FEATURE=sequelize"
grep -rql "sqlalchemy\|SQLAlchemy" "$REPO_ROOT/pyproject.toml" "$REPO_ROOT/requirements.txt" 2>/dev/null && echo "FEATURE=sqlalchemy"
ls "$REPO_ROOT"/migrations/ "$REPO_ROOT"/alembic/ "$REPO_ROOT"/**/migrations/ 2>/dev/null && echo "FEATURE=db-migrations"

# Containers
[ -f "$REPO_ROOT/Dockerfile" ] || [ -f "$REPO_ROOT/docker-compose.yml" ] || [ -f "$REPO_ROOT/docker-compose.yaml" ] && echo "FEATURE=docker"

# CI/CD
[ -d "$REPO_ROOT/.github/workflows" ] && echo "CI=github-actions"
[ -f "$REPO_ROOT/.gitlab-ci.yml" ] && echo "CI=gitlab-ci"
[ -f "$REPO_ROOT/Jenkinsfile" ] && echo "CI=jenkins"
[ -f "$REPO_ROOT/.circleci/config.yml" ] && echo "CI=circleci"

# Monorepo
[ -f "$REPO_ROOT/nx.json" ] && echo "FEATURE=monorepo-nx"
[ -f "$REPO_ROOT/lerna.json" ] && echo "FEATURE=monorepo-lerna"
[ -f "$REPO_ROOT/pnpm-workspace.yaml" ] && echo "FEATURE=monorepo-pnpm"
ls "$REPO_ROOT"/packages/ "$REPO_ROOT"/apps/ 2>/dev/null && echo "FEATURE=monorepo-dirs"

# Linter / Formatter configs
ls "$REPO_ROOT"/.eslintrc* "$REPO_ROOT"/eslint.config.* 2>/dev/null && echo "CONFIG=eslint"
ls "$REPO_ROOT"/.prettierrc* "$REPO_ROOT"/prettier.config.* 2>/dev/null && echo "CONFIG=prettier"
[ -f "$REPO_ROOT/ruff.toml" ] || grep -q "ruff" "$REPO_ROOT/pyproject.toml" 2>/dev/null && echo "CONFIG=ruff"
[ -f "$REPO_ROOT/.editorconfig" ] && echo "CONFIG=editorconfig"

# Environment config
[ -f "$REPO_ROOT/.env.example" ] || [ -f "$REPO_ROOT/.env.sample" ] && echo "FEATURE=env-config"
```

## 3. Test Framework Detection

```bash
# Node test frameworks
grep -q '"jest"' "$REPO_ROOT/package.json" 2>/dev/null && echo "TEST=jest"
grep -q '"vitest"' "$REPO_ROOT/package.json" 2>/dev/null && echo "TEST=vitest"
grep -q '"mocha"' "$REPO_ROOT/package.json" 2>/dev/null && echo "TEST=mocha"
grep -q '"cypress"' "$REPO_ROOT/package.json" 2>/dev/null && echo "TEST=cypress"
grep -q '"playwright"' "$REPO_ROOT/package.json" 2>/dev/null && echo "TEST=playwright"

# Python test frameworks
grep -rql "pytest" "$REPO_ROOT/pyproject.toml" "$REPO_ROOT/requirements.txt" "$REPO_ROOT/setup.cfg" 2>/dev/null && echo "TEST=pytest"

# Java test frameworks
grep -q "junit" "$REPO_ROOT/pom.xml" "$REPO_ROOT"/build.gradle* 2>/dev/null && echo "TEST=junit"
grep -q "testng" "$REPO_ROOT/pom.xml" "$REPO_ROOT"/build.gradle* 2>/dev/null && echo "TEST=testng"

# Go
[ -f "$REPO_ROOT/go.mod" ] && echo "TEST=go-test"

# Rust
[ -f "$REPO_ROOT/Cargo.toml" ] && echo "TEST=cargo-test"

# Ruby
grep -q "rspec" "$REPO_ROOT/Gemfile" 2>/dev/null && echo "TEST=rspec"
grep -q "minitest" "$REPO_ROOT/Gemfile" 2>/dev/null && echo "TEST=minitest"

# Test file location pattern
ls "$REPO_ROOT"/**/*.spec.* "$REPO_ROOT"/**/*.test.* 2>/dev/null | head -3 && echo "TEST_PATTERN=colocated"
[ -d "$REPO_ROOT/__tests__" ] || [ -d "$REPO_ROOT/tests" ] || [ -d "$REPO_ROOT/test" ] && echo "TEST_PATTERN=separate-dir"
ls "$REPO_ROOT"/**/test_*.py "$REPO_ROOT"/**/tests/ 2>/dev/null | head -3 && echo "TEST_PATTERN=python-convention"
```

## 4. Monorepo Handling

If monorepo indicators are detected, also list the packages/apps:

```bash
# List workspace packages
if [ -f "$REPO_ROOT/pnpm-workspace.yaml" ]; then
  cat "$REPO_ROOT/pnpm-workspace.yaml"
elif [ -f "$REPO_ROOT/package.json" ]; then
  node -e "const p=require('./package.json'); if(p.workspaces) console.log(JSON.stringify(p.workspaces))" 2>/dev/null
fi

# List top-level directories that look like packages
ls -d "$REPO_ROOT"/packages/*/ "$REPO_ROOT"/apps/*/ "$REPO_ROOT"/services/*/ "$REPO_ROOT"/libs/*/ 2>/dev/null
```

## Output Format

After running all detection, summarise results clearly:

```
=== Project Detection Results ===
Stack:      <stack>
Framework:  <framework>
Language:   <typescript|javascript|python|java|go|rust|ruby>
Features:   <comma-separated list>
CI:         <github-actions|gitlab-ci|jenkins|circleci|none>
Tests:      <comma-separated test frameworks>
Test files: <colocated|separate-dir|python-convention|unknown>
Monorepo:   <yes (tool)|no>
Configs:    <comma-separated linter/formatter configs>
```

If detection is uncertain for any field, report `unknown` — never guess.
