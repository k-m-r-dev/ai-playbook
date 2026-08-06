## Learned User Preferences

- Prefer grill-style clarification (one question at a time, recommendation plus alternatives) before implementing ambiguous skill or template work.
- Keep internal routing labels such as "Path B" out of user-facing skill and template docs when only one path is shipped.
- Do not edit symlinked overlay files from ai-playbook in client repos; put project-specific overrides in committed wrappers that include playbook `_AGENTS.md` / `_CLAUDE.md` (same pattern as CLAUDE.md).
- Continual-learning should maintain only project-local `AGENTS.md` learned sections — never overwrite playbook-owned `_AGENTS.md` policy content.
- Prefer a short plan and explicit approval before permanent cross-client fixes.
- Client installs must preserve IP isolation: never ship ai-playbook source content into client repositories.
- Prefer Cursor-billed GSD orchestration via gsd-workflow MCP and `.gsd/` (gsd-pi v3) over CLI `gsd_execute` / Copilot billing for plan and execute skills.
- When configuring client repos, ensure `.gitignore` covers overlay-generated or local-engine artifacts that should not be committed.
- Before editing Claude or Copilot skill surfaces on platform templates, check whether they are symlinked to Cursor; update only real files and leave symlinked surfaces alone.
- For multi-stack monorepos, prefer `--platform universal` at the repo root and defer nested Flutter (or other) platform overlays until that package exists.
- Set client GSD delivery values in that project's `.gsd/DELIVERY-PROFILE.md`; do not customize `shared/gsd/templates/DELIVERY-PROFILE.md` for a single client.
- Prefer a personal global skills hub at `~/.agents/skills` (with Cursor/Claude bridges) while playbook `shared/gsd` remains the source of truth; unify skills such as do-next / do-next-runner like ticket-to-plan (single SoT, no multi-template forks; platform specifics via adaptable `platform.md` packs).

## Learned Workspace Facts

- This repository is the source template for client AI overlays (`ios/`, `android/`, `flutter-riverpod/`, `flutter-bloc/`, `universal/`), not a typical application codebase.
- Client overlay install uses `scripts/install-client-ai-overlay.sh` with `--platform` and typically `--mode symlink`.
- Overlay install pattern: playbook files are symlinked as `_AGENTS.md`, `_CLAUDE.md`, `_ARCHITECTURE.md`, `_SESSION_WORKFLOW.md`; committed wrappers include those and hold project-specific plus continual-learning sections.
- The framework unifies Cursor, Claude Code, and VS Code Copilot around local-first engines: gsd-pi, graphify, and ruflo.
- `graphify-obsidian` is shipped on platform templates and this repo as a `/graphify-obsidian` wrapper around graphify Obsidian export.
- `scripts/repair-after-ruflo.sh` re-applies playbook hook-handler safety after `ruflo init` overwrites client helpers.
- On macOS, graphify is commonly installed with `uv tool install graphifyy` (acceptable alternative to pip).
- On platform templates, `.claude/skills/<name>` are typically directory symlinks to `../../.cursor/skills/<name>`; Copilot `.github/instructions/*.instructions.md` are real files that must be synced separately.
- Playbook skills are authored in `shared/gsd/**/SKILL.body.md` and assembled onto platform templates via `shared/gsd/scripts/install-workflow-tools.sh`.
- To wire only gsd-workflow MCP (not the full overlay), use `scripts/bootstrap-gsd-workflow.sh` with `--patch-mcp` (and usually `--init-gsd`); reserve `install-client-ai-overlay.sh` for full overlay installs. Client delivery settings then live in `.gsd/DELIVERY-PROFILE.md` (copied from `shared/gsd/templates/`); re-bootstrap without `--force` will not overwrite an existing profile.
- Nested overlays are supported as a second `install-client-ai-overlay.sh` run into a client subfolder after the top-level platform install.
- If lean-ctx reports it is rooted elsewhere, the MCP jail is bound to another workspace; reload or re-enable the lean-ctx MCP (or add `extra_roots`) so `ctx_*` matches the open repo.
