# Flutter Riverpod AI Development Template

Generic AI-first template for Flutter projects using Dart, Riverpod state management, and GetIt/Injectable dependency injection.

## Purpose

Provide durable, high-signal context so coding agents can plan, implement, and review Flutter Riverpod changes consistently.

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

## Riverpod Conventions

- App root must be wrapped by `ProviderScope`
- Use `ref.watch` for reactive reads and `ref.read` for command actions
- Keep provider declarations close to feature ownership
- Prefer `AsyncValue` for loading/error/data state modeling

## Agent Workflow

- `@Planner`: produce a concrete plan with risks and test surfaces
- `@Coder`: implement small, reviewable changes
- `@Reviewer`: verify correctness, architecture fit, security, and test coverage

## Session & progress docs

Canonical playbook: **`SESSION_WORKFLOW.md`** (full process + templates). **Cursor** (`.cursor/rules/20-session-progress.mdc`), **Claude** (`session-progress-workflow` skill), and **Copilot** (`session-progress.instructions.md`) share the **same routing body**; only metadata differs (`globs` / skill frontmatter / `applyTo`). **Claude** also loads playbooks via **`CLAUDE.md`** (`@ARCHITECTURE.md`, `@SESSION_WORKFLOW.md`). Do not duplicate lifecycle or templates in those three—only in **`SESSION_WORKFLOW.md`** (`ai-playbook`).

For substantive work, follow that playbook: keep `.workflow/current_session_progress.md` updated during the session, archive to `.workflow/previous_session_progress.md` at handoff, and align `.workflow/progress_tracker.md` when tasks or schema change. **`.workflow/` is always copied** at overlay install (project-owned state). **`SESSION_WORKFLOW.md` uses the installer `--mode`** (typically **symlink** as `_AGENTS.md`; committed `AGENTS.md` wraps it with `@_AGENTS.md`); use **`--mode copy`** if your environment cannot resolve symlinks.

## Skills

| Skill | Path | Purpose |
| --- | --- | --- |
| flutter-architecture | `.claude/skills/flutter-architecture/SKILL.md` | High-level repository layout and dependency direction |
| flutter-riverpod-architecture | `.claude/skills/flutter-riverpod-architecture/SKILL.md` | Riverpod-specific feature and state ownership patterns |
| native-data-fetching | `.claude/skills/native-data-fetching/SKILL.md` | Networking, retries, caching, and error handling |
| security-and-privacy | `.claude/skills/security-and-privacy/SKILL.md` | Secrets, sensitive data, validation, and storage safety |
| flutter-platform-quality | `.claude/skills/flutter-platform-quality/SKILL.md` | Performance, accessibility, concurrency, and release quality |
| architecture-playbook | `.claude/skills/architecture-playbook/SKILL.md` | Thin routing to `ARCHITECTURE.md` (pairs with root `ARCHITECTURE.md`) |
| session-progress-workflow | `.claude/skills/session-progress-workflow/SKILL.md` | Session docs, handoff rhythm, `.workflow/*` (pairs with `SESSION_WORKFLOW.md`) |
| gsd-plan-milestone | `.cursor/skills/gsd-plan-milestone/SKILL.md` | Grill + ROADMAP via gsd-workflow MCP |
| gsd-advance-unit | `.cursor/skills/gsd-advance-unit/SKILL.md` | One pure GSD unit via MCP |
| do-next | `.cursor/skills/do-next/SKILL.md` | One unit; smoke + Task Handoff Gate + slice commits |
| do-next-runner | `.cursor/skills/do-next-runner/SKILL.md` | Auto-chain do-next units; smoke hard-stop |

**GSD prerequisite:** `.gsd/` must exist — run `bootstrap-gsd-workflow.sh --init-gsd --patch-mcp --with-do-next` before any GSD-family skill.
