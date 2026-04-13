# Stack Module: Python

Governs Phase 2.3 (framework-specific guidance) and Phase 4 (verification)
for Python projects.

---

## Phase 2.3 — Python-Specific Guidance

Apply these principles when resolving comments in this codebase:

- **Type hints**: If a function signature changes, update type hints throughout.
  Check `mypy` will still pass — do not widen types to `Any` to silence errors.
- **Pydantic models**: If a field is changed on a Pydantic model, update all
  validators, `model_config`, and any `.model_dump()` / `.model_validate()` call
  sites. Check for `@field_validator` decorators that reference the field name.
- **Dependency injection (FastAPI)**: If a dependency signature changes, verify
  all routes that `Depends()` on it. Check for transitive dependencies.
- **ORM (SQLAlchemy / Django ORM)**: If a model field is modified, check whether
  a migration is needed. Do not modify the schema without a migration file.
  For Alembic: `alembic revision --autogenerate -m "describe change"` and review
  the generated migration before committing.
- **Error handling**: Raise specific exception types — do not use bare `except:`
  or swallow exceptions with `pass`. Use appropriate HTTP status codes in FastAPI
  (`HTTPException(status_code=...)`).
- **Imports**: Keep stdlib, third-party, and local imports separated (isort
  convention). Do not use wildcard imports (`from module import *`).

Finding related tests:
```bash
grep -r "def test_" --include="*.py" -l
# or for pytest discovery:
find . -name "test_*.py" -o -name "*_test.py" | head -20
```

---

## Phase 4 — Verification

Detect the package manager and tool config first:

```bash
# Package manager
[ -f "poetry.lock" ]   && PM="poetry run" || PM=""
[ -f "Pipfile.lock" ]  && PM="pipenv run"

# Tool runner
[ -f "pyproject.toml" ] && grep -q "\[tool.ruff\]" pyproject.toml && LINTER="ruff"
[ -f ".flake8" ] || grep -q "\[flake8\]" setup.cfg 2>/dev/null && LINTER="flake8"
[ -f ".pylintrc" ] && LINTER="pylint"
```

Run in this order. **Stop at the first failure** and fix before continuing.

### 4.1 Lint / Format

```bash
# Ruff (preferred modern linter)
$PM ruff check .
$PM ruff format --check .

# Flake8 (fallback)
$PM flake8 .

# Black (format check)
$PM black --check .
```

### 4.2 Type Check

```bash
$PM mypy .
# or: $PM mypy src/
```

Only skip if the project has no `mypy.ini` / `[tool.mypy]` config and no
existing type annotations — note this in the summary if skipped.

### 4.3 Run Affected Tests

```bash
# Find test files that reference changed modules
CHANGED=$(git diff --name-only HEAD | grep "\.py$")
for f in $CHANGED; do
  MODULE=$(basename "$f" .py)
  find . \( -name "test_*.py" -o -name "*_test.py" \) | xargs grep -l "$MODULE" 2>/dev/null
done | sort -u
```

Run targeted tests first:
```bash
$PM pytest <affected-test-files> -v
```

If targeted tests pass, run the full suite:
```bash
$PM pytest
```

---

## Stack-Specific Hard Rules

- Never use `# type: ignore` to silence mypy unless the existing codebase
  already uses it for that specific case; fix the underlying type issue instead
- If a comment requires a database model change, always generate and review a
  migration before committing
- If a comment touches a Pydantic model used in an API response, verify
  serialization behaviour hasn't changed by checking affected endpoint tests
