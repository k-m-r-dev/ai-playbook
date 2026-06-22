# Project Delivery Profile

Record active delivery settings here. Agents read this **after** the abstract workflow files in `.gsd/workflow/`.

Defaults below target **Python** projects.

## Active profile

| Field | Value |
| --- | --- |
| Integration strategy | `feature-branch` |
| Integration branch | `main` |
| Commit cadence | `slice` |
| Review unit | `pr-per-milestone` |
| Git/PR checkpoint mode | `milestone` |
| Remote push | Explicit user approval before push / open PR |
| External tickets | Optional |

## Validation (this project)

```bash
pytest
ruff check .
```

## Notes

- Keep deterministic unit tests alongside changed modules.
- Prefer incremental type/lint adoption if repository has mixed legacy code quality.
