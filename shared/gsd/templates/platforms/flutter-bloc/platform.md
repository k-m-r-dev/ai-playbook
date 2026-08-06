# Platform context — Flutter + Bloc (do-next / gsd-advance-unit)

Customize package name and test targets from `AGENTS.md`.

## Verification

```bash
flutter test test/[test_file]_test.dart 2>&1 | tail -40
# full suite:
flutter test 2>&1 | tail -40
```

## Context reads (in order)

1. `AGENTS.md`
2. `ARCHITECTURE.md`
3. `.gsd/DELIVERY-PROFILE.md`
4. Active `T##-PLAN.md`
