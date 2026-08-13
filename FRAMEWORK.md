# Unified local-first AI engineering framework

This repository is a **private playbook template** that stitches three dominant interfaces — **VS Code Copilot**, **Cursor**, and **Claude Code CLI** — to three local engines — **@opengsd/gsd-pi**, **graphify**, and **ruflo** — so agents stop re-parsing the whole workspace every session.

## Goals

- **70–95% lower token burn** on structural exploration (graph + ledger vs raw tree walks)
- **Cross-session relevance** via `CLAUDE.md` + `.workflow/` + ruflo HNSW memory
- **Local-first** — graphs and vectors on disk; optional enterprise privacy for cloud tools

## Architecture

```mermaid
graph TD
    subgraph Frontends [Development interfaces]
        VS[VS Code Copilot]
        CR[Cursor IDE]
        CC[Claude Code CLI]
    end

    subgraph LocalCache [Unified context ledger]
        CL[CLAUDE.md]
    end

    subgraph Engines [Optimization and memory]
        GSD[opengsd/gsd-pi]
        GF[graphify]
        RF[ruflo MCP]
    end

    subgraph Storage [Local disk]
        DB_G[graphify-out/graph.json]
        DB_R[.ruflo/]
    end

    VS --> CL
    CR --> CL
    CC --> CL
    CR -.-> GF
    CC --> RF
    CC --> GF
    GF --> DB_G
    RF --> DB_R
    GSD --> CL
```

## Repository layout

```text
ai-playbook/
  universal/          # Default overlay — any stack
  ios/ android/       # Mobile-native depth
  flutter-*/          # Flutter + state-management variants
  scripts/            # Install overlay into client repos
  config/             # MCP + hook templates
  shared/gsd/          # GSD workflow skills + personal-skills.manifest
  FRAMEWORK.md        # This document
  EXTENDING.md        # Add new AI tools
```

## Core ledger: `CLAUDE.md`

Every client project gets root **`CLAUDE.md`** (committed wrapper) and **`_CLAUDE.md`** (playbook symlink). The wrapper includes `@_CLAUDE.md` plus four live ledger sections:

1. **Project environment** — stack, build/test commands, enabled engines
2. **Active topography** — graphify hubs (paths into the codebase)
3. **Milestone state** — GSD-Pi / `.gsd/` progress
4. **Cross-session learnings** — durable decisions (ruflo-distilled)

The same **wrapper + `_` template** pattern applies to **`AGENTS.md`**, **`ARCHITECTURE.md`**, and **`SESSION_WORKFLOW.md`**:

| Committed wrapper | Playbook symlink | Purpose |
|-------------------|------------------|---------|
| `AGENTS.md` | `_AGENTS.md` | `@_AGENTS.md` + continual-learning sections |
| `CLAUDE.md` | `_CLAUDE.md` | `@_CLAUDE.md` + mutable ledger |
| `ARCHITECTURE.md` | `_ARCHITECTURE.md` | `@_ARCHITECTURE.md` + `## Project Layout` |
| `SESSION_WORKFLOW.md` | `_SESSION_WORKFLOW.md` | `@_SESSION_WORKFLOW.md` only |

Playbook templates (`_*`) stay out of client git; wrappers are committed. Cursor **continual-learning** writes only to `AGENTS.md` — never mutating ai-playbook symlinks.

All frontends read **`CLAUDE.md`** first. Do not duplicate long architecture prose there — use **`ARCHITECTURE.md`** (wrapper).

## Day-to-day loop

```text
[1 Session start]  → [2 Milestone check] → [3 Code execution]
        │                                      │
        ▼                                      ▼
 Ingest CLAUDE.md + graphs          GSD review / graph traverse
        │                                      │
        ▼                                      ▼
[4 Session end]  ←  [5 State sync]  ←  ruflo consolidate + graphify refresh
```

| Step | Action |
|------|--------|
| 1 | Open tool; hooks/MCP load local state (no cloud parse yet) |
| 2 | `gsd review` or skim milestone section in `CLAUDE.md` |
| 3 | Edit via graph-targeted reads; run build/test from `AGENTS.md` |
| 4 | Archive `.workflow/`; update `CLAUDE.md` learnings |
| 5 | `npx ruflo@latest memory consolidate --target local`; commit code + ledger |

## Tool setup

### Claude Code (ruflo + graphify hooks)

```bash
npx ruflo@latest init --wizard
claude mcp add ruflo -- npx -y ruflo@latest mcp start

# graphify CLI (pick one)
uv tool install graphifyy          # recommended on macOS/Linux — puts binary in ~/.local/bin
# pip install graphifyy            # alternative if you prefer pip/venv

graphify build                     # requires ~/.local/bin on PATH when using uv tool install
```

Merge `config/claude.settings.local.example.json` into `.claude/settings.local.json` (gitignored). Project `.mcp.json` can include ruflo — see `config/mcp.template.json`.

### Cursor (rules + MCP)

1. Install overlay: `--platform universal`
2. **Settings → MCP**: add graphify server — e.g. `graphify mcp start` if `uv tool install graphifyy` is on your PATH, or `uvx graphifyy mcp start` without a global install
3. Enable **gsd-workflow** MCP for GSD skills under `.cursor/skills/`
4. **Bootstrap GSD** in client repos: `bootstrap-gsd-workflow.sh --init-gsd --patch-mcp --with-do-next` (or use **`configure-client-project`** skill from ai-playbook for guided setup + delivery-profile interview)
5. **Preflight** (read-only): `scripts/configure-client-check.sh --source-repo <playbook> --client-repo <client>`
6. Rules in `.cursor/rules/` enforce ledger + token budget

### GSD milestone execution (after bootstrap)

| Skill | Trigger | Role |
| --- | --- | --- |
| `gsd-plan-milestone` | `$gsd-plan-milestone` | Plan ROADMAP |
| `gsd-advance-unit` | `$gsd-advance-unit` | One pure GSD unit |
| `do-next` | `do next` | Custom workflow unit (smoke, gates, slice commits) |
| `do-next-runner` | `$do-next-runner` | Auto-chain do-next units |

Canonical templates: `shared/gsd/`. None work without `.gsd/` bootstrapped.

Legacy `.cursorrules` at repo root is optional; prefer `.cursor/rules/`.

### VS Code Copilot (markdown only)

- `.github/copilot-instructions.md` — parsing + ledger rules
- `.github/instructions/*.instructions.md` — thin routing to `ARCHITECTURE.md` / `SESSION_WORKFLOW.md`
- No local MCP — agents use `graphify-out/GRAPH_REPORT.md` as structural ground truth

## Personal Agents Hub

The **Personal Agents Hub** replaces per-platform skill copies with a single
assembly point at `~/.agents/skills`. Symlink bridges connect the hub to
`~/.cursor/skills` and `~/.claude/skills`.

Guide: **[shared/gsd/ADDING-SKILLS.md](shared/gsd/ADDING-SKILLS.md)**.

```bash
# Install all skills from the manifest
bash scripts/install-personal-agents-hub.sh

# Update one skill after editing shared/gsd/
bash scripts/update-personal-skill.sh graphify-obsidian

# Preview without changes
bash scripts/install-personal-agents-hub.sh --dry-run
```

The canonical skill list lives in `shared/gsd/personal-skills.manifest`.
Platform overlays (`universal/`, `ios/`, etc.) no longer carry copies of
hub-managed skills. The lockfile `~/.playbook-hub-lock.json` (home directory,
not under `~/.agents/skills`) tracks versions.

| Skill | Type | Source |
|-------|------|--------|
| `do-next` | assembled | `idea/do-next/templates` |
| `do-next-runner` | assembled | `idea/do-next-runner/templates` |
| `gsd-plan-milestone` | assembled | `skills/gsd-plan-milestone` |
| `gsd-advance-unit` | assembled | `skills/gsd-advance-unit` |
| `ticket-to-plan` | flat | `skills/ticket-to-plan` |
| `verified-pr-review` | flat | `skills/verified-pr-review` |
| `graphify-obsidian` | flat | `skills/graphify-obsidian` |

## Install into a client repo

```bash
bash scripts/install-client-ai-overlay.sh \
  --source-repo ~/private/ai-playbook \
  --client-repo ~/projects/my-api \
  --platform universal \
  --mode symlink \
  --existing-policy merge
```

Managed playbook templates (`_*` root files) are excluded from client git via `.git/info/exclude`. **Committed wrappers** (`AGENTS.md`, `CLAUDE.md`, etc.) are tracked in the client repo.

## Choosing a platform overlay

| Project | Platform flag |
|---------|----------------|
| Generic backend/frontend/desktop/infra | `universal` |
| Native iOS | `ios` |
| Native Android | `android` |
| Flutter + Riverpod | `flutter-riverpod` |
| Flutter + Bloc | `flutter-bloc` |

You may start with `universal` and add mobile playbooks later; avoid installing two overlays on the same client without uninstalling first.

## Privacy

- Playbook template symlinks (`_*` root files) stay out of client git (exclude list); committed wrappers are tracked.
- Vendors may still process file contents if their product sends workspace context to the cloud — configure enterprise settings separately.

## Migrating legacy overlays

If an existing client repo still has symlinked `AGENTS.md` (pre-wrapper model), run:

```bash
bash scripts/migrate-overlay-wrappers.sh \
  --source-repo ~/private/ai-playbook \
  --client-repo ~/projects/my-app \
  --platform flutter-riverpod
```

## Further reading

- **`EXTENDING.md`** — register Windsurf, Codex, JetBrains, custom MCP
- **`shared/gsd/ADDING-SKILLS.md`** — add / update hub-managed skills
- **`universal/README.md`** — per-overlay file map
- Mobile-specific: `ios/README.md`, `android/README.md`, etc.
