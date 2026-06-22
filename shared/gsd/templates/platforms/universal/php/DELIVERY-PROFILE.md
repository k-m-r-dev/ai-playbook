# Project Delivery Profile

Record active delivery settings here. Agents read this **after** the abstract workflow files in `.gsd/workflow/`.

Defaults below target **PHP/Composer backend** projects.

## Active profile

| Field | Value |
| --- | --- |
| Integration strategy | `feature-branch` |
| Integration branch | `main` |
| Commit cadence | `slice` — one commit after each slice completes verification |
| Review unit | `pr-per-milestone` |
| Git/PR checkpoint mode | `milestone` (use `slice` only if team requires PR per slice) |
| Remote push | Explicit user approval before push / open PR |
| External tickets | Optional |

## Validation (this project)

```bash
composer test
composer lint
composer phpstan
```

## Notes

- Keep domain/business rules covered with deterministic PHPUnit tests.
- Prefer incremental PRs that keep schema migrations and app logic reviewable together.
