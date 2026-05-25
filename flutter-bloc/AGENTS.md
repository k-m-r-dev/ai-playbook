# Flutter BLoC AI Development Template

Generic AI-first template for Flutter projects using Dart, BLoC/Cubit state management, and GetIt/Injectable dependency injection.

## Purpose

Provide durable, high-signal context so coding agents can plan, implement, and review Flutter BLoC changes consistently.

## Architecture Document

The project's concrete architecture decisions live in `ARCHITECTURE.md`.

- Read `ARCHITECTURE.md` before planning or implementing any feature, refactor, or structural change.
- If a general principle in this file conflicts with a specific decision in `ARCHITECTURE.md`, the architecture document takes precedence.
- **Cursor** (`.cursor/rules/15-architecture.mdc`), **Claude** (`architecture-playbook` skill), and **Copilot** (`architecture.instructions.md`) share the **same routing body** for reading **`ARCHITECTURE.md`** first; only metadata differs (`globs` / skill frontmatter / `applyTo`). **Claude** also loads it via **`CLAUDE.md`** (`@ARCHITECTURE.md`). Do not duplicate layer or module rules in those three—only in **`ARCHITECTURE.md`**.

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

## Session & progress docs

Canonical playbook: **`SESSION_WORKFLOW.md`** (full process + templates). **Cursor** (`.cursor/rules/20-session-progress.mdc`), **Claude** (`session-progress-workflow` skill), and **Copilot** (`session-progress.instructions.md`) share the **same routing body**; only metadata differs (`globs` / skill frontmatter / `applyTo`). **Claude** also loads playbooks via **`CLAUDE.md`** (`@ARCHITECTURE.md`, `@SESSION_WORKFLOW.md`). Do not duplicate lifecycle or templates in those three—only in **`SESSION_WORKFLOW.md`** (`ai-playbook`).

For substantive work, follow that playbook: keep `.workflow/current_session_progress.md` updated during the session, archive to `.workflow/previous_session_progress.md` at handoff, and align `.workflow/progress_tracker.md` when tasks or schema change. **`.workflow/` is always copied** at overlay install (project-owned state). **`SESSION_WORKFLOW.md` uses the installer `--mode`** (typically **symlink** next to `AGENTS.md`); use **`--mode copy`** if your environment cannot resolve symlinks.

## Skills

| Skill | Path | Purpose |
| --- | --- | --- |
| flutter-architecture | `.claude/skills/flutter-architecture/SKILL.md` | High-level repository layout and dependency direction |
| flutter-bloc-architecture | `.claude/skills/flutter-bloc-architecture/SKILL.md` | BLoC-specific feature and state ownership patterns |
| native-data-fetching | `.claude/skills/native-data-fetching/SKILL.md` | Networking, retries, caching, and error handling |
| security-and-privacy | `.claude/skills/security-and-privacy/SKILL.md` | Secrets, sensitive data, validation, and storage safety |
| flutter-platform-quality | `.claude/skills/flutter-platform-quality/SKILL.md` | Performance, accessibility, concurrency, and release quality |
| architecture-playbook | `.claude/skills/architecture-playbook/SKILL.md` | Thin routing to `ARCHITECTURE.md` (pairs with root `ARCHITECTURE.md`) |
| session-progress-workflow | `.claude/skills/session-progress-workflow/SKILL.md` | Session docs, handoff rhythm, `.workflow/*` (pairs with `SESSION_WORKFLOW.md`) |
| gsd-pi-cursor | `.cursor/skills/gsd-pi-cursor/SKILL.md` | Grill + milestone plan in Cursor via gsd-workflow MCP |
| gsd-next-cursor | `.cursor/skills/gsd-next-cursor/SKILL.md` | Advance one GSD unit in Cursor (plan slice / execute task) via gsd-workflow MCP; Cursor billing only |
