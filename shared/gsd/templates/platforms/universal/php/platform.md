# Platform context — universal/php (do-next / gsd-advance-unit)

Customize after bootstrap. Commands should match `AGENTS.md` and composer scripts.

## Verification

```bash
composer test
composer lint
composer phpstan
```

## Read order

1. `AGENTS.md`
2. `.gsd/DELIVERY-PROFILE.md`
3. `ARCHITECTURE.md` (if present)
4. Active `T##-PLAN.md`
