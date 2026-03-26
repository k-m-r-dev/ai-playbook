---
name: flutter-bloc-architecture
description: >
  BLoC-specific architecture guidance for Flutter projects. Use when
  implementing blocs/cubits, state ownership, and feature-level
  architecture in BLoC codebases.
---

# Flutter BLoC Architecture

## When To Use

Use for new features, bloc/cubit state refactors, dependency management, and async state modeling with BLoC.

## Guidance

- Scope blocs/cubits by feature with `BlocProvider`/`MultiBlocProvider`
- Keep events/intents explicit and transitions contained in bloc/cubit classes
- Use `BlocBuilder` for UI rendering and `BlocListener` for side effects
- Keep side effects behind repositories and use cases
- Represent loading, success, and error explicitly in bloc/cubit state classes
