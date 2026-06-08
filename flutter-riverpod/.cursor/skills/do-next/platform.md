# Platform context — do-next verification

Read before **2b Execute task** and slice-level verification.

## Verification

Replace placeholders per `ARCHITECTURE.md` and `AGENTS.md`:

```bash
# Native iOS example:
xcodebuild -scheme [AppScheme] -configuration Debug \
  -destination 'platform=iOS Simulator,name=[SimulatorName]' \
  test -only-testing:[TestBundle] 2>&1 | tail -40

# Android example:
./gradlew test

# Flutter example:
flutter test

# Generic:
npm test
```

## Read order

1. `ARCHITECTURE.md`
2. `.gsd/DELIVERY-PROFILE.md` — branch, commit cadence
3. Active `T##-PLAN.md`
