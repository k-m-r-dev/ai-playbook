# Platform context — Native iOS

Read **before** Phase 0 orient and during grill codebase search.

## Read order (repo root)

1. `AGENTS.md` — agent policy, `xcodebuild` commands, layout heuristics
2. `ARCHITECTURE.md` — app shell, navigation, DI, data layer, feature checklist
3. `SESSION_WORKFLOW.md` — session lifecycle (symlinked from ai-playbook when installed)
4. `.workflow/progress_tracker.md` — sprint, backlog, shipped work

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

## Architecture skills (planning context only)

- `.claude/skills/ios-architecture/SKILL.md`
- `.claude/skills/native-ios-architecture/SKILL.md`

Do not duplicate layer rules here — cite `ARCHITECTURE.md` and existing feature patterns during grill.

## Verification (post-milestone / handoff — not during grill)

From app root (replace placeholders per `AGENTS.md`):

```bash
xcodebuild -scheme [AppScheme] -configuration Debug \
  -destination 'platform=iOS Simulator,name=[SimulatorName]' \
  test -only-testing:[TestBundle] 2>&1 | tail -40
```

## Grill hints

- Swift structured concurrency; protocol boundaries for services/repos
- Copy: `dictionary.swift`; constants: `constants.swift` per feature
- App shell / tab navigation patterns in `ARCHITECTURE.md`
- Permissions, Keychain, and network timeouts as explicit decisions
