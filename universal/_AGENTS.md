# Universal AI Development Template

Stack-agnostic playbook for **backend**, **frontend**, **mobile**, **desktop**, **libraries**, and **CI/CD** repositories. Optimized for local-first context: **graphify** (structure), **ruflo** (memory).

## Supported tools

| Tool | Entry | Notes |
|------|-------|-------|
| Claude Code | `CLAUDE.md` | MCP + hooks for ruflo / graphify |
| Cursor | `.cursor/rules/` | MCP for graphify + ruflo; rules enforce token budget |
| GitHub Copilot | `.github/copilot-instructions.md` | Markdown-only; uses `graphify-out/` maps |

Optional tools: see `EXTENDING.md` in the ai-playbook repo for how to add Windsurf, Codex CLI, JetBrains AI, etc.

## Operating model

1. **Read `CLAUDE.md`** at session start (ledger: stack, topography, milestone, learnings).
2. **Read `ARCHITECTURE.md`** before non-trivial design or multi-module work.
3. **Traverse structure** via graphify (`graphify-out/`, graph MCP) — not whole-repo text search.
4. **Follow `SESSION_WORKFLOW.md`** for `.workflow/` session files.
5. **Consolidate learnings** into ruflo + update `CLAUDE.md` at session end.

## Commands (customize per project)

```bash
# Example Node — replace with your stack
npm run build
npm test
npm run lint

# Local infrastructure (when installed)
graphify build
graphify check-update --silent
npx ruflo@latest memory search --query "<keywords>" --namespace patterns
npx ruflo@latest memory consolidate --target local
```

### Stack profile examples

| Profile | Build / test hints |
|---------|-------------------|
| Node/TS | `npm run build`, `npm test` |
| Rust | `cargo build`, `cargo test` |
| Python | `pytest`, `ruff check` |
| Go | `go build ./...`, `go test ./...` |
| JVM | `./gradlew build test` |
| .NET | `dotnet build`, `dotnet test` |
| Flutter | `flutter analyze`, `flutter test` |
| iOS | `xcodebuild` (see `ios/` playbook) |
| Android | `./gradlew test` (see `android/` playbook) |

Copy a platform-specific overlay (`ios`, `android`, `flutter-*`) when you need deeper stack skills; use **`universal`** as the default for everything else.

## Repository layout (suggested)

Adapt names to your stack; document the real layout in `ARCHITECTURE.md`.

```text
src/ or app/     — application code
tests/           — automated tests
docs/            — human docs (not AI overlay)
config/          — configuration
scripts/         — automation
.graphify-out/   — local AST graph (gitignored)
.ruflo/          — local HNSW memory (gitignored)
.workflow/       — session scratch (overlay install)
```

## Core principles

- Explicit module boundaries and dependency direction
- Validate at system boundaries; never commit secrets
- Small, reviewable diffs; match existing conventions
- Tests or verification commands after behavior changes
- Prefer graph-backed navigation over reading entire directories into context

## Agent roles

- **Planner**: constraints, plan, milestone alignment
- **Coder**: implement approved direction
- **Reviewer**: correctness, security, architecture fit, tests

Definitions: `.github/agents/*.agent.md`

## Tool mapping

| Concern | Canonical | Cursor | Claude | Copilot |
|---------|-----------|--------|--------|---------|
| Policy | `AGENTS.md` | rules `00`, `10` | via `CLAUDE.md` | copilot-instructions |
| Structure | `ARCHITECTURE.md` | `15-architecture.mdc` | `architecture-playbook` | `architecture.instructions.md` |
| Session | `SESSION_WORKFLOW.md` | `20-session-progress.mdc` | `session-progress-workflow` | `session-progress.instructions.md` |
| Token budget | `CLAUDE.md` | `05-unified-ai-framework.mdc` | hooks / skills | copilot-instructions |

## Skills (Claude)

| Skill | Purpose |
|-------|---------|
| `architecture-playbook` | Route to `ARCHITECTURE.md` |
| `session-progress-workflow` | Route to `SESSION_WORKFLOW.md` |
| `local-first-context` | graphify + ruflo before broad search |
| `graph-navigate` | Query `graphify-out/` and graph MCP |
| `graphify-obsidian` | `/graphify-obsidian <vault-dir>` — build graph + export Obsidian vault |

Registry: `skills-lock.json`

## Privacy

- Overlay install keeps playbook files out of client git via `.git/info/exclude` (see install script).
- Local memory and graphs stay on disk; configure vendor enterprise privacy separately if required.
