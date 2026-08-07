# Platform context — universal (gsd-plan-milestone)

Customize after bootstrap. Used during grill and formalize phases.

## Read order

1. `AGENTS.md` — build/test commands, layout
2. `ARCHITECTURE.md` — module map (if present)
3. `.gsd/DELIVERY-PROFILE.md` — branch and PR strategy

## Verification (post-milestone — not during grill)

```bash
yarn test
yarn lint
```

## Grill hints

- Cite existing patterns from `AGENTS.md` and `ARCHITECTURE.md`
- Record branch strategy and ticket IDs in DELIVERY-PROFILE during formalize
