# Flutter Riverpod AI Template Usage

This folder is a starter template for adding high-quality AI coding context to a Flutter repository using Riverpod.

## Included Patterns

- A base architecture document in `ARCHITECTURE.md`
- A shared source of truth in `AGENTS.md`
- Claude-compatible entrypoint and skills in `CLAUDE.md` and `.claude/`
- Cursor-compatible rules in `.cursor/rules/`
- Copilot-compatible instructions and agent roles in `.github/` (generic coding patterns live in **`implementation.instructions.md`**; put app-only facts in **`doc/copilot-project-appendix.md`** when you add that file in the client repo)
- A starter `skills-lock.json` registry pattern
- Architecture routing: **Cursor** `15-architecture.mdc`, **Claude** `architecture-playbook`, and **Copilot** `architecture.instructions.md` share the **identical routing body** (only tool metadata differs); the full structure doc lives only in **`ARCHITECTURE.md`** (follows install **`--mode`** like other root files).
- Session workflow: `.workflow/` (**copied** at install) and root `SESSION_WORKFLOW.md` (follows install **`--mode`**, usually **symlink**). **Cursor** `20-session-progress.mdc`, **Claude** `session-progress-workflow`, and **Copilot** `session-progress.instructions.md` share the **identical routing body** (only tool metadata differs); full lifecycle and templates live only in **`SESSION_WORKFLOW.md`**; project state only under **`.workflow/`**

## Customization Order

1. Fill in `ARCHITECTURE.md` with project-specific paths, environments, and naming.
2. Replace placeholder commands with real build, test, lint, and format commands.
3. Add project-specific security, performance, and compliance rules.
4. Extend skill packs for networking, persistence, design system, and testing workflows.
