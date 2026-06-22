# Platform context — universal/php (gsd-plan-milestone)

Plan milestones around service boundaries, integration points, and data schema safety.

## Verification baseline

```bash
composer test
composer lint
composer phpstan
```

## Milestone hints

- Include rollback strategy for DB/data migrations.
- Split large domain changes into reviewable slices.
