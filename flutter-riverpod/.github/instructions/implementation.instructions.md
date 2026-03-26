---
applyTo: "**"
excludeAgent: ["Reviewer"]
---

# Flutter Riverpod Implementation Instructions

## Mission

Build maintainable Flutter software with clear architecture, safe defaults, and reviewable changes.

## Architecture Rules

- Read `ARCHITECTURE.md` before implementing any feature, refactor, or structural change
- Keep app shell, feature logic, shared services, and design system concerns separate
- Prefer explicit boundaries between UI, domain, and data access

## Quality Requirements

- Run tests after every implementation change. A change is not done until tests pass.
  - `flutter analyze`
  - `flutter test`
- Add or update tests for changed behavior
- Avoid broad refactors unless necessary
