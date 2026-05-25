# Platform context — Native Android

Read **before** implementation tasks and when planning slice tasks.

## Read order (repo root)

1. `AGENTS.md` — agent policy, Gradle commands, module heuristics
2. `ARCHITECTURE.md` — Clean Architecture + MVVM, Hilt, app shell, feature checklist (**required before code changes**)
3. `SESSION_WORKFLOW.md` — session lifecycle (symlinked from ai-playbook when installed)
4. `.workflow/progress_tracker.md` — sprint, backlog, shipped work
5. `.gsd/milestones/M###/M###-ROADMAP.md` and `M###-CONTEXT.md` for the active milestone

## Module layout (from template)

| Area | Typical path |
| --- | --- |
| App shell | `app/` |
| Features | `feature/` |
| Core / data / DI | `core/` |
| Design system | `designsystem/` or `ui/` |
| Shared tests | `testing/` |

Use **concrete paths** from the client `ARCHITECTURE.md` when placeholders like `[package]` are resolved.

## Architecture skills (implementation context)

- `.claude/skills/android-architecture/SKILL.md`
- `.claude/skills/native-android-architecture/SKILL.md`

Do not duplicate layer rules here — follow `ARCHITECTURE.md` and existing feature patterns.

## Verification (required before `gsd_task_complete`)

From app root:

```bash
./gradlew testDebugUnitTest
./gradlew lint
```

Per-module: `./gradlew :[module]:testDebugUnitTest`

## Execution hints

- Navigation: Jetpack Navigation Compose, nested tab graphs (`ARCHITECTURE.md` app shell section)
- State: `StateFlow` / ViewModel → Use Case → Repository
- DI: Hilt modules in `core/`; no new singletons without explicit decision
- Copy/constants: string resources, `constants.kt`, `dictionary.kt` per feature
- Match task PLAN file paths to ROADMAP slice goals; update `.workflow/progress_tracker.md` when shipped work completes
