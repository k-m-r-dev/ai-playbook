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

- `AGENTS.md`, `CLAUDE.md`, `ARCHITECTURE.md`, `SESSION_WORKFLOW.md`
- `.claude/helpers`, `.claude/skills`, `.claude/agents`, `.cursor/rules`, `.cursor/skills`, `.cursor/agents`
- `.github/agents`, `.github/instructions`, `.github/copilot-instructions.md` (universal)
- `.workflow/` (always **copied** — project-owned session state)

GSD milestone skills (`do-next`, `do-next-runner`, `gsd-plan-milestone`, `gsd-advance-unit`) ship in the overlay. **Runtime** `.gsd/` (workflow rules, idea packages, smoke script) is **not** installed by the overlay alone — run **`bootstrap-gsd-workflow.sh`** (see below). Full adoption guide: **[shared/gsd/README.md](shared/gsd/README.md)**.

## Scripts guide (when to use what)

These scripts are for **installing and maintaining overlays in local client repos** (the playbook stays out of the client’s git history).

### `scripts/install-client-ai-overlay.sh`

- **Use when**: first-time install of the overlay into a client repo.
- **Does**: copies/symlinks overlay files into the client repo, writes a manifest to `.git/ai-playbook/<platform>.manifest.tsv`, and adds paths to `.git/info/exclude`.
- **Default mode**: `symlink` (recommended). `.workflow/` is always copied.

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
- **Check only**: `--check` reports `.gsd/`, workflow, and MCP readiness without copying.

**Example (recommended after overlay install):**

```bash
bash scripts/bootstrap-gsd-workflow.sh \
  --source-repo ~/private/ai-playbook \
  --client-repo ~/projects/my-ios-app \
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

### `scripts/sync-gsd-skills-to-overlays.sh`

- **Use when**: you changed templates under `shared/gsd/` and need to refresh all platform overlays (`universal`, `ios`, `android`, `flutter-*`).
- **Does**: re-runs the skill installer across playbook platform folders.

### `shared/gsd/scripts/install-workflow-tools.sh`

- **Use when**: installing or refreshing GSD-family skills without a full overlay reinstall.
- **Modes**: `--project` (client repo) or `--personal` (`~/.cursor/skills`, `~/.claude/skills`); pick IDEs with `--cursor`, `--claude`, `--copilot`.
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
- Installer refuses to overwrite unmanaged existing paths
- Already-installed clients: `scripts/patch-client-ai-gitignore.sh`

## GSD milestone workflow (Cursor, Claude, Copilot)

**Readiness ladder** — skills do not work until `.gsd/` is bootstrapped:

```text
1. install-client-ai-overlay.sh     → skills (symlinked into client)
2. bootstrap-gsd-workflow.sh        → .gsd/ runtime (required)
3. $gsd-plan-milestone              → ROADMAP
4. do next / $do-next-runner        → custom workflow execution
   — or $gsd-advance-unit           → pure GSD one unit
```

| Skill | Trigger | Role |
| --- | --- | --- |
| `gsd-plan-milestone` | `$gsd-plan-milestone` | Grill → formalize → ROADMAP |
| `gsd-advance-unit` | `$gsd-advance-unit` | One pure GSD plan/execute unit |
| `do-next` | `do next` / `$do-next` | Custom workflow unit (smoke, gates, slice commits) |
| `do-next-runner` | `$do-next-runner` | Auto-chain do-next units |

| IDE | Skill paths |
| --- | --- |
| Cursor | `.cursor/skills/<skill>/SKILL.md` |
| Claude | `.claude/skills/<skill>/` (symlinked to Cursor) |
| Copilot | `.github/instructions/<skill>.instructions.md` |

Requires **gsd-workflow** MCP in `.mcp.json` (and `.cursor/mcp.json` for Cursor-only servers). Uses Cursor/Claude billing — not terminal `/gsd` unless you opt in. Canonical templates: **`shared/gsd/`** — see **[shared/gsd/README.md](shared/gsd/README.md)**.

## Add tools or patch existing overlays

- New AI IDE / CLI: **[EXTENDING.md](EXTENDING.md)**
- Missing GSD runtime or do-next skills: `scripts/add-do-next-to-overlay.sh` or `scripts/bootstrap-gsd-workflow.sh`
- Refresh GSD skill templates across platforms: `scripts/sync-gsd-skills-to-overlays.sh`
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
