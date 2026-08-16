# Playbook entrypoint (symlink as `_CLAUDE.md`)

Thin playbook base for **Claude Code**, **Cursor**, and **GitHub Copilot**. Mutable project ledger lives in committed **`CLAUDE.md`** (`@_CLAUDE.md` + sections below).

@_AGENTS.md
@_ARCHITECTURE.md
@_SESSION_WORKFLOW.md

## Usage

- **`_CLAUDE.md`** (this file) — playbook base; symlink to shared `ai-playbook` — do not edit in client repos
- **`CLAUDE.md`** — committed project ledger (environment, session scratch, learnings)
- **`AGENTS.md`** — committed wrapper (`@_AGENTS.md` + continual-learning sections)
- **`ARCHITECTURE.md`** — committed wrapper (`@_ARCHITECTURE.md` + `## Project Layout`)
- **`SESSION_WORKFLOW.md`** — committed wrapper (`@_SESSION_WORKFLOW.md` only)
- Deeper implementation playbooks: `.claude/skills/`
