# AI-Native Completion Register

> This register is the source of truth for incremental modernization of SSU.
>
> A task is **not complete** merely because a new file exists or an isolated
> test passes. Completion requires a real production path:
>
> **REAL REQUEST → REAL ROUTE → APPLICATION COMPOSITION → NEW MODULE → REAL DEPENDENCY → REAL RESPONSE/EVENT**

## Status Legend

- `NOT_STARTED` — no implementation exists.
- `IN_PROGRESS` — implementation exists but the production path is incomplete.
- `INTEGRATED` — production code reaches the implementation.
- `VALIDATED` — integrated and covered by executed validation.
- `BLOCKED` — cannot safely continue without a prerequisite.

## Current Migration Register

| ID | Priority | Domain | Weakness / Objective | Status | Evidence / Next Action |
|---|---|---|---|---|---|
| AUTH-001 | P1 | Authentication | Extract authentication behind a modular service boundary | IN_PROGRESS | `features/auth/auth_service.dart` exists; prove production bootstrap reaches it |
| AUTH-002 | P1 | Authentication | Create explicit route cutover boundary | IN_PROGRESS | `auth_cutover.dart`, `legacy_auth_cutover.dart` exist; integrate into running server |
| AUTH-003 | P1 | Authentication | Ensure legacy server can delegate auth without duplicate DB lifecycle | IN_PROGRESS | `LegacyAuthCutover` reuses `DatabaseService`; verify actual server composition |
| APP-001 | P1 | Application | Establish modular application composition root | IN_PROGRESS | `AppRouter`, `ServerMigration`, and `server_handler.dart` exist; wire into bootstrap |
| APP-002 | P1 | Application | Prevent unintegrated architecture from being called complete | VALIDATED | This register defines the production-path completion rule |
| EVENT-001 | P1 | Platform | Establish event bus foundation | IN_PROGRESS | Event bus exists; connect real domain events and verify consumers |
| RUNTIME-001 | P1 | Platform | Establish server lifecycle ownership | IN_PROGRESS | Lifecycle abstraction exists; connect startup/shutdown ownership |
| TEST-001 | P1 | Quality | Add contract tests for extracted authentication boundaries | IN_PROGRESS | Tests exist; execute full suite and fix integration failures |
| OBS-001 | P2 | Operations | Establish structured observability for migration boundaries | NOT_STARTED | Add request/event correlation and structured error reporting |
| DATA-001 | P1 | Data | Audit database access for transactions, indexes, unbounded reads, and race conditions | NOT_STARTED | Perform repository-wide database audit before further extraction |
| SEC-001 | P0 | Security | Perform adversarial authentication and authorization audit | NOT_STARTED | Audit token/session/password/reset/privilege paths |
| AI-001 | P1 | AI Platform | Define real AI orchestration boundary based on actual school workflows | NOT_STARTED | Do not build speculative agent layers before domain event/task use cases exist |

## Completion Rules

A migration item may move to `INTEGRATED` only when:

1. A real application entry point reaches the new implementation.
2. The old competing production path is no longer selected for that scope.
3. Existing dependencies are reused or intentionally replaced.
4. Error behavior and compatibility are understood.
5. The relevant tests exist.

A migration item may move to `VALIDATED` only when:

1. Formatting succeeds.
2. Static analysis succeeds or known failures are documented.
3. Relevant tests are executed.
4. The production composition path is tested.
5. The diff has been reviewed for duplicate behavior and regressions.

## Current Highest-Value Next Actions

### 1. Complete the authentication production cutover

The extracted authentication code must be proven to sit on the actual request
path of the running server. Do not mark this complete based on isolated route
tests.

Required chain:

```text
HTTP request
    ↓
server bootstrap
    ↓
production handler
    ↓
ServerMigration
    ↓
AuthFirstMigrationHandler
    ↓
LegacyAuthCutover
    ↓
AuthRouteCutover
    ↓
AuthService
    ↓
DatabaseService / email / session state
    ↓
HTTP response or domain event
```

### 2. Verify the existing route contract before deleting legacy handlers

Before removing legacy authentication handlers:

- enumerate the actual legacy authentication paths;
- compare methods and path names with the extracted routes;
- compare response status codes and response shapes;
- compare authentication/session behavior;
- identify any route that is missing from the extracted module;
- add compatibility adapters where necessary.

### 3. Execute validation

The next implementation cycle must run the actual project validation commands
available in the repository. Do not report tests as executed unless the command
was actually run and its result is known.

## Architectural Guardrails

- Do not create a second database connection for a migrated feature.
- Do not create a second authentication system without an explicit migration plan.
- Do not create an event bus that has no real domain event producer or consumer.
- Do not create AI agents that directly mutate critical data without permission,
  validation, auditability, and human-approval rules where required.
- Do not remove legacy code until replacement behavior is proven on the real
  production path.
- Prefer reversible migration boundaries over large rewrites.
- Every new abstraction must have a real caller.
- Every claimed migration must identify its production entry point.

## Next Register Update

After the next implementation cycle, update this file with:

- exact files changed;
- actual validation commands executed;
- actual pass/fail results;
- newly discovered weaknesses;
- status changes supported by evidence.
