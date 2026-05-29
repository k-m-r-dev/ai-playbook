---
name: graph-navigate
description: Navigate codebase via graphify-out and graph MCP tools.
---

# Graph navigation

## Ground truth

- `graphify-out/graph.json` — structural graph
- `graphify-out/GRAPH_REPORT.md` — human-readable hubs and clusters
- `graphify-out/manifest.json` — build metadata

## Workflow

1. Identify the seed symbol or path from the user task.
2. Locate the node in `GRAPH_REPORT.md` or via graph MCP (`/graphify` when skill installed).
3. Follow edges to dependencies and dependents before editing.
4. After edits that change public boundaries, note whether `graphify build` is needed.

## Copilot note

Copilot has no graph MCP — use report files and `CLAUDE.md` topography bullets only.
