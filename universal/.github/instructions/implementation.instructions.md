---
applyTo: "**"
---

# Implementation guidance (universal)

## Before coding

1. Read **`CLAUDE.md`** and **`ARCHITECTURE.md`**.
2. Use **`graphify-out/`** or graph tools to locate related modules — avoid blind repo-wide search.
3. Align with the active milestone in **`CLAUDE.md`** when using GSD.

## While coding

- Match existing patterns, naming, and error handling in the touched area.
- Keep changes scoped; update tests when behavior changes.
- Centralize configuration and secrets — never commit credentials.

## After coding

- Run build/test/lint commands from **`AGENTS.md`**.
- Update **`.workflow/`** and **`CLAUDE.md`** per `SESSION_WORKFLOW.md` at session end.

## Project-specific appendix

Optional client-only facts (API base URLs, internal package names, codegen commands) belong in **`doc/copilot-project-appendix.md`** in the client repo — not in the shared playbook symlink.
