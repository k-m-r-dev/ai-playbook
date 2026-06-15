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
| Git/PR checkpoint mode | `milestone` by default; set `slice` for PR-per-slice workflows, `none` for no remote workflow |
| Remote push | Explicit user approval before push / open PR |
| External tickets | Optional — set to JIRA/Linear ID if required |

## Validation (this project)

See skill `platform.md` files and `AGENTS.md`. Typical monorepo / Node:

```bash
yarn test
yarn lint
```

When bootstrap detects Prettier support in a universal JS repo, it appends an auto-managed validation block in this file between:

- `<!-- BEGIN AUTO:PRETTIER-VALIDATION -->`
- `<!-- END AUTO:PRETTIER-VALIDATION -->`

That block may be refreshed on future bootstrap runs.

## Notes

- Task Handoff Gate applies for `do next`: pause between tasks when commit cadence is `slice`.
- do-next/do-next-runner must still ask for explicit stage confirmations before push/PR.
- Do not use local planning IDs (`M###`, `S##`) in public PR titles unless the team agrees.
