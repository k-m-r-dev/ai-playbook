# Stage B backlog — playbook-owned workflow (post gsd-pi bridge)

**Status:** backlog / next ai-playbook stage (not implemented in Stage A)  
**Depends on:** Stage A external-executor bridge (`shared/gsd/mcp/gsd-external-executor/`)

## Intent

Remove hard dependency on `@opengsd/gsd-pi` so upgrades, missing claim APIs, or product direction changes cannot block client workflows.

## Deliverables (future milestone)

1. **ADR:** Playbook-owned workflow ledger — goals, non-goals, security model, migration from `.gsd/`.
2. **Spec layer:** [OpenSpec](https://github.com/Fission-AI/OpenSpec) for change proposals (`openspec/changes/...` proposal / specs / design / tasks) as the human-reviewable requirements surface.
3. **Execution layer:** playbook MCP + SQLite (or equivalent) with first-class external-executor APIs (`begin` / `complete` / `publish` / `abort`) designed for Cursor / Claude CLI / oh-my-pi.
4. **Migration:** dual-read adapter (gsd-pi `.gsd` ↔ playbook ledger) so existing clients do not brick; keep reviewable markdown projections.
5. **Security:** local-first, path jail, no secrets in specs, audited tool surface, schema migrations with backups.
6. **Skills:** `ticket-to-plan` / `do-next` become backend-agnostic facades (gsd-pi bridge today → playbook engine tomorrow).

## Design constraint from Stage A

Keep all gsd-pi private imports behind `shared/gsd/mcp/gsd-external-executor/` so Stage B replaces the adapter without rewriting every skill.

## Suggested kickoff

When ready: create a GSD or OpenSpec change for “playbook workflow v1”, grill scope (ledger schema, OpenSpec mapping, security), then implement behind a feature flag with dual-read.
