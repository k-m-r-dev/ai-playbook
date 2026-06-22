# Platform context — universal/node (gsd-plan-milestone)

Plan milestones around package boundaries, shared contracts, and incremental rollout.

## Verification baseline

```bash
npm test
npm run lint
npm run typecheck
```

## Milestone hints

- Prefer vertical slices that cut across API + UI + tests.
- Keep dependency updates isolated from feature behavior changes.
