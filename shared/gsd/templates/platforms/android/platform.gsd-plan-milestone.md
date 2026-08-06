# Platform context — Native Android (gsd-plan-milestone)

## Context reads (in order)

1. `AGENTS.md`
2. `ARCHITECTURE.md`
3. `.gsd/DELIVERY-PROFILE.md`

## Verification (post-milestone)

```bash
./gradlew :[module]:testDebugUnitTest 2>&1 | tail -40
./gradlew :[module]:lintDebug 2>&1 | tail -20
```

## Grill hints

- Kotlin coroutines; MVVM / MVI boundaries
- Hilt / Dagger DI graph; module boundaries
- Compose vs XML layout conventions
- See `ARCHITECTURE.md` for navigation and DI patterns
