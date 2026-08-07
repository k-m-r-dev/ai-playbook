# Platform context — universal (do-next / gsd-advance-unit)

Customize after bootstrap. Verification commands should match `AGENTS.md`.

## Verification

```bash
# Monorepo / Node (default)
yarn test
yarn lint

# Single package
cd apps/<app> && yarn test

# Generic fallback
npm test
```

## Read order

1. `AGENTS.md`
2. `.gsd/DELIVERY-PROFILE.md`
3. `ARCHITECTURE.md` (if present)
4. Active `T##-PLAN.md`
