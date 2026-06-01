@_CLAUDE.md

---

## Project Environment & Architecture Context

- **Primary stack**: [e.g. TypeScript/Node, Rust, Python, Kotlin, Go — fill in per project]
- **Project type**: [backend | frontend | mobile | desktop | library | infra | monorepo]
- **Optimization baseline**: openGSD (`@opengsd/gsd-pi`) / graphify / ruflo — enable only what is installed locally
- **Build**: `[e.g. npm run build]`
- **Test**: `[e.g. npm test]`
- **Lint/format**: `[e.g. npm run lint]`

## Active System Topography (pre-computed via graphify)

Regenerate after major structural changes: `graphify build` (or your graphify CLI).

- **Primary hubs**: [e.g. `src/core/router.ts`, `src/services/auth.service.ts`]
- **Shared contracts**: [e.g. `src/types/index.ts`, `proto/`, `openapi.yaml`]
- **Ground-truth map**: `graphify-out/GRAPH_REPORT.md` and `graphify-out/graph.json` — prefer graph traversal over repo-wide search

## Current Milestone Phase & Session State (managed via GSD-Pi)

- **Current milestone**: [e.g. M2 — Secure ingestion layer]
- **Completed this cycle**: [bullet list]
- **Next execution target**: [single concrete next step]
- **GSD artifacts**: `.gsd/` when using gsd-workflow MCP in Cursor; `.planning/` when using terminal GSD — do not mix without intent

## Cross-Session Learnings & Architectural Logic (distilled via ruflo)

Append short, durable bullets after consolidation (`npx ruflo@latest memory consolidate --target local`).

- **[Design decision]** [One sentence — e.g. crypto helpers live only in `src/lib/crypto.ts`]
- **[Tool rule]** Use graphify / ruflo MCP before wide file sweeps or blind `grep` across the tree
- **[Verification]** [Project-specific gates that must pass before merge]

## Session scratch (optional — prefer `.workflow/`)

For active work, use `.workflow/current_session_progress.md` per `SESSION_WORKFLOW.md`. Update the milestone section above only at meaningful handoffs.
