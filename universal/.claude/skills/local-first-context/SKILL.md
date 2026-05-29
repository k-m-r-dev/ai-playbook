---
name: local-first-context
description: Use graphify and ruflo before broad repo search; minimize token burn.
---

# Local-first context

Use this skill when exploring an unfamiliar area, finding callers, or planning multi-file work.

## Order of operations

1. Read **`CLAUDE.md`** — topography hubs and learnings.
2. Open **`graphify-out/GRAPH_REPORT.md`** or query graph MCP if available.
3. Search ruflo memory: `npx ruflo@latest memory search --query "<topic>" --namespace patterns`
4. Read **specific files** on the graph path — not entire directories.
5. Use targeted grep only when graphs and memory lack the answer.

## When to rebuild graphs

- After large refactors or new top-level modules: `graphify build`
- Hooks may run `graphify check-update --silent` on Bash (Claude Code)

## Do not

- Paste whole `node_modules`, build output, or `graphify-out/cache` into context
- Re-read the full repo tree each session when `CLAUDE.md` + graph exist
