# Platform context — Native iOS (do-next / gsd-advance-unit)

Customize scheme and simulator from `AGENTS.md`.

## Verification

```bash
xcodebuild -scheme [AppScheme] -configuration Debug \
  -destination 'platform=iOS Simulator,name=[SimulatorName]' \
  test -only-testing:[TestBundle] 2>&1 | tail -40
```

## Read order

1. `AGENTS.md`
2. `ARCHITECTURE.md`
3. `.gsd/DELIVERY-PROFILE.md`
4. Active `T##-PLAN.md`
