# Project Delivery Profile

Record active delivery settings here. Agents read this **after** the abstract workflow files in `.gsd/workflow/`.

Defaults below target **Node/JS/TS** projects.

## Active profile

| Field | Value |
| --- | --- |
| Integration strategy | `feature-branch` |
| Integration branch | `main` or `develop` |
| Commit cadence | `slice` — one commit after each slice completes verification |
| Review unit | `pr-per-milestone` |
| Git/PR checkpoint mode | `milestone` by default |
| Remote push | Explicit user approval before push / open PR |
| External tickets | Optional |

## Validation (this project)

```bash
npm test
npm run lint
npm run typecheck
```

## Notes

- Keep lint/typecheck/test green on every slice.
- For monorepos, narrow verification to touched app/package where possible.
