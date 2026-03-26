# Flutter BLoC AI Development Template

Generic AI-first template for Flutter projects using Dart, BLoC/Cubit state management, and GetIt/Injectable dependency injection.

## Purpose

Provide durable, high-signal context so coding agents can plan, implement, and review Flutter BLoC changes consistently.

## Architecture Document

The project's concrete architecture decisions live in `ARCHITECTURE.md`.

- Read `ARCHITECTURE.md` before planning or implementing any feature, refactor, or structural change.
- If a general principle in this file conflicts with a specific decision in `ARCHITECTURE.md`, the architecture document takes precedence.

## Commands

Run from the Flutter app root:

```bash
flutter pub get
flutter analyze
flutter test
flutter test --coverage
flutter build apk --debug
flutter build ios --debug --no-codesign
```

## BLoC Conventions

- Provide feature state owners via `BlocProvider`/`MultiBlocProvider`
- Keep events/intents explicit and side effects in bloc/cubit methods
- Keep UI subscriptions explicit with `BlocBuilder` and side effects with `BlocListener`
- Model loading/error/success states explicitly in state classes

## Agent Workflow

- `@Planner`: produce a concrete plan with risks and test surfaces
- `@Coder`: implement small, reviewable changes
- `@Reviewer`: verify correctness, architecture fit, security, and test coverage

## Skills

| Skill | Path | Purpose |
| --- | --- | --- |
| flutter-architecture | `.claude/skills/flutter-architecture/SKILL.md` | High-level repository layout and dependency direction |
| flutter-bloc-architecture | `.claude/skills/flutter-bloc-architecture/SKILL.md` | BLoC-specific feature and state ownership patterns |
| native-data-fetching | `.claude/skills/native-data-fetching/SKILL.md` | Networking, retries, caching, and error handling |
| security-and-privacy | `.claude/skills/security-and-privacy/SKILL.md` | Secrets, sensitive data, validation, and storage safety |
| flutter-platform-quality | `.claude/skills/flutter-platform-quality/SKILL.md` | Performance, accessibility, concurrency, and release quality |
