## Learned User Preferences

- Prefer grill-style clarification (one question at a time, recommendation plus alternatives) before implementing ambiguous skill or template work.
- Keep internal routing labels such as "Path B" out of user-facing skill and template docs when only one path is shipped.
- Do not edit symlinked overlay files from ai-playbook in client repos; put project-specific overrides in committed wrappers that include playbook `_AGENTS.md` / `_CLAUDE.md` (same pattern as CLAUDE.md).
- Continual-learning should maintain only project-local `AGENTS.md` learned sections — never overwrite playbook-owned `_AGENTS.md` policy content.
- Prefer a short plan and explicit approval before permanent cross-client fixes.
- Client installs must preserve IP isolation: never ship ai-playbook source content into client repositories.
- Prefer Cursor-billed GSD orchestration via gsd-workflow MCP and `.gsd/` (gsd-pi v3) over CLI `gsd_execute` / Copilot billing for plan and execute skills.
- When configuring client repos, ensure `.gitignore` covers overlay-generated or local-engine artifacts that should not be committed.

## Learned Workspace Facts

- This repository is the source template for client AI overlays (`ios/`, `android/`, `flutter-riverpod/`, `flutter-bloc/`, `universal/`), not a typical application codebase.
- Client overlay install uses `scripts/install-client-ai-overlay.sh` with `--platform` and typically `--mode symlink`.
- Overlay install pattern: playbook files are symlinked as `_AGENTS.md`, `_CLAUDE.md`, `_ARCHITECTURE.md`, `_SESSION_WORKFLOW.md`; committed wrappers include those and hold project-specific plus continual-learning sections.
- The framework unifies Cursor, Claude Code, and VS Code Copilot around local-first engines: gsd-pi, graphify, and ruflo.
- `graphify-obsidian` is shipped on platform templates and this repo as a `/graphify-obsidian` wrapper around graphify Obsidian export.
- `scripts/repair-after-ruflo.sh` re-applies playbook hook-handler safety after `ruflo init` overwrites client helpers.
- On macOS, graphify is commonly installed with `uv tool install graphifyy` (acceptable alternative to pip).
