# Native iOS AI Template Usage

This folder is a starter template for adding high-quality AI coding context to a native iOS repository.

## Goal

Give any supported coding agent enough context to make safer decisions with less prompting.

## Included Patterns

- A base architecture document in `ARCHITECTURE.md`
- A shared source of truth in `AGENTS.md`
- Claude-compatible entrypoint and skills in `CLAUDE.md` and `.claude/`
- Cursor-compatible rules in `.cursor/rules/`
- Copilot-compatible instructions and agent roles in `.github/`
- A starter `skills-lock.json` registry pattern

## How To Use With Claude

1. Copy `AGENTS.md` and `CLAUDE.md` to the repository root.
2. Copy `.claude/skills/` into the repository.
3. Ask Claude to read `CLAUDE.md` first, then follow the referenced skills as needed.
4. Keep durable architecture decisions in `AGENTS.md`, not in prompts.

## How To Use With Cursor

1. Copy `.cursor/rules/` into the repository root.
2. Keep the broad project contract in `AGENTS.md` so Cursor users and non-Cursor users share one source of truth.
3. Use small rule files with focused concerns: project context, implementation rules, and review criteria.
4. If using an older Cursor setup, mirror the most important project context into `.cursorrules` as a compatibility fallback.

## How To Use With GitHub Copilot

1. Copy `AGENTS.md` to the repository root.
2. Copy `.github/instructions/` and `.github/agents/` into the repository.
3. Copy `.claude/skills/` too, even if Copilot does not load those files automatically.
4. Keep agent roles explicit so planning, implementation, and review can follow separate responsibilities.
5. Reference skills by name from `.github/agents/*.agent.md` and keep fallback rules in `.github/instructions/`.

## How The Copilot Bridge Works

- Canonical implementation guidance lives in `.claude/skills/`
- `AGENTS.md` names the skills and their paths
- `.github/agents/*.agent.md` refers to those skills by name
- `.github/instructions/` duplicates only the minimum fallback guidance needed when direct skill loading is unavailable
- `skills-lock.json` gives automation a predictable catalog of the available skills

## Customization Order

1. Fill in `ARCHITECTURE.md` with project-specific paths, environments, and brand values.
2. Update architecture boundaries and folder conventions.
2. Replace placeholder commands with real build, test, lint, and format commands.
3. Add project-specific security, performance, and compliance rules.
4. Extend skill packs for networking, persistence, design system, testing, and release workflows.

## Maintenance Guidance

- Change `AGENTS.md` first when policy changes
- Keep tool-specific files aligned with that source of truth
- Remove stale rules aggressively
- Prefer short, direct instructions over long narrative documents
