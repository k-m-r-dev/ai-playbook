# Platform context — Flutter Riverpod

Read **before** Phase 0 orient and during grill codebase search.

## Read order (repo root)

1. `AGENTS.md` — agent policy, `flutter` commands, Riverpod conventions
2. `ARCHITECTURE.md` — Clean Architecture + Riverpod, feature layout, verification
3. `SESSION_WORKFLOW.md` — session lifecycle (symlinked from ai-playbook when installed)
4. `.workflow/progress_tracker.md` — sprint, backlog, shipped work

## Module layout (from template)

| Area | Typical path |
| --- | --- |
| App / routing | `lib/app/` |
| Core / DI / network | `lib/core/` |
| Features | `lib/features/<feature>/` (`view/`, `state/`, `domain/`, `data/`) |
| Design system | `lib/design_system/` |
| Tests | `test/` |

## Architecture skills (planning context only)

- `.claude/skills/flutter-architecture/SKILL.md`
- `.claude/skills/flutter-riverpod-architecture/SKILL.md`

Do not duplicate layer rules here — cite `ARCHITECTURE.md` and existing feature patterns during grill.

## Verification (post-milestone / handoff — not during grill)

From Flutter app root:

```bash
flutter analyze
flutter test
```

## Grill hints

- Root wrapped in `ProviderScope`; `ref.watch` vs `ref.read` ownership
- `AsyncValue` for loading/error/data; side effects behind repositories/use cases
- Feature state under `lib/features/<feature>/state/` (providers/notifiers)
- GetIt/Injectable wiring in `lib/core/` when DI touches the feature
