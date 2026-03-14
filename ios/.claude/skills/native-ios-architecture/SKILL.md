---
name: native-ios-architecture
description: >
  Generic architecture guidance for native iOS projects. Use when implementing
  features, refactoring modules, adding services, wiring dependencies, or
  deciding file structure and data flow.
---

# Native iOS Architecture

## When To Use

Use for new features, architectural refactors, dependency management, navigation flow work, persistence integration, or service-layer design.

## Recommended Structure

```
App/
Features/
Core/
DesignSystem/
Testing/
Scripts/
```

## Feature Module Pattern

Each feature should have a clear entry point and well-defined ownership for state, UI, domain logic, and side effects.

Suggested shape:

```
Features/FeatureName/
  Views/
  ViewModels/
  Domain/
  Data/
  dictionary.swift
  constants.swift
  Tests/
```

## Design Guidance

- Keep side effects behind explicit interfaces
- Keep mapping and parsing logic out of views
- Prefer one authoritative owner for each piece of mutable state
- Centralize copy, identifiers, feature flags, and tunable thresholds
- Use composition to share behavior before introducing inheritance-heavy designs

## Testing Guidance

- Unit test domain logic and data mapping
- Integration test critical workflows and failure paths
- Mock boundaries, not internal implementation details

## Anti-Patterns

- Hidden global state
- View controllers or views owning too much business logic
- Networking or persistence logic spread across UI files
- Magic strings, hardcoded thresholds, or copy duplicated across files
