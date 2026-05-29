# Extending the AI playbook for new tools

Use this guide when adding a fourth (or fifth) AI interface — **Windsurf**, **Codex CLI**, **JetBrains AI**, **Amazon Q**, a custom IDE plugin, or an internal agent runner.

## Design principles

1. **Single ledger** — all tools read root **`CLAUDE.md`** first.
2. **Thin tool surface** — duplicate only routing rules; keep process in `SESSION_WORKFLOW.md` and structure in `ARCHITECTURE.md`.
3. **Local-first navigation** — point tools at `graphify-out/` and ruflo before repo-wide search.
4. **Optional capability** — document what works without MCP (like Copilot).

## Checklist for a new tool

### 1. Discovery entry

| Mechanism | Example location |
|-----------|------------------|
| Always-on rules | `.windsurfrules`, `.cursor/rules/`, `AGENTS.md` |
| Tool-specific instructions | `.github/instructions/`, Copilot-style markdown |
| CLI project file | `CLAUDE.md` pattern for any Anthropic-compatible CLI |

Add a row to **`universal/AGENTS.md`** → Tool mapping table.

### 2. Token budget rules

Copy the body of **`universal/.cursor/rules/05-unified-ai-framework.mdc`** into your tool’s rule file. Required bullets:

- Read `CLAUDE.md` before complex work
- Use graph reports / MCP before wide search
- Update ledger + `.workflow/` at handoff

### 3. MCP servers (if supported)

Add to client `.mcp.json` or tool-specific MCP config:

```json
{
  "mcpServers": {
    "ruflo": {
      "command": "npx",
      "args": ["-y", "ruflo@latest", "mcp", "start"]
    },
    "graphify": {
      "command": "uvx",
      "args": ["graphifyy", "mcp", "start"]
    }
  }
}
```

Adjust package names to match your installed graphify distribution.

### 4. Install script mapping (optional)

To ship files with `install-client-ai-overlay.sh`, add paths under `universal/` (or a new `platform/`) and extend `MAPPINGS` in `scripts/install-client-ai-overlay.sh`:

```bash
".yourtool/rules|.yourtool/rules"
```

Keep optional files behind `[[ -e "$source_path" ]] || continue` so missing files do not break install.

For hook-based integrations, include helper scripts explicitly:

```bash
".claude/helpers|.claude/helpers"
```

This ensures client overlays receive hardened hook handlers (for example, `.claude/helpers/hook-handler.cjs`) and not just skill/rule files.

### 5. Platform validation

Update platform allowlists in:

- `scripts/install-client-ai-overlay.sh`
- `scripts/uninstall-client-ai-overlay.sh`
- `scripts/bootstrap-playbooks-from-aitools.sh`
- `scripts/add-session-workflow-to-overlay.sh`
- `scripts/add-cursor-skills-to-overlay.sh`

### 6. Skills lock

Register Claude-compatible skills in `skills-lock.json` and add `.claude/skills/<name>/SKILL.md`.

### 7. Document in FRAMEWORK.md

Add a subsection under **Tool setup** with install steps and limitations.

### 8. Add migration + verification for safety-critical scripts

If a change affects runtime safety (hooks, command dispatch, session lifecycle):

- add a patch script for already-installed overlays in `scripts/` (manifest-aware); after `ruflo init` in a client repo, `repair-after-ruflo.sh` re-applies helpers with **symlink** mode; `patch-client-ai-gitignore.sh` refreshes committed `.gitignore` blocks from `config/client-ai-gitignore-artifacts.txt`,
- add a verification script (drift check + behavior check),
- run verification locally before shipping:

```bash
bash scripts/verify-hook-safety.sh
```

## Feeding a new agent session

Give any agent this bootstrap prompt:

```markdown
You are working in a repo using the ai-playbook local-first framework.

1. Read CLAUDE.md (ledger), ARCHITECTURE.md (structure), AGENTS.md (commands).
2. Use graphify-out/GRAPH_REPORT.md for navigation — no full-repo scans.
3. Follow SESSION_WORKFLOW.md for .workflow/ session files.
4. Run verification commands from AGENTS.md before claiming done.

Optional MCP: ruflo (memory), graphify (graph), gsd-workflow (milestones).
```

## Example: hypothetical “Acme AI IDE”

```text
universal/
  .acme/
    rules.md          # thin pointer → CLAUDE.md + 05-unified-ai-framework body
  doc/
    acme-setup.md     # MCP URL, auth, feature flags
```

Install mapping: `".acme/rules|.acme/rules"`

## Versioning

When changing shared routing text, update **all** thin surfaces in one commit:

- `.cursor/rules/15-architecture.mdc`
- `.claude/skills/architecture-playbook/SKILL.md`
- `.github/instructions/architecture.instructions.md`

Keep the `# Architecture` / `# Session progress` sections **byte-identical** across the three (see SYNC comments in repo).
