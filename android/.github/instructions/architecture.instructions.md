---
applyTo: "**"
---

<!-- SYNC: Keep the # Architecture section byte-identical in 15-architecture.mdc, architecture-playbook/SKILL.md, and architecture.instructions.md (each platform). -->

# Architecture

**Shared routing contract** — **Cursor** `.cursor/rules/15-architecture.mdc`, **Claude** `architecture-playbook`, **Copilot** `architecture.instructions.md`: **one** definition (body below). Only tool wrappers differ (`globs` / `alwaysApply`, skill YAML, `applyTo`).

**Where things live**

- **`_ARCHITECTURE.md`** — playbook **template** (symlink to shared `ai-playbook`). Refine in ai-playbook, not in the client repo.
- **`ARCHITECTURE.md`** — **project wrapper** (committed): `@_ARCHITECTURE.md` + `## Project Layout` for client-specific paths, modules, and diagrams.

**Substantive work** — Read **`ARCHITECTURE.md`** before planning or implementing non-trivial features, refactors, or new modules. Do not duplicate that document in chat; do not treat `ARCHITECTURE.md` as session scratch—use **`SESSION_WORKFLOW.md`** and **`.workflow/`** for ongoing session state.
