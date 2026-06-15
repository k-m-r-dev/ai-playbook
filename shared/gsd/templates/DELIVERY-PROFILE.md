# Project Delivery Profile

Record active delivery settings here. Agents read this **after** the abstract workflow files in `.gsd/workflow/`.

## Active profile

| Field | Value |
| --- | --- |
| Integration strategy | `trunk-direct` |
| Integration branch | `main` |
| Commit cadence | `slice` — one commit after each slice completes verification |
| Review unit | `none` |
| Git/PR checkpoint mode | `none` \| `slice` \| `milestone` (default used by do-next handshake; still confirm each checkpoint) |
| Remote push | Explicit user approval before push |
| External tickets | Optional |

## Milestone overrides

Add per-milestone tables when active (slice order, scope slugs, LOC budget).

## Validation (this project)

See platform skill `platform.md` or `ARCHITECTURE.md` for verify commands. Example:

```bash
# Replace with project-specific command from platform.md
npm test
```

## Notes

- Task Handoff Gate applies for `do next`: pause between tasks when commit cadence is `slice`.
- `Git/PR checkpoint mode` guides do-next defaults only; user confirmation is still required before push/PR stages.
- Do not create feature branches unless this profile changes.
