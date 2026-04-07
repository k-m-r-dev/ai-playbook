# Flutter BLoC AI Template Usage

This folder is a starter template for adding high-quality AI coding context to a Flutter repository using BLoC/Cubit.

## Included Patterns

- A base architecture document in `ARCHITECTURE.md`
- A shared source of truth in `AGENTS.md`
- Claude-compatible entrypoint and skills in `CLAUDE.md` and `.claude/`
- Cursor-compatible rules in `.cursor/rules/`
- Copilot-compatible instructions and agent roles in `.github/` (generic coding patterns live in **`implementation.instructions.md`**; put app-only facts in **`doc/copilot-project-appendix.md`** when you add that file in the client repo)
- A starter `skills-lock.json` registry pattern

## Customization Order

1. Fill in `ARCHITECTURE.md` with project-specific paths, environments, and naming.
2. Replace placeholder commands with real build, test, lint, and format commands.
3. Add project-specific security, performance, and compliance rules.
4. Extend skill packs for networking, persistence, design system, and testing workflows.
