---
name: graphify-obsidian
description: >-
  Build or refresh a graphify knowledge graph and export an Obsidian vault with
  graph.canvas. Wraps `/graphify <path> --obsidian --obsidian-dir <vault>`.
  Use when the user invokes /graphify-obsidian, graphify obsidian, or wants the
  playbook graph synced into a Personal Brain / Obsidian vault.
disable-model-invocation: true
---

# /graphify-obsidian

Export this repo's **graphify** graph into an Obsidian vault. Equivalent to:

```text
/graphify <scan-path> --obsidian --obsidian-dir <obsidian-vault-dir>
```

## Invocation

```text
/graphify-obsidian <obsidian-vault-dir>
/graphify-obsidian <obsidian-vault-dir> <scan-path>
/graphify-obsidian --obsidian-dir <obsidian-vault-dir> [--path <scan-path>]
```

| Argument | Required | Default |
|----------|----------|---------|
| Obsidian vault directory | Yes | — |
| Scan path (repo root to graph) | No | `.` (current working directory) |

Expand `~` in paths. Resolve to absolute paths before running commands.

**Examples:**

```text
/graphify-obsidian ~/Workspace/Obsidian/Personal/Personal-Brain
/graphify-obsidian ~/Workspace/Obsidian/Personal/Personal-Brain .
/graphify-obsidian --obsidian-dir ~/vaults/brain --path ./universal
```

Pass through optional graphify flags if the user includes them: `--update`, `--mode deep`, `--no-viz`, `--cluster-only` (see graphify skill Usage).

## Prerequisites

- **graphify** installed (`uv tool install graphifyy` or `pip install graphifyy`)
- Read **`~/.claude/skills/graphify/SKILL.md`** (or the graphify skill bundled with the environment) for the full pipeline, honesty rules, and query/path subcommands

## What you must do

1. **Parse** `OBSIDIAN_DIR` and `SCAN_PATH` from the user message.

2. **Interpreter guard** — ensure `graphify-out/.graphify_python` exists under `SCAN_PATH` (see graphify skill “Interpreter guard”).

3. **Fast path (incremental)** — from `SCAN_PATH`, if `graphify-out/graph.json` exists:

   ```bash
   cd SCAN_PATH
   $(cat graphify-out/.graphify_python) -c "
   from graphify.detect import detect_incremental
   from pathlib import Path
   r = detect_incremental(Path('.'))
   print(r.get('new_total', 0), len(r.get('deleted_files', [])))
   "
   ```

   If **new_total is 0** and **no deleted files**, skip Steps 1–5 of the full graphify pipeline. Run only:

   ```bash
   cd SCAN_PATH
   graphify export obsidian --dir OBSIDIAN_DIR
   graphify export html   # unless user passed --no-viz
   ```

   Then report vault path, note count, and `graph.canvas` location. Paste God Nodes / Surprising Connections / Suggested Questions from `graphify-out/GRAPH_REPORT.md` if the report exists.

4. **Full or update pipeline** — otherwise follow **`graphify/SKILL.md`** on `SCAN_PATH` with these **fixed** options:

   - Always set: `--obsidian --obsidian-dir OBSIDIAN_DIR`
   - If user asked for incremental: `--update` (graphify update flow, then Step 6 obsidian export)
   - Forward any other flags the user supplied

   At **Step 6**, Obsidian export is mandatory:

   ```bash
   cd SCAN_PATH
   graphify export obsidian --dir OBSIDIAN_DIR
   graphify export html   # unless --no-viz
   ```

5. **Completion message** — tell the user:

   ```text
   Obsidian vault: OBSIDIAN_DIR
   Canvas: OBSIDIAN_DIR/graph.canvas
   Local graph: SCAN_PATH/graphify-out/ (graph.html, GRAPH_REPORT.md, graph.json)
   ```

   Open the vault directory in Obsidian as a vault (not a single subfolder).

## Copilot / no-agent note

Copilot cannot run this skill. Use `graphify export obsidian --dir …` manually after `graphify build` in the repo root.
