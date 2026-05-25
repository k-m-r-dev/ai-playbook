# Native iOS AI Development Template

Generic AI-first template for native iOS projects using Swift and Apple platform tooling.

## Purpose

Provide durable, high-signal context so coding agents can plan, implement, and review native iOS changes consistently.

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
- **Cursor** (`.cursor/rules/15-architecture.mdc`), **Claude** (`architecture-playbook` skill), and **Copilot** (`architecture.instructions.md`) share the **same routing body** for reading **`ARCHITECTURE.md`** first; only metadata differs (`globs` / skill frontmatter / `applyTo`). **Claude** also loads it via **`CLAUDE.md`** (`@ARCHITECTURE.md`). Do not duplicate layer or module rules in those three—only in **`ARCHITECTURE.md`**.
- When updating architecture decisions in a client project, update `ARCHITECTURE.md` first, then keep this file aligned.

## Commands

Run from the iOS app root:

```bash
# Build
xcodebuild -scheme [AppScheme] -configuration Debug build

# Run tests on a pinned simulator (preferred – matches CI)
xcodebuild -scheme [AppScheme] -configuration Debug \
  -destination 'platform=iOS Simulator,name=[SimulatorName],OS=[SimulatorOS]' \
  test -only-testing:[TestBundle] 2>&1 | tail -40

# Run tests on latest available simulator of a given device (no OS pin)
xcodebuild -scheme [AppScheme] -configuration Debug \
  -destination 'platform=iOS Simulator,name=[SimulatorName]' \
  test -only-testing:[TestBundle] 2>&1 | tail -40

# Build without code signing (CI / no provisioning profile)
xcodebuild -scheme [AppScheme] -configuration Debug \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build 2>&1

# Lint if configured
swiftlint

# Format if configured
swiftformat .
```

> **Placeholders** – replace before use:
> - `[AppScheme]` – Xcode scheme name (e.g. `MyApp`)
> - `[SimulatorName]` – simulator device name (e.g. `iPhone 16`)
> - `[SimulatorOS]` – OS version string (e.g. `18.4`); omit the `,OS=` clause to pick the latest installed
> - `[TestBundle]` – unit-test target name (e.g. `MyAppTests`)

## Suggested Repository Layout

- `App/`: app entry point, lifecycle, composition root, dependency wiring
- `Features/`: user-facing feature modules grouped by business capability
- `Core/`: networking, storage, auth, analytics, logging, shared utilities
- `DesignSystem/`: reusable UI components, tokens, themes, accessibility helpers
- `Testing/`: shared test helpers, mocks, fixtures, contract tests
- `Scripts/`: automation for build, release, lint, code generation, validation

## Core Principles

- Favor clear module boundaries and explicit dependencies
- Keep domain logic separate from UI and platform glue
- Make state ownership obvious and keep a single source of truth per flow
- Prefer typed interfaces, small units, and predictable data flow
- Fail loudly in development, recover gracefully in production paths
- Write code that is easy for both humans and agents to extend safely

## Conventions

- Every non-trivial feature should define:
  - `dictionary.swift` for user-facing strings or copy contracts
  - `constants.swift` for non-user-facing constants, thresholds, and defaults
- Do not inline user-facing copy across multiple files
- Do not scatter magic numbers, notification names, or storage keys
- Prefer protocol boundaries for services, repositories, and integrations
- Prefer constructor injection or explicit dependency containers over hidden globals
- Add or update tests for each changed behavior; target meaningful coverage for changed files

## Quality Bar

- Strong typing throughout Swift code
- Structured concurrency preferred over ad hoc callback chains
- Clear error handling with actionable user-safe messages
- Deterministic tests for logic, data mapping, and failure cases
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

## Session & progress docs

Canonical playbook: **`SESSION_WORKFLOW.md`** (full process + templates). **Cursor** (`.cursor/rules/20-session-progress.mdc`), **Claude** (`session-progress-workflow` skill), and **Copilot** (`session-progress.instructions.md`) share the **same routing body**; only metadata differs (`globs` / skill frontmatter / `applyTo`). **Claude** also loads playbooks via **`CLAUDE.md`** (`@ARCHITECTURE.md`, `@SESSION_WORKFLOW.md`). Do not duplicate lifecycle or templates in those three—only in **`SESSION_WORKFLOW.md`** (`ai-playbook`).

For substantive work, follow that playbook: keep `.workflow/current_session_progress.md` updated during the session, archive to `.workflow/previous_session_progress.md` at handoff, and align `.workflow/progress_tracker.md` when tasks or schema change. **`.workflow/` is always copied** at overlay install (project-owned state). **`SESSION_WORKFLOW.md` uses the installer `--mode`** (typically **symlink** next to `AGENTS.md`); use **`--mode copy`** if your environment cannot resolve symlinks.

## Tool Mapping

- Claude: entry point is `CLAUDE.md`, which should reference this file
- Cursor: entry point is `.cursor/rules/`, which should align with this file
- GitHub Copilot: `.github/instructions/` and `.github/agents/` should reinforce this file
- MCP Servers: use corresponding MCP servers for github, figma
- Other tools: point them here first, then to tool-specific overlays only if needed

## Skills

These skills are the canonical implementation playbooks for the template. If a tool can load skill files directly, use them. If not, mirror the same rules into the tool-specific instruction layer.

| Skill | Path | Purpose |
| --- | --- | --- |
| ios-architecture | `.claude/skills/ios-architecture/SKILL.md` | High-level repository layout, module boundaries, and planning heuristics |
| native-ios-architecture | `.claude/skills/native-ios-architecture/SKILL.md` | Feature-level iOS implementation patterns and module structure |
| native-data-fetching | `.claude/skills/native-data-fetching/SKILL.md` | Network design, request lifecycle, retries, caching, and error handling |
| security-and-privacy | `.claude/skills/security-and-privacy/SKILL.md` | Secrets handling, sensitive data rules, validation, storage, and permissions |
| apple-platform-quality | `.claude/skills/apple-platform-quality/SKILL.md` | Performance, accessibility, concurrency, release quality, and review heuristics |
| architecture-playbook | `.claude/skills/architecture-playbook/SKILL.md` | Thin routing to `ARCHITECTURE.md` (pairs with root `ARCHITECTURE.md`) |
| session-progress-workflow | `.claude/skills/session-progress-workflow/SKILL.md` | Session docs, handoff rhythm, `.workflow/*` (pairs with `SESSION_WORKFLOW.md`) |
| gsd-pi-cursor | `.cursor/skills/gsd-pi-cursor/SKILL.md` | Grill + milestone plan in Cursor via gsd-workflow MCP |
| gsd-next-cursor | `.cursor/skills/gsd-next-cursor/SKILL.md` | Advance one GSD unit in Cursor (plan slice / execute task) via gsd-workflow MCP; Cursor billing only |

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
