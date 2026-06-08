# Project Delivery Profile

Record active delivery settings here. Agents read this **after** the abstract workflow files in `.gsd/workflow/`.

Customize this file after bootstrap — defaults suit **feature-branch + PR per milestone** repos.

## Active profile

| Field | Value |
| --- | --- |
| Integration strategy | `feature-branch` |
| Integration branch | `main` or `develop` |
| Commit cadence | `slice` — one commit after each slice completes verification |
| Review unit | `pr-per-milestone` |
| Remote push | Explicit user approval before push / open PR |
| External tickets | Optional — set to JIRA/Linear ID if required |

## Validation (this project)

See skill `platform.md` files and `AGENTS.md`. Typical monorepo / Node:

```bash
yarn test
yarn lint
```

## Notes

- Task Handoff Gate applies for `do next`: pause between tasks when commit cadence is `slice`.
- Do not use local planning IDs (`M###`, `S##`) in public PR titles unless the team agrees.
