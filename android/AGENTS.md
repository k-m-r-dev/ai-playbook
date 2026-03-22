# Native Android AI Development Template

Generic AI-first template for native Android projects using Kotlin and Gradle-based tooling.

## Purpose

Provide durable, high-signal context so coding agents can plan, implement, and review native Android changes consistently.

Supported tools:

- Claude
- Cursor
- GitHub Copilot
- Other agentic coding tools that can read repository instructions

## Operating Model

- Keep a single source of truth in this file
- Mirror tool-specific details into `.claude/`, `.cursor/`, and `.github/`
- Prefer explicit architectural rules over vague preferences
- Optimize instructions for correctness, safety, and maintainability

## Architecture Document

The project's concrete architecture decisions live in `ARCHITECTURE.md`.

- **Read `ARCHITECTURE.md` before planning or implementing any feature, refactor, or structural change.**
- It defines the app shell pattern, navigation model, DI ownership rules, data layer conventions, and the step-by-step checklist for adding a new feature.
- If a general principle in this file conflicts with a specific decision in `ARCHITECTURE.md`, the architecture document takes precedence.
- When updating architecture decisions in a client project, update `ARCHITECTURE.md` first, then keep this file aligned.

## Commands

Run from the Android app root:

```bash
# Build
./gradlew assembleDebug

# Unit tests (runs all unit tests for the debug variant)
./gradlew testDebugUnitTest

# Unit tests for a specific module
./gradlew :[module]:testDebugUnitTest

# Instrumented tests on connected device or emulator
./gradlew connectedDebugAndroidTest

# Instrumented tests for a specific module
./gradlew :[module]:connectedDebugAndroidTest

# Lint
./gradlew lint

# Static analysis if configured
./gradlew detekt

# Format if configured
./gradlew ktlintFormat
```

## Suggested Repository Layout

- `app/`: application module, app wiring, startup, navigation shell
- `feature/`: user-facing feature modules grouped by business capability
- `core/`: networking, storage, auth, analytics, logging, shared utilities
- `designsystem/`: reusable UI components, themes, tokens, accessibility helpers
- `testing/`: shared test helpers, fixtures, fake implementations, contracts
- `build-logic/`: convention plugins and shared build configuration

## Core Principles

- Favor clear module boundaries and explicit dependencies
- Keep domain logic separate from UI and framework glue
- Make state ownership obvious and keep a single source of truth per flow
- Prefer typed contracts, small units, and predictable data flow
- Fail loudly in development, recover gracefully in production paths
- Write code that is easy for both humans and agents to extend safely

## Conventions

- Every non-trivial feature should define:
  - string resources for user-facing copy
  - `constants.kt` for non-user-facing constants, thresholds, and defaults
  - `dictionary.kt` when the feature benefits from typed copy grouping or message contracts
- Do not inline user-facing copy across multiple files
- Do not scatter magic numbers, preference keys, route names, or analytics labels
- Prefer constructor injection or explicit dependency wiring over hidden singletons
- Add or update tests for each changed behavior; target meaningful coverage for changed files

## Quality Bar

- Strong typing throughout Kotlin code
- Structured concurrency preferred over ad hoc callback chains
- Clear error handling with actionable user-safe messages
- Deterministic tests for logic, mapping, and failure cases
- Performance-sensitive paths should avoid repeated work on the main thread
- Accessibility, localization readiness, and observability are required design concerns

## Security And Safety

- Never hardcode secrets, credentials, certificates, or tokens
- Never log sensitive identifiers, auth payloads, or raw personal data
- Validate external input before persistence or rendering
- Define timeout, retry, and cancellation behavior for network and long-running work
- Keep permission usage minimal, explicit, and documented

## Agent Workflow

- `@Planner`: analyze the codebase, identify constraints, and produce an implementation plan
- `@Coder`: implement the approved direction with small, reviewable changes
- `@Reviewer`: assess correctness, architecture fit, security, performance, and test coverage

## Tool Mapping

- Claude: entry point is `CLAUDE.md`, which should reference this file
- Cursor: entry point is `.cursor/rules/`, which should align with this file
- GitHub Copilot: `.github/instructions/` and `.github/agents/` should reinforce this file
- Other tools: point them here first, then to tool-specific overlays only if needed

## Skills

These skills are the canonical implementation playbooks for the template. If a tool can load skill files directly, use them. If not, mirror the same rules into the tool-specific instruction layer.

| Skill | Path | Purpose |
| --- | --- | --- |
| android-architecture | `.claude/skills/android-architecture/SKILL.md` | High-level repository layout, module boundaries, and planning heuristics |
| native-android-architecture | `.claude/skills/native-android-architecture/SKILL.md` | Feature-level Android implementation patterns and module structure |
| native-data-fetching | `.claude/skills/native-data-fetching/SKILL.md` | Network design, request lifecycle, retries, caching, and error handling |
| security-and-privacy | `.claude/skills/security-and-privacy/SKILL.md` | Secrets handling, sensitive data rules, validation, storage, and permissions |
| android-platform-quality | `.claude/skills/android-platform-quality/SKILL.md` | Performance, accessibility, concurrency, release quality, and review heuristics |

## Copilot Skill Bridge

- Keep the canonical knowledge in `.claude/skills/`
- Reference skills by name in `.github/agents/*.agent.md`
- Duplicate only the minimum fallback guidance in `.github/instructions/`
- Keep `skills-lock.json` aligned with the skill directories so automated tooling can discover the catalog predictably

## Template Files In This Folder

- `README.md`: setup and usage notes for Claude, Cursor, and Copilot
- `CLAUDE.md`: lightweight Claude entrypoint
- `skills-lock.json`: starter skill registry pattern
- `.github/instructions/`: implementation and review guidance for Copilot-style tools
- `.github/agents/`: planner/coder/reviewer role definitions
- `.claude/skills/`: reusable skill packs for Claude-style workflows
- `.cursor/rules/`: Cursor rule files derived from the same standards
