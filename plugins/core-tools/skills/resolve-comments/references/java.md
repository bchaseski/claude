# Stack Module: Java

Governs Phase 2.3 (framework-specific guidance) and Phase 4 (verification)
for Java projects (Maven or Gradle).

---

## Phase 2.3 — Java-Specific Guidance

Apply these principles when resolving comments in this codebase:

- **Spring Boot / DI**: If a bean is added, moved, or renamed, check `@Component`,
  `@Service`, `@Repository`, `@Bean` annotations and confirm the bean is
  discoverable via component scanning. Check `@Autowired` / constructor injection
  call sites.
- **DTOs / Records**: If a field changes on a DTO or Java Record, update all
  constructors, builders (`@Builder`), mappers (MapStruct), and any Jackson
  `@JsonProperty` annotations. Update OpenAPI / Swagger `@Schema` annotations.
- **JPA / Hibernate**: If an entity field is modified, check whether a Flyway or
  Liquibase migration is needed. Do not alter `@Entity` mappings without a
  corresponding migration. Confirm `@Column` constraints match DB constraints.
- **Error handling**: Use `@ControllerAdvice` / `@ExceptionHandler` patterns.
  Do not swallow exceptions in catch blocks — at minimum log and rethrow.
- **Interfaces vs implementations**: Prefer injecting the interface, not the
  concrete class. If an interface method signature changes, update all
  implementations.
- **Null safety**: Prefer `Optional<T>` over returning `null`. If a comment
  asks for null checks, add `@NonNull` / `@Nullable` annotations where applicable.

Finding related tests:
```bash
find . -name "*Test.java" -o -name "*Tests.java" -o -name "*Spec.java" | head -20
grep -r "class.*Test" --include="*.java" -l
```

---

## Phase 4 — Verification

Detect build tool first:

```bash
[ -f "pom.xml" ]                                        && BUILD="mvn"
[ -f "build.gradle" ] || [ -f "build.gradle.kts" ]     && BUILD="./gradlew"
```

Run in this order. **Stop at the first failure** and fix before continuing.

### 4.1 Compile

```bash
# Maven
mvn compile -q

# Gradle
./gradlew compileJava compileTestJava
```

A compile failure must be fixed before anything else.

### 4.2 Static Analysis / Checkstyle

```bash
# Maven (if Checkstyle plugin configured)
mvn checkstyle:check -q

# Maven (if SpotBugs / PMD configured)
mvn spotbugs:check pmd:check -q

# Gradle
./gradlew checkstyleMain checkstyleTest
./gradlew spotbugsMain
```

Skip silently if the project has no static analysis plugins configured.

### 4.3 Run Affected Tests

```bash
CHANGED=$(git diff --name-only HEAD | grep "\.java$")
for f in $CHANGED; do
  CLASS=$(basename "$f" .java)
  find . -name "${CLASS}Test.java" -o -name "${CLASS}Tests.java" 2>/dev/null
done | sort -u
```

Run targeted tests:
```bash
# Maven — run specific test class
mvn test -Dtest="<TestClassName>" -pl <module> -q

# Gradle
./gradlew test --tests "<fully.qualified.TestClassName>"
```

If targeted tests pass, run the full suite:
```bash
# Maven
mvn test -q

# Gradle
./gradlew test
```

### 4.4 Package (optional — run if CI does a full build)

```bash
mvn package -DskipTests -q
# or:
./gradlew assemble
```

---

## Stack-Specific Hard Rules

- If a comment requires a JPA entity change, always generate and review a
  Flyway/Liquibase migration before committing — never rely on
  `spring.jpa.hibernate.ddl-auto=update` in non-dev environments
- If a comment touches a public API method signature (REST endpoint, interface
  method used across modules), flag it in the commit message as a potential
  breaking change
- Never suppress a compiler warning with `@SuppressWarnings` to pass the build;
  fix the underlying issue unless suppression already exists in the surrounding code
