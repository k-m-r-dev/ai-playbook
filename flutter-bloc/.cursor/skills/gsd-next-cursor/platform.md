# Platform context — Flutter BLoC

Read **before** implementation tasks and when planning slice tasks.

## Read order (repo root)

1. `AGENTS.md` — agent policy, `flutter` commands, BLoC conventions
2. `ARCHITECTURE.md` — Clean Architecture + BLoC, feature layout, verification (**required before code changes**)
3. `SESSION_WORKFLOW.md` — session lifecycle (symlinked from ai-playbook when installed)
4. `.workflow/progress_tracker.md` — sprint, backlog, shipped work
5. `.gsd/milestones/M###/M###-ROADMAP.md` and `M###-CONTEXT.md` for the active milestone

## Module layout (from template)

| Area | Typical path |
| --- | --- |
| App / routing | `lib/app/` |
| Core / DI / network | `lib/core/` |
| Features | `lib/features/<feature>/` (`view/`, `bloc/` or `cubit/`, `domain/`, `data/`) |
| Design system | `lib/design_system/` |
| Tests | `test/` |

## Architecture skills (implementation context)

- `.claude/skills/flutter-architecture/SKILL.md`
- `.claude/skills/flutter-bloc-architecture/SKILL.md`

Do not duplicate layer rules here — follow `ARCHITECTURE.md` and existing feature patterns.

## Verification (required before `gsd_task_complete`)

From Flutter app root:

```bash
flutter analyze
flutter test
```

## Execution hints

- `BlocProvider` / `MultiBlocProvider` scope per feature
- Explicit events/states; `BlocBuilder` vs `BlocListener` split
- Loading/error/success modeled in state classes (not ad hoc flags in widgets)
- GetIt/Injectable wiring in `lib/core/` when DI touches the feature
- Match task PLAN file paths to ROADMAP slice goals; update `.workflow/progress_tracker.md` when shipped work completes
