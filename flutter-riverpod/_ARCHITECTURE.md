# [App Name] - Clean Architecture + Riverpod

This document describes how Clean Architecture and Riverpod work together in this Flutter app.

## Flow of control

```text
Widget -> Provider/Notifier -> Use Case -> Repository -> Data Source
```

## Layout

- `lib/app/`: app startup, global routing, app shell
- `lib/core/`: DI, networking, persistence, shared services, constants
- `lib/features/<feature>/`: `view/`, `state/`, `domain/`, `data/`
- `lib/design_system/`: tokens, reusable components, themes
- `test/`: unit/widget/integration tests

## Riverpod architecture rules

- Root app is wrapped by `ProviderScope`
- Use `ref.watch` for reactive reads and `ref.read` for command-style actions
- Keep side effects behind repositories and use cases
- Prefer `AsyncValue` for loading/error/data states

## Build and verification after changes

- Run analysis and tests after every change before considering work done.

```bash
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --debug --no-codesign
```
