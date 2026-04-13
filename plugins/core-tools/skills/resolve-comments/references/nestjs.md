# Stack Module: TypeScript / NestJS

Governs Phase 2.3 (framework-specific guidance) and Phase 4 (verification)
for TypeScript projects using NestJS.

---

## Phase 2.3 — NestJS / TypeScript-Specific Guidance

Apply these principles when resolving comments in this codebase:

- **DI / Module wiring**: If a provider is added or moved, update the owning
  module's `providers`/`exports` array. Check barrel `index.ts` exports.
- **DTOs**: If a field is changed, update both the request DTO and any response
  DTO. Update `class-validator` decorators. Update Swagger `@ApiProperty`.
- **Services / Repositories**: Keep business logic in services. Repositories own
  DB interactions only. Do not leak Prisma/Mongoose types above the repository
  layer.
- **Prisma + MongoDB**: If a schema field is modified, update
  `prisma/schema.prisma`. For MongoDB, use `@db.ObjectId` on ID fields. Run
  `npx prisma generate` after any schema changes — this is mandatory before build.
- **Error handling**: Use NestJS `HttpException` subclasses or a custom exception
  filter. Do not swallow errors silently.
- **Kafka**: Producer and consumer decorators must match topic names exactly.
  Confirm dead-letter topic handling if removing retry logic.
- **Tests**: If changing a service method signature, update all affected mocks in
  spec files. Use `jest.spyOn` rather than manual mock reassignment where possible.

Finding related tests:
```bash
grep -r "describe\|it(" --include="*.spec.ts" -l
```

---

## Phase 4 — Verification

Run in this order. **Stop at the first failure** and fix before continuing.

### 4.1 Lint

```bash
npm run lint
# or: npx eslint "src/**/*.ts" --max-warnings=0
```

Fix any lint errors introduced by your changes. Do not suppress rules inline
unless the existing code already does so.

### 4.2 Type Check

```bash
npx tsc --noEmit
```

Resolve all type errors before proceeding.

### 4.3 Build

```bash
npm run build
```

A build failure typically means a broken import, missing export, or module
wiring issue.

### 4.4 Run Affected Tests

```bash
CHANGED_FILES=$(git diff --name-only HEAD)
for f in $CHANGED_FILES; do
  BASE=$(basename "$f" .ts)
  find . -name "*.spec.ts" | xargs grep -l "$BASE" 2>/dev/null
done | sort -u
```

Run targeted tests first:
```bash
npx jest --testPathPattern="<affected-spec-files>" --passWithNoTests
```

If all targeted tests pass, run the full suite:
```bash
npm test -- --passWithNoTests
```

---

## Stack-Specific Hard Rules

- If a comment requires a Prisma schema change, always run `npx prisma generate`
  before the build step
- If a comment touches a Kafka topic name or event payload shape, flag it
  explicitly in the commit message — these are breaking changes
- Never suppress a TypeScript error with `// @ts-ignore` to pass the type check;
  fix the underlying issue instead
