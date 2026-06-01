# Playbook entrypoint (symlink as `_CLAUDE.md`)

Thin playbook base for **Claude Code**, **Cursor**, and **GitHub Copilot**. Mutable project ledger lives in committed **`CLAUDE.md`** (`@_CLAUDE.md` + sections below).

@_AGENTS.md
@_ARCHITECTURE.md
@_SESSION_WORKFLOW.md

## Usage

- **`_CLAUDE.md`** (this file) — playbook base; symlink to shared `ai-playbook` — do not edit in client repos
- **`CLAUDE.md`** — committed project ledger (environment, topography, milestones, learnings)
- **`AGENTS.md`** — committed wrapper (`@_AGENTS.md` + continual-learning sections)
- **`ARCHITECTURE.md`** — committed wrapper (`@_ARCHITECTURE.md` + `## Project Layout`)
- **`SESSION_WORKFLOW.md`** — committed wrapper (`@_SESSION_WORKFLOW.md` only)
- Deeper implementation playbooks: `.claude/skills/`

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
