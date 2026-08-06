# AI Playbook — local-first multi-tool template

Private repository template for installing a **unified AI engineering overlay** into client projects without committing playbook files to client git history.

Supports **VS Code Copilot**, **Cursor**, and **Claude Code CLI**, with optional **GSD-Pi** (`@opengsd/gsd-pi`), **graphify** (AST knowledge graph), and **ruflo** (local HNSW memory). See **[FRAMEWORK.md](FRAMEWORK.md)** for the full architecture and daily loop.

## Repository layout

```text
ai-playbook/
  universal/              # Default — backend, frontend, desktop, infra, CI/CD
  ios/ android/           # Native mobile depth
  flutter-riverpod/       # Flutter + Riverpod
  flutter-bloc/           # Flutter + Bloc
  shared/gsd/             # GSD workflow + do-next templates (copied to client .gsd/)
  scripts/                # Install / uninstall / bootstrap
  config/                 # MCP + Claude hook templates
  FRAMEWORK.md            # Unified framework guide
  EXTENDING.md            # Add new AI tools
```

## Choose a platform

| Your project | `--platform` |
|--------------|--------------|
| Anything except dedicated mobile templates | **`universal`** |
| Native iOS | `ios` |
| Native Android | `android` |
| Flutter (Riverpod) | `flutter-riverpod` |
| Flutter (Bloc) | `flutter-bloc` |

Start with **`universal`** for new services, web apps, libraries, and pipelines. Use mobile folders when you need stack-specific `ARCHITECTURE.md` and skills.

`universal` now supports style-aware bootstrap via auto-detection:

- `php`
- `node`
- `react-native-mono`
- `python`
- fallback `generic`

The bootstrap/harness scripts detect style from repository structure by default and pick matching templates.
Installer also uses this style detection for root `_*.md` templates in `universal/styles/<style>/`.

## Install into a client repo

```bash
bash scripts/install-client-ai-overlay.sh \
  --source-repo ~/private/ai-playbook \
  --client-repo ~/projects/my-api \
  --platform universal \
  --mode symlink
```

Confirm `git status` in the client repo shows **no** staged AI overlay files (paths are in `.git/info/exclude`).

### Installed paths

- `_AGENTS.md`, `_CLAUDE.md`, `_ARCHITECTURE.md`, `_SESSION_WORKFLOW.md` (template files)
- `AGENTS.md`, `CLAUDE.md`, `ARCHITECTURE.md`, `SESSION_WORKFLOW.md` (wrappers / project-owned files)
- `.claude/helpers`, `.claude/skills`, `.claude/agents`, `.cursor/rules`, `.cursor/skills`, `.cursor/agents`
- `.github/agents`, `.github/instructions`, `.github/copilot-instructions.md` (universal)
- `.workflow/` (always **copied** — project-owned session state)

If wrapper files already exist, installer keeps existing content and prepends `@_...` includes when matching `_` template files are present.

GSD milestone skills (`do-next`, `do-next-runner`, `gsd-plan-milestone`, `gsd-advance-unit`) are **not** copied into platform overlay trees. Install them into a **client** with **`bootstrap-gsd-workflow.sh --with-do-next`** or **`install-workflow-tools.sh --project`**, and onto your machine via the **Personal Agents Hub** (`scripts/install-personal-agents-hub.sh`). **Runtime** `.gsd/` is still not installed by the overlay alone — run bootstrap (see below). Guides: **[shared/gsd/README.md](shared/gsd/README.md)** · **[shared/gsd/ADDING-SKILLS.md](shared/gsd/ADDING-SKILLS.md)**.

## Scripts guide (when to use what)

These scripts are for **installing and maintaining overlays in local client repos** (the playbook stays out of the client’s git history).

### `scripts/install-client-ai-overlay.sh`

- **Use when**: first-time install of the overlay into a client repo.
- **Does**: copies/symlinks overlay files into the client repo, writes a manifest to `.git/ai-playbook/<platform>.manifest.tsv`, and adds paths to `.git/info/exclude`.
- **Default mode**: `symlink` (recommended). `.workflow/` is always copied.
- **Default existing-target policy**: `merge` (safe for existing projects; keeps existing files and only adds missing overlay content).
- **Universal style selection**: for `--platform universal`, installer auto-detects project style (`php`, `node`, `react-native-mono`, `python`, fallback `generic`) and sources root `_*.md` from `universal/styles/<style>/` when available.

**Example (generic repo — recommended):**

```bash
bash scripts/install-client-ai-overlay.sh \
  --source-repo ~/private/ai-playbook \
  --client-repo ~/projects/my-service \
  --platform universal \
  --mode symlink
```

**Example (tool can’t follow symlinks):**

```bash
bash scripts/install-client-ai-overlay.sh \
  --source-repo ~/private/ai-playbook \
  --client-repo ~/projects/my-service \
  --platform universal \
  --mode copy
```

**Example (strict fail-fast, legacy behavior):**

```bash
bash scripts/install-client-ai-overlay.sh \
  --source-repo ~/private/ai-playbook \
  --client-repo ~/projects/my-service \
  --platform universal \
  --existing-policy fail
```

**Example (force universal style):**

```bash
bash scripts/install-client-ai-overlay.sh \
  --source-repo ~/private/ai-playbook \
  --client-repo ~/projects/my-service \
  --platform universal \
  --project-style php
```

**Example (mobile-specific overlay):**

```bash
bash scripts/install-client-ai-overlay.sh \
  --source-repo ~/private/ai-playbook \
  --client-repo ~/projects/my-ios-app \
  --platform ios \
  --mode symlink
```

### `scripts/uninstall-client-ai-overlay.sh`

- **Use when**: you want to remove an overlay from a client repo (cleanup, reinstall, or switch platforms).
- **Does**: removes only paths listed in the manifest; removes the exclude block; leaves unrelated files alone.

**Example:**

```bash
bash scripts/uninstall-client-ai-overlay.sh \
  --client-repo ~/projects/my-service \
  --platform universal
```

### `scripts/add-session-workflow-to-overlay.sh`

- **Use when**: the client repo already has an overlay, but `SESSION_WORKFLOW.md` is missing (older installs).
- **Does**: installs `SESSION_WORKFLOW.md` and appends it to the manifest and exclude block.
- **Important**: `--mode` must match how you installed the overlay (usually `symlink`).

**Example:**

```bash
bash scripts/add-session-workflow-to-overlay.sh \
  --source-repo ~/private/ai-playbook \
  --client-repo ~/projects/my-service \
  --platform universal
```

### `scripts/add-cursor-skills-to-overlay.sh`

- **Use when**: the client repo already has an overlay, but `.cursor/skills` is missing (older installs).
- **Does**: installs `.cursor/skills` and appends it to the manifest and exclude block.

**Example:**

```bash
bash scripts/add-cursor-skills-to-overlay.sh \
  --source-repo ~/private/ai-playbook \
  --client-repo ~/projects/my-service \
  --platform universal
```

### `scripts/add-copilot-instructions-to-overlay.sh`

- **Use when**: the client repo already has an overlay, but `.github/copilot-instructions.md` is missing (older installs).
- **Does**: installs `.github/copilot-instructions.md` (only if present in the source platform) and appends it to the manifest and exclude block.

**Example (universal):**

```bash
bash scripts/add-copilot-instructions-to-overlay.sh \
  --source-repo ~/private/ai-playbook \
  --client-repo ~/projects/my-service \
  --platform universal
```

### `scripts/patch-hook-safety-overlay.sh`

- **Use when**: existing client overlays were installed before hook-safety hardening and are missing `.claude/helpers/hook-handler.cjs`.
- **Does**: patches the installed overlay manifest and exclude block, then installs/updates `.claude/helpers` in the client repo.
- **Mode**: inherits install mode from manifest unless `--mode` is provided.

**Example:**

```bash
bash scripts/patch-hook-safety-overlay.sh \
  --source-repo ~/private/ai-playbook \
  --client-repo ~/projects/my-service \
  --platform universal
```

**After `ruflo init --start-all` overwrites hook handler** — use `repair-after-ruflo.sh` (symlink restore + hardened handler; all installed platforms by default):

```bash
bash scripts/repair-after-ruflo.sh \
  --source-repo ~/private/ai-playbook \
  --client-repo ~/projects/my-service
```

Single platform: add `--platform universal`. Lower-level control: `patch-hook-safety-overlay.sh` (optional `--mode`).

### `scripts/verify-hook-safety.sh`

- **Use when**: validating hook safety before release or after template changes.
- **Does**:
  - checks `hook-handler.cjs` drift across platform templates,
  - validates hook decision JSON contract,
  - verifies timeout path remains fail-open.

**Example:**

```bash
bash scripts/verify-hook-safety.sh
```

### `scripts/bootstrap-gsd-workflow.sh`

- **Use when**: a client repo has the overlay but needs project-owned GSD runtime (`.gsd/workflow/`, idea packages, smoke script, `DELIVERY-PROFILE.md`).
- **Does**: copies from `shared/gsd/` into the client repo; optional `--init-gsd`, `--with-do-next`, `--patch-mcp` (writes gsd-workflow into `.mcp.json`).
- **Auto-detects target stack**: updates `.gsd/DELIVERY-PROFILE.md` with project-appropriate validation commands (for example, Composer/PHP vs Node scripts).
- **Universal style selection**: for `--platform universal`, auto-selects template pack (`php`, `node`, `react-native-mono`, `python`, `generic`) unless `--project-style` is explicitly set.
- **Check only**: `--check` reports `.gsd/`, workflow, and MCP readiness without copying.

**Example (recommended after overlay install):**

```bash
bash scripts/bootstrap-gsd-workflow.sh \
  --source-repo ~/private/ai-playbook \
  --client-repo ~/projects/my-ios-app \
  --platform ios \
  --harness-context \
  --init-gsd --with-do-next --patch-mcp
```

### `scripts/add-do-next-to-overlay.sh`

- **Use when**: an existing overlay client needs GSD/do-next skills + runtime in one step.
- **Does**: runs `install-workflow-tools.sh` (all four GSD-family skills, all IDEs) then `bootstrap-gsd-workflow.sh`.

**Example:**

```bash
bash scripts/add-do-next-to-overlay.sh \
  --source-repo ~/private/ai-playbook \
  --client-repo ~/projects/my-ios-app \
  --platform ios
```

### `scripts/install-personal-agents-hub.sh`

- **Use when**: installing or refreshing personal hub skills from `shared/gsd/personal-skills.manifest` onto your machine (`~/.agents/skills` + Cursor/Claude bridges; optional `--codex`).
- **Does**: assembles/copies SoT skills, writes `~/.playbook-hub-lock.json`, and creates IDE bridges.
- **See also**: [shared/gsd/ADDING-SKILLS.md](shared/gsd/ADDING-SKILLS.md)

```bash
bash scripts/install-personal-agents-hub.sh
bash scripts/install-personal-agents-hub.sh --dry-run
```

### `scripts/update-personal-skill.sh`

- **Use when**: you changed one skill under `shared/gsd/` and want to refresh only that skill in the personal hub.
- **Does**: thin wrapper around `install-personal-agents-hub.sh --skills <name> --force`.

```bash
bash scripts/update-personal-skill.sh ticket-to-plan
# refresh all hub skills:
bash scripts/install-personal-agents-hub.sh --force
```

### `scripts/sync-gsd-skills-to-overlays.sh` (RETIRED)

- **Retired**: refuses to run. SoT skills are no longer copied into platform overlay trees.
- **Use instead**: `scripts/install-personal-agents-hub.sh` / `scripts/update-personal-skill.sh` for personal; `shared/gsd/scripts/install-workflow-tools.sh --project` for clients. See [shared/gsd/ADDING-SKILLS.md](shared/gsd/ADDING-SKILLS.md).

### `scripts/migrate-overlay-wrappers.sh`

- **Use when**: a client overlay still uses legacy root symlink model and you want wrapper + `_` template model.
- **Does**: migrates root docs to wrapper files and installs `_` template targets for current overlay platform.

### `scripts/patch-client-ai-gitignore.sh`

- **Use when**: existing overlay install is missing committed `.gitignore` managed blocks.
- **Does**: reapplies managed `.gitignore` blocks from overlay configuration without reinstalling everything.

### `scripts/bootstrap-playbook-wrappers-in-source.sh` (maintainer utility)

- **Use when**: evolving this `ai-playbook` source repo itself from legacy root docs to wrapper + `_` templates.
- **Does**: one-time/idempotent split of platform root docs into committed wrappers and template files.

### `scripts/update-sync-routing-blocks.py` (maintainer utility)

- **Use when**: syncing routing blocks/comments across wrapper/template files in this source repo.
- **Does**: updates source-side sync markers; not required for normal client overlay install flow.

### `shared/gsd/scripts/install-workflow-tools.sh`

- **Use when**: installing or refreshing GSD-family skills into a **client** repo without a full overlay reinstall.
- **Prefer for personal**: `scripts/install-personal-agents-hub.sh` (lockfile + bridges). Use `--personal` only as a fallback.
- **Modes**: `--project` (client repo) or `--personal`; pick IDEs with `--cursor`, `--claude`, `--copilot`.
- **Default `--tools`**: `do-next`, `do-next-runner`, `gsd-plan-milestone`, `gsd-advance-unit`. Flat skills (`ticket-to-plan`, `verified-pr-review`, `graphify-obsidian`) need an explicit `--tools` list.
- **Dry-run**: `--dry-run` prints actions without writing files.

**Example (project, all IDEs):**

```bash
bash shared/gsd/scripts/install-workflow-tools.sh \
  --project --cursor --claude --copilot \
  --repo ~/projects/my-ios-app
```

### `scripts/bootstrap-playbooks-from-aitools.sh` (legacy seed)

- **Use when**: you have an existing repo with `aitools/<platform>` and want to seed/update your private `ai-playbook` repo.
- **Does**: copies `aitools/<platform>` → `<dest-repo>/<platform>`.
- **Note**: `universal/` is maintained in this repo directly and is **not** bootstrapped from `aitools/`.

**Example (seed mobile playbooks only):**

```bash
bash scripts/bootstrap-playbooks-from-aitools.sh \
  --source-repo ~/workspace/repo-with-aitools \
  --dest-repo ~/private/ai-playbook \
  --platform all
```

## After install (client project)

1. Fill in **`CLAUDE.md`** (stack, topography, milestone, learnings).
2. Customize **`ARCHITECTURE.md`** for the real module map.
3. Set build/test commands in **`AGENTS.md`**.
4. **Bootstrap GSD** (if using milestone workflow):

```bash
bash scripts/bootstrap-gsd-workflow.sh \
  --source-repo ~/private/ai-playbook \
  --client-repo ~/projects/my-app \
  --init-gsd --with-do-next --patch-mcp
```

5. Optional local engines:

```bash
npx ruflo@latest init --wizard
claude mcp add ruflo -- npx -y ruflo@latest mcp start
uv tool install graphifyy && graphify build   # or: pip install graphifyy
```

Copy templates from `config/` — see **FRAMEWORK.md**.

## Bootstrap from `aitools/` (legacy mobile seed)

```bash
bash scripts/bootstrap-playbooks-from-aitools.sh \
  --source-repo ~/workspace/template-source \
  --dest-repo ~/private/ai-playbook \
  --platform all
```

This copies `aitools/ios`, `android`, and Flutter variants. **`universal`** is maintained in this repo directly (not bootstrapped from `aitools/`).

## Safety model

- Files install only into the local client checkout
- State under `.git/ai-playbook/<platform>.manifest.tsv`
- Managed paths in `.git/info/exclude` (local, not committed)
- Managed blocks in the client **`.gitignore`** (committed — team-wide): runtime artifacts from `config/client-ai-gitignore-artifacts.txt` plus overlay paths per platform
- Default install policy is additive (`--existing-policy merge`): preserve existing unmanaged paths, install missing paths, and merge missing directory entries
- Strict behavior available with `--existing-policy fail`
- Already-installed clients: `scripts/patch-client-ai-gitignore.sh`

## GSD milestone workflow (Cursor, Claude, Copilot)

**Readiness ladder** — skills and `.gsd/` runtime are installed from shared, not baked into platform trees:

```text
1. Personal hub OR client install-from-shared
   install-personal-agents-hub.sh             → ~/.agents/skills (+ Cursor/Claude bridges)
   — or install-workflow-tools.sh --project   → client .cursor / .claude / .github skills
2. bootstrap-gsd-workflow.sh                  → .gsd/ runtime (required for GSD)
3. $gsd-plan-milestone                        → ROADMAP
4. do next / $do-next-runner                  → custom workflow execution
   — or $gsd-advance-unit                     → pure GSD one unit
```

| Skill | Trigger | Role |
| --- | --- | --- |
| `gsd-plan-milestone` | `$gsd-plan-milestone` | Grill → formalize → ROADMAP |
| `gsd-advance-unit` | `$gsd-advance-unit` | One pure GSD plan/execute unit |
| `do-next` | `do next` / `$do-next` | Custom workflow unit (smoke, gates, slice commits) |
| `do-next-runner` | `$do-next-runner` | Auto-chain do-next units |

| IDE | Personal hub | Client project |
| --- | --- | --- |
| Cursor | `~/.cursor/skills/<skill>` → `~/.agents/skills/<skill>` | `.cursor/skills/<skill>/SKILL.md` |
| Claude | `~/.claude/skills/<skill>` → hub | `.claude/skills/<skill>/` |
| Copilot | *(no personal hub)* | `.github/instructions/<skill>.instructions.md` via `--project --copilot` |

Requires **gsd-workflow** MCP in `.mcp.json` (and `.cursor/mcp.json` for Cursor-only servers). Uses Cursor/Claude billing — not terminal `/gsd` unless you opt in. Canonical templates: **`shared/gsd/`** — see **[shared/gsd/README.md](shared/gsd/README.md)** · **[shared/gsd/ADDING-SKILLS.md](shared/gsd/ADDING-SKILLS.md)**.

## Add tools or patch existing overlays

- New AI IDE / CLI: **[EXTENDING.md](EXTENDING.md)**
- Missing GSD runtime or do-next skills: `scripts/add-do-next-to-overlay.sh` or `scripts/bootstrap-gsd-workflow.sh`
- Add or update SoT skills: **[shared/gsd/ADDING-SKILLS.md](shared/gsd/ADDING-SKILLS.md)**
- Refresh personal hub: `scripts/install-personal-agents-hub.sh` / `scripts/update-personal-skill.sh`
- Refresh client skills from shared: `shared/gsd/scripts/install-workflow-tools.sh --project …`
- Missing `SESSION_WORKFLOW.md`: `scripts/add-session-workflow-to-overlay.sh`
- Missing `.github/copilot-instructions.md`: `scripts/add-copilot-instructions-to-overlay.sh`
- Missing `.cursor/skills`: `scripts/add-cursor-skills-to-overlay.sh`
- Missing hook safety helpers in existing overlay: `scripts/patch-hook-safety-overlay.sh`
- After `ruflo init` overwrote client hooks: `scripts/repair-after-ruflo.sh`
- Client missing AI `.gitignore` blocks: `scripts/patch-client-ai-gitignore.sh`

## Uninstall

```bash
bash scripts/uninstall-client-ai-overlay.sh \
  --client-repo ~/projects/my-api \
  --platform universal
```

## Ownership & privacy

- Playbooks stay out of client git history via exclude rules
- Cloud AI vendors may still read workspace files — configure enterprise privacy separately
- Local graphs (graphify) and vectors (ruflo) remain on disk under `graphify-out/` and `.ruflo/`
