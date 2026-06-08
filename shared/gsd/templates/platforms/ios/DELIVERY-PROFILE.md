# Project Delivery Profile

Record active delivery settings here. Agents read this **after** the abstract workflow files in `.gsd/workflow/`.

Defaults suit **trunk-direct** native iOS repos — customize per project.

## Active profile

| Field | Value |
| --- | --- |
| Integration strategy | `trunk-direct` |
| Integration branch | `develop` or `main` |
| Commit cadence | `slice` — one commit after each slice completes verification |
| Review unit | `none` — direct commits unless profile changes |
| Remote push | Explicit user approval before push |
| External tickets | Optional |

## Validation (this project)

```bash
xcodebuild -scheme [AppScheme] -configuration Debug \
  -destination 'platform=iOS Simulator,name=[SimulatorName]' \
  test 2>&1 | tail -40
```

Replace scheme and simulator from `AGENTS.md` / `platform.md`.

## Notes

- Task Handoff Gate applies for `do next`.
- Do not create feature branches unless this profile changes.
