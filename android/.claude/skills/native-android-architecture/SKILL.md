---
name: native-android-architecture
description: >
  Generic architecture guidance for native Android projects. Use when
  implementing features, refactoring modules, adding services, wiring
  dependencies, or deciding file structure and data flow.
---

# Native Android Architecture

## When To Use

Use for new features, architectural refactors, dependency management, navigation work, persistence integration, or service-layer design.

## Recommended Structure

```
app/
feature/
core/
designsystem/
testing/
build-logic/
```

## Feature Module Pattern

Each feature should have a clear entry point and well-defined ownership for state, UI, domain logic, and side effects.

Suggested shape:

```
feature/feature-name/
  ui/
  domain/
  data/
  constants.kt
  dictionary.kt
  src/test/
```

## Design Guidance

- Keep side effects behind explicit interfaces
- Keep mapping and parsing logic out of UI code
- Prefer one authoritative owner for each piece of mutable state
- Centralize copy, identifiers, feature flags, and tunable thresholds
- Use composition to share behavior before introducing inheritance-heavy designs

## Testing Guidance

- Unit test domain logic and data mapping
- Integration test critical workflows and failure paths
- Mock boundaries, not internal implementation details

## Anti-Patterns

- Hidden global state or uncontrolled singletons
- UI layers owning too much business logic
- Networking or persistence logic spread across presentation files
- Magic strings, hardcoded thresholds, or duplicated copy contracts
