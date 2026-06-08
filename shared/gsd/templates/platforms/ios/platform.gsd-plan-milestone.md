# Platform context — Native iOS (gsd-plan-milestone)

Copy from `ios/.cursor/skills/gsd-plan-milestone/platform.md` in ai-playbook overlay when installed, or customize here.

## Read order

1. `AGENTS.md`
2. `ARCHITECTURE.md`
3. `.gsd/DELIVERY-PROFILE.md`

## Verification (post-milestone)

```bash
xcodebuild -scheme [AppScheme] -configuration Debug \
  -destination 'platform=iOS Simulator,name=[SimulatorName]' \
  test 2>&1 | tail -40
```

## Grill hints

- Swift concurrency; protocol boundaries for services
- Copy/constants co-located per feature
- See `ARCHITECTURE.md` for navigation and DI patterns
