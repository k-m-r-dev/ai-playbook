---
name: flutter-architecture
description: >
  High-level architecture guidance for Flutter repositories. Use when planning
  module layout, boundaries, dependency direction, migration strategy, or
  feature shape before implementation details are chosen.
---

# Flutter Architecture

## When To Use

Use before implementing features or refactors that affect repository structure, module boundaries, or dependency direction.

## Focus Areas

- Keep app wiring, feature modules, shared services, and design system concerns clearly separated
- Prefer stable dependency direction from app shell toward features and shared services
- Keep planning output explicit about files, risks, and migration scope
