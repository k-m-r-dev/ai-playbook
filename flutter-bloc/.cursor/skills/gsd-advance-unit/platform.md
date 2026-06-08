# Platform context — Native iOS

Read **before** implementation tasks and when planning slice tasks.

## Read order (repo root)

1. `AGENTS.md` — agent policy, `xcodebuild` commands, layout heuristics
2. `ARCHITECTURE.md` — app shell, navigation, DI, data layer, feature checklist (**required before code changes**)
3. `SESSION_WORKFLOW.md` — session lifecycle (symlinked from ai-playbook when installed)
4. `.workflow/progress_tracker.md` — sprint, backlog, shipped work
5. `.gsd/milestones/M###/M###-ROADMAP.md` and `M###-CONTEXT.md` for the active milestone

## Module layout (from template)

| Area | Typical path |
| --- | --- |
| App composition | `App/` |
| Features | `Features/` |
| Core services | `Core/` |
| Design system | `DesignSystem/` |
| Shared tests | `Testing/` |
| Automation | `Scripts/` |

Use **concrete paths** from the client `ARCHITECTURE.md` when placeholders are resolved.

## Architecture skills (implementation context)

- `.claude/skills/ios-architecture/SKILL.md`
- `.claude/skills/native-ios-architecture/SKILL.md`

Do not duplicate layer rules here — follow `ARCHITECTURE.md` and existing feature patterns.

## Verification (required before `gsd_task_complete`)

From app root (replace placeholders per `AGENTS.md`):

```bash
xcodebuild -scheme [AppScheme] -configuration Debug \
  -destination 'platform=iOS Simulator,name=[SimulatorName]' \
  test -only-testing:[TestBundle] 2>&1 | tail -40
```

## Execution hints

- Swift structured concurrency; protocol boundaries for services/repos
- Copy: `dictionary.swift`; constants: `constants.swift` per feature
- App shell / tab navigation patterns in `ARCHITECTURE.md`
- Permissions, Keychain, and network timeouts as explicit decisions
- Match task PLAN file paths to ROADMAP slice goals; update `.workflow/progress_tracker.md` when shipped work completes
