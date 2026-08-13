## Learned User Preferences

- Prefer grill-style clarification (one question at a time, plain-English explanation per option, `[recommended]` default) before ambiguous skill, template, or client-configuration work; after configure/bootstrap, flag remaining gaps and ask whether to apply each rather than leaving leftover merge-yourself notes.
- Do not edit symlinked overlay files from ai-playbook in client repos; put project-specific overrides in committed wrappers that include playbook `_AGENTS.md` / `_CLAUDE.md` (same pattern as CLAUDE.md).
- Continual-learning should maintain only project-local `AGENTS.md` learned sections — never overwrite playbook-owned `_AGENTS.md` policy content.
- Prefer a short plan and explicit approval before permanent cross-client fixes.
- Client installs must preserve IP isolation: never ship ai-playbook source content into client repositories.
- Prefer agent-driven do-next / do-next-runner across Cursor, Claude CLI, and oh-my-pi (gsd-pi as ledger/MCP) via gsd-workflow plus the playbook claim bridge; avoid unsupervised full `gsd_execute` / Copilot billing unless the user opts in.
- Prefer playbook-owned GSD claim/publish bridges over waiting on upstream gsd-pi PRs when using gsd outside their app; comfortable with GSD's projected plan files if ticket-to-plan → do-next stays reviewable (not locked to phases `PLAN.md` checkboxes).
- When configuring client repos, ensure `.gitignore` covers overlay-generated or local-engine artifacts that should not be committed.
- Before editing Claude or Copilot skill surfaces on platform templates, check whether they are symlinked to Cursor; update only real files and leave symlinked surfaces alone.
- For multi-stack monorepos, prefer `--platform universal` at the repo root and defer nested Flutter (or other) platform overlays until that package exists.
- Set client GSD delivery values in that project's `.gsd/DELIVERY-PROFILE.md` (clean profile only — never append `CLAUDE.md` / `AGENTS.md` wrapper content); do not customize `shared/gsd/templates/DELIVERY-PROFILE.md` for a single client.
- Prefer a personal global skills hub at `~/.agents/skills` (Cursor/Claude bridges; optional Codex) with playbook `shared/gsd` as SoT; add/update skills via `shared/gsd/ADDING-SKILLS.md` and `scripts/install-personal-agents-hub.sh` / `update-personal-skill.sh` (manifest: `shared/gsd/personal-skills.manifest`); no multi-template skill forks — platform specifics via `shared/gsd/templates/platforms/` packs.

## Learned Workspace Facts

- This repository is the source template for client AI overlays (`ios/`, `android/`, `flutter-riverpod/`, `flutter-bloc/`, `universal/`), not a typical application codebase.
- Client overlay install uses `scripts/install-client-ai-overlay.sh` with `--platform` and typically `--mode symlink`.
- Overlay install pattern: playbook files are symlinked as `_AGENTS.md`, `_CLAUDE.md`, `_ARCHITECTURE.md`, `_SESSION_WORKFLOW.md`; committed wrappers include those and hold project-specific plus continual-learning sections.
- The framework unifies Cursor, Claude Code, and VS Code Copilot around local-first engines: gsd-pi, graphify, and ruflo.
- Personal Agents Hub skills (do-next, do-next-runner, ticket-to-plan, graphify-obsidian, etc.) live under `shared/gsd/`; install/refresh with `scripts/install-personal-agents-hub.sh` and `scripts/update-personal-skill.sh`; `sync-gsd-skills-to-overlays.sh` is retired and refuses.
- `scripts/repair-after-ruflo.sh` re-applies playbook hook-handler safety after `ruflo init`; Cursor pre-tool hooks need JSON `permissionDecision` on stdout from `.claude/helpers/hook-handler.cjs` (human `[OK]` on stderr).
- After `gsd_plan_slice` / ticket-to-plan, gsd-pi Attempt-based completion needs a running Attempt; playbook ships `shared/gsd/mcp/gsd-external-executor` (`playbook_gsd_task_begin` → `gsd_task_complete` → `playbook_gsd_task_publish` / abort) so do-next can advance the ledger without unsupervised `gsd_execute`.
- On platform templates, `.claude/skills/<name>` are typically directory symlinks to `../../.cursor/skills/<name>`; Copilot `.github/instructions/*.instructions.md` are real files that must be synced separately.
- Playbook skills are authored under `shared/gsd/` (flat `SKILL.md` or assembled `SKILL.body.md`); client install via `shared/gsd/scripts/install-workflow-tools.sh --project` (flat orphans need `--tools`).
- Preferred client GSD bring-up: playbook-operator `configure-client-project` skill from ai-playbook (`scripts/configure-client-check.sh` preflight, grill-style delivery interview, then overlay + `bootstrap-gsd-workflow.sh`); install via `scripts/update-personal-skill.sh configure-client-project`. Manual fallback: `install-client-ai-overlay.sh` then `bootstrap-gsd-workflow.sh` with `--patch-mcp --with-do-next` (and `--harness-context` when useful); skip `--init-gsd` if client already has `gsd.db`. `--patch-mcp` does not overwrite existing `.mcp.json`; `configure-client-project` should flag missing `playbook-gsd` and other gaps and ask whether to apply each. `--with-do-next` copies `playbook-gsd-health.sh` into client `.workflow/scripts/`. stderr warnings for `GSD_WORKFLOW_EXECUTORS_MODULE` / `GSD_WORKFLOW_WRITE_GATE_MODULE` are expected. Re-bootstrap without `--force` will not overwrite an existing `DELIVERY-PROFILE.md`.
- `.gsd` is often a symlink to `~/.gsd/projects/<id>`; path jails must allow that resolved store. Machine `.mcp.json` / `.workflow/` copies are local; committed SoTs are `config/mcp.template.json` and `shared/gsd/scripts/playbook-gsd-health.sh`.
- If lean-ctx reports it is rooted elsewhere, the MCP jail is bound to another workspace; reload or re-enable the lean-ctx MCP (or add `extra_roots`) so `ctx_*` matches the open repo.
