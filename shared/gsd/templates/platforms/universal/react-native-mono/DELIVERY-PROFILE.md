# Project Delivery Profile

Record active delivery settings here. Agents read this **after** the abstract workflow files in `.gsd/workflow/`.

Defaults below target **React Native monorepo** projects.

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
# Replace <mobile-app> with your app package
cd apps/<mobile-app>
yarn test
yarn lint
```

## Notes

- Keep shared package changes coordinated with mobile app consumers.
- Validate critical app flows on at least one platform emulator/device before merge.
