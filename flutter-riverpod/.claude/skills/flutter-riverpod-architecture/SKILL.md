---
name: flutter-riverpod-architecture
description: >
  Riverpod-specific architecture guidance for Flutter projects. Use when
  implementing providers, notifiers, state ownership, and feature-level
  architecture in Riverpod codebases.
---

# Flutter Riverpod Architecture

## When To Use

Use for new features, provider/state refactors, dependency management, and async state modeling with Riverpod.

## Guidance

- Wrap app root with `ProviderScope`
- Keep providers feature-scoped and composable
- Use `ref.watch` for reactive reads and `ref.read` for one-off commands
- Keep side effects behind repositories and use cases
- Prefer `AsyncValue` to represent loading, data, and error states
