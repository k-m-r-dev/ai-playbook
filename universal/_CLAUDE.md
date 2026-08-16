# Playbook entrypoint (symlink as `_CLAUDE.md`)

Universal playbook base for **Claude Code**, **Cursor**, and **GitHub Copilot**. Mutable project ledger lives in committed **`CLAUDE.md`**. Push durable policy to `_AGENTS.md`, structure to `_ARCHITECTURE.md`, and rhythm to `_SESSION_WORKFLOW.md` via their committed wrappers.

@_AGENTS.md
@_ARCHITECTURE.md
@_SESSION_WORKFLOW.md

## Tool routing (read-only reference)

| Tool | Primary config | Local engines |
|------|----------------|---------------|
| Claude Code | `.claude/settings.json`, `.mcp.json`, hooks | optional; none required |
| Cursor | `.cursor/rules/`, `.cursor/mcp.json` | optional; none required |
| VS Code Copilot | `.github/copilot-instructions.md`, `.github/instructions/` | optional; none required |

Full setup: `FRAMEWORK.md` in your `ai-playbook` source repo, or `universal/README.md` after overlay install.
