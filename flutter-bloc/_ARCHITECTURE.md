# [App Name] - Clean Architecture + BLoC

This document describes how Clean Architecture and BLoC/Cubit work together in this Flutter app.

## Flow of control

```text
Widget -> Bloc/Cubit -> Use Case -> Repository -> Data Source
```

## Layout

- `lib/app/`: app startup, global routing, app shell
- `lib/core/`: DI, networking, persistence, shared services, constants
- `lib/features/<feature>/`: `view/`, `state/`, `domain/`, `data/`
- `lib/design_system/`: tokens, reusable components, themes
- `test/`: unit/widget/integration tests

## BLoC architecture rules

- Scope blocs/cubits by feature using `BlocProvider`/`MultiBlocProvider`
- Keep side effects behind repositories and use cases
- Keep event handling and state transitions inside bloc/cubit classes
- Use `BlocBuilder` for UI rendering and `BlocListener` for one-off side effects

## Build and verification after changes

- Run analysis and tests after every change before considering work done.

```bash
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --debug --no-codesign
```
