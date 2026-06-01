@_CLAUDE.md

---

## Project Environment & Architecture Context

- **Primary stack**: Flutter / Dart / BLoC / GetIt-Injectable
- **Project type**: mobile
- **Optimization baseline**: openGSD / graphify / ruflo — enable only what is installed locally
- **Build**: `[e.g. npm run build]`
- **Test**: `[e.g. npm test]`
- **Lint/format**: `[e.g. npm run lint]`

## Active System Topography (pre-computed via graphify)

Regenerate after major structural changes: `graphify build` (or `graphify update .`).

- **Primary hubs**: [e.g. main entry modules]
- **Shared contracts**: [e.g. types, API schemas]
- **Ground-truth map**: `graphify-out/GRAPH_REPORT.md` and `graphify-out/graph.json` — prefer graph traversal over repo-wide search

## Current Milestone Phase & Session State (managed via GSD-Pi)

- **Current milestone**: [e.g. M2 — feature name]
- **Completed this cycle**: [bullet list]
- **Next execution target**: [single concrete next step]
- **GSD artifacts**: `.gsd/` when using gsd-workflow MCP in Cursor; `.planning/` when using terminal GSD — do not mix without intent

## Cross-Session Learnings & Architectural Logic (distilled via ruflo)

Append short, durable bullets after consolidation (`npx ruflo@latest memory consolidate --target local` when ruflo is installed).

- **[Tool rule]** Use graphify / ruflo MCP before wide file sweeps or blind `grep` across the tree

## Session scratch (optional — prefer `.workflow/`)

For active work, use `.workflow/current_session_progress.md` per `SESSION_WORKFLOW.md`. Update the milestone section above only at meaningful handoffs.
