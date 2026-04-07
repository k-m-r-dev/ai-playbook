---
applyTo: "**"
excludeAgent: ["Reviewer"]
---

# Native iOS Implementation Instructions

## Mission

Build maintainable native iOS software with clear architecture, strong typing, safe defaults, and reviewable changes.

## Architecture Rules

- **Read `ARCHITECTURE.md` before implementing any feature, refactor, or structural change.** It is the project-specific source of truth for the app shell, navigation, DI, data layer, and feature checklist.
- Keep app composition, feature logic, shared services, and design system concerns separate
- New work should follow the modern project structure rather than extending obsolete patterns
- Prefer explicit boundaries between UI, domain, data access, and platform integrations
- Avoid hidden cross-feature coupling

## Session & progress documentation

- Follow **`SESSION_WORKFLOW.md`** and **`session-progress.instructions.md`**; apply substantive edits only under **`.workflow/`** (see playbook for the checklist—do not duplicate here).

## Coding Rules

- Prefer Swift language features that improve safety and readability
- Prefer protocol boundaries at system edges, not everywhere by default
- Keep async work cancellable and lifecycle-aware
- Keep copy, constants, storage keys, and identifiers centralized
- Avoid one-off utility sprawl; either create a real shared abstraction or keep logic local

## Quality Requirements

- **Run tests after every implementation change. A change is not done until tests pass.**
  - Pinned simulator: `xcodebuild -scheme [AppScheme] -configuration Debug -destination 'platform=iOS Simulator,name=[SimulatorName],OS=[SimulatorOS]' test -only-testing:[TestBundle] 2>&1 | tail -40`
  - Latest simulator: `xcodebuild -scheme [AppScheme] -configuration Debug -destination 'platform=iOS Simulator,name=[SimulatorName]' test -only-testing:[TestBundle] 2>&1 | tail -40`
  - Generic build (no signing): `xcodebuild -scheme [AppScheme] -configuration Debug -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build 2>&1`
- Add or update tests for changed behavior
- Preserve backwards compatibility unless the change explicitly includes a migration
- Avoid broad refactors unless they are necessary for correctness or maintainability
- Optimize for simple, inspectable diffs

## Security Requirements

- Never introduce hardcoded secrets
- Avoid logging sensitive data
- Validate untrusted input and external payloads
- Be explicit about permissions, persistence, and network behavior

## Output Style

- Explain assumptions when the repository does not define them
- Prefer concrete edits over abstract advice
- Call out missing tests, migration risks, or unclear ownership
