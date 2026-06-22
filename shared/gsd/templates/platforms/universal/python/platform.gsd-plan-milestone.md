# Platform context — universal/python (gsd-plan-milestone)

Plan milestones around module boundaries, data contracts, and runtime safety.

## Verification baseline

```bash
pytest
ruff check .
```

## Milestone hints

- Keep migration/infra changes separate from behavioral feature changes where possible.
- Include benchmark or profiling checks when modifying performance-critical paths.
