# Platform context — Native Android (do-next / gsd-advance-unit)

Customize `buildVariant`, `module`, and test commands from `AGENTS.md`.

## Verification

```bash
./gradlew :[module]:testDebugUnitTest 2>&1 | tail -40
# or connected tests:
./gradlew :[module]:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=[TestClass]
```

## Context reads (in order)

1. `AGENTS.md`
2. `ARCHITECTURE.md`
3. `.gsd/DELIVERY-PROFILE.md`
4. Active `T##-PLAN.md`
