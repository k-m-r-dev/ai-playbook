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

1. Fill in `ARCHITECTURE.md` → `## Project Layout` with project-specific paths, environments, and naming.
2. Update `CLAUDE.md` ledger (stack, build/test commands, topography, milestones).
3. Let continual-learning maintain `AGENTS.md` learned sections; extend shared policy in ai-playbook `_AGENTS.md`.
4. Add project-specific security, performance, and compliance rules to `_AGENTS.md` in ai-playbook when they apply to all installs.
5. Extend skill packs for networking, persistence, design system, and testing workflows in ai-playbook.
