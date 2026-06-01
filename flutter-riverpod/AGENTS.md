@_AGENTS.md

## Learned User Preferences

- Use GSD Pi in Cursor (`gsd-pi-cursor` to discuss/formalize, `gsd-next-cursor` for step execution) so planning and implementation bill the Cursor model—not the terminal `/gsd next` TUI or Copilot-only flows.
- Extend overlay skills and shared playbook files via the `ai-playbook` installer project, not ad-hoc copies only in this repo.
- Do not create git commits unless explicitly asked; when asked, draft commit messages and PR titles/descriptions in the repo's existing style.
- Ship Library and related UI in light mode only (dark mode was dropped per client request).
- Treat environments as dev and prod only for now; keep room to add more flavors later without assuming staging exists today.
- Prefer human-readable doc names under `doc/` (for example `APP-INTEGRATION.md`) over bare milestone codes (for example `M006-CONTRACT.md`).
- For Ruflo on Cursor: neutralize broken ruflo-core PreToolUse in `~/.cursor/plugins/cache/ruflo/ruflo-core` (not `~/.cursor/hooks/`); wire project hooks via `.cursor/hooks.json` and `.cursor/hooks/` adapter to `.claude/helpers/hook-handler.cjs`; re-neutralize after ruflo-core plugin updates.

## Learned Workspace Facts

- GSD milestone state and artifacts live under `.gsd/` (gsd-pi v3); persistence goes through the `gsd-workflow` MCP server.
- CI/CD and git hosting use Azure DevOps (`entwinedimaginations/Furqan`).
- Library tab CMS uses `LIBRARY_MANIFEST_URL` via `--dart-define` (pipeline/Azure Library in prod; local HTTP manifest on LAN for dev).
- Flutter SDK is managed with FVM (`.fvmrc` / `.fvm/`).
- Codebase graph is maintained with graphify (`graphify-out/`; run `graphify update .` after substantive code edits).
- Playbook templates (`_*` files) symlink into shared `ai-playbook`; committed wrappers (`AGENTS.md`, etc.) hold project-specific content; session scratch belongs in `.workflow/`.
- `library-cms/scripts/` is tracked despite the root `scripts/` gitignore rule.
- Dev environment uses Nix flake + direnv (`.envrc`, `flake.nix`, `flake.lock`); `.direnv/` is local cache and gitignored.
- MCP config is split: repo-root `.mcp.json` (gsd-workflow, dart-mcp-server, azure-devops, etc.) and `.cursor/mcp.json` for Cursor-only servers (e.g. codeintel-ask); both use `mcpServers` (not `servers`).
- Hybrid codebase search uses codeintel-ask (`ask` CLI + MCP in `.cursor/mcp.json`) — runs locally with no per-query API cost; prefer `graphify path`/`query` for graph-structure questions to keep agent context smaller; graphify handles architecture graph queries.
- GSD milestone folders under `.gsd/milestones/M###/` can exist on disk while missing from `gsd.db`; register with `gsd_plan_milestone` before `gsd_plan_slice` or reliable `gsd_progress` for that milestone.
- Claude Code hooks use `.claude/settings.json`; GitHub Copilot uses `.github/copilot-instructions.md` only (no Ruflo hooks).
