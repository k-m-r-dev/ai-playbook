# Universal AI playbook overlay

Stack-agnostic template for **any** repository: backend, frontend, mobile, desktop, infra, or CI/CD. Unifies **Claude Code**, **Cursor**, and **GitHub Copilot** with optional **GSD-Pi**, **graphify**, and **ruflo**.

## Quick install (client project)

```bash
bash /path/to/ai-playbook/scripts/install-client-ai-overlay.sh \
  --source-repo ~/private/ai-playbook \
  --client-repo ~/projects/my-service \
  --platform universal \
  --mode symlink
```

Then customize committed **`CLAUDE.md`** (ledger), **`ARCHITECTURE.md`** (`## Project Layout`), and **`AGENTS.md`** (continual-learning sections). Playbook templates in **`_CLAUDE.md`**, **`_AGENTS.md`**, etc. are symlinks — edit those in your ai-playbook repo, not in the client checkout.

## First-time local infrastructure

```bash
# Ruflo (Claude Code MCP + memory)
npx ruflo@latest init --wizard
claude mcp add ruflo -- npx -y ruflo@latest mcp start

# Graphify (structural AST graph)
pip install graphifyy   # or: uv tool install graphifyy
graphify build

# GSD-Pi (milestones — Cursor)
# Enable gsd-workflow MCP in Cursor; use .cursor/skills/gsd-pi-cursor
```

Copy hook and MCP templates from `ai-playbook/config/` — see root **`FRAMEWORK.md`**.

## Files in this overlay

| File | Role |
|------|------|
| `CLAUDE.md` | **Ledger wrapper** (committed) — `@_CLAUDE.md` + stack, topography, milestone, learnings |
| `_CLAUDE.md` | Playbook entrypoint symlink |
| `AGENTS.md` | **Policy wrapper** — `@_AGENTS.md` + continual-learning sections |
| `_AGENTS.md` | Playbook policy symlink |
| `ARCHITECTURE.md` | **Structure wrapper** — `@_ARCHITECTURE.md` + `## Project Layout` |
| `_ARCHITECTURE.md` | Playbook architecture template symlink |
| `SESSION_WORKFLOW.md` | **Process wrapper** — `@_SESSION_WORKFLOW.md` |
| `_SESSION_WORKFLOW.md` | Playbook session process symlink |
| `.github/copilot-instructions.md` | Copilot-specific directives |
| `.cursor/rules/05-unified-ai-framework.mdc` | Token budget + local-first rules |

## Platform-specific depth

Use **`universal`** by default. Add or switch to **`ios`**, **`android`**, **`flutter-riverpod`**, or **`flutter-bloc`** when you need native/mobile skills and stack-specific `ARCHITECTURE.md` templates.

## Extending

See **`EXTENDING.md`** at the ai-playbook repository root to register additional AI tools (Windsurf, Codex, JetBrains, custom MCP).
