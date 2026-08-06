# Platform context — Flutter + Riverpod (gsd-plan-milestone)

## Context reads (in order)

1. `AGENTS.md`
2. `ARCHITECTURE.md`
3. `.gsd/DELIVERY-PROFILE.md`

## Verification (post-milestone)

```bash
flutter test 2>&1 | tail -40
flutter analyze 2>&1 | tail -20
```

## Grill hints

- Riverpod providers: StateNotifier vs AsyncNotifier boundaries
- Repository pattern; data layer isolation
- Widget / state separation; GoRouter navigation
- See `ARCHITECTURE.md` for feature-first structure and DI conventions
