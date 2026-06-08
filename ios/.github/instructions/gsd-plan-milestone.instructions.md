---
applyTo: "**"
---

<!-- SYNC: shared/gsd/skills/gsd-plan-milestone/SKILL.body.md -->

# GSD Plan Milestone

Orchestrate **discuss → formalize → plan** using **chat + `gsd-workflow` MCP**. Use **`.gsd/`** (gsd-pi v3), not `.planning/`.

<!-- SYNC: shared/gsd/skills/gsd-plan-milestone/SKILL.body.md -->

## GSD bootstrap gate

If `.gsd/` missing: run `gsd` once in repo root OR `bootstrap-gsd-workflow.sh --init-gsd --patch-mcp` before other phases.

If `gsd-workflow` MCP unavailable: **STOP** — configure `.mcp.json` per [setup.md](setup.md).

## Template context

Read [platform.md](platform.md) for module paths, doc read order, and verification commands.

## Invocation

- **`$gsd-plan-milestone`** + feature description
- "Grill me and plan a milestone for …"

## Phases

0. **Orient** — `gsd_milestone_status`, `gsd_milestone_generate_id` if needed
1. **Grill** — one question per message; no impl code
2. **Formalize** — `gsd_requirement_save` → `gsd_decision_save` → `gsd_summary_save`
3. **Plan** — `gsd_plan_milestone` → `M###-ROADMAP.md`
4. **Verify** — `.gsd/milestones/M###/` artifacts; update `.workflow/progress_tracker.md`
5. **Handoff** — **`$gsd-advance-unit`** or **`do next`** for execution; terminal `gsd` only if user wants TUI billing

## Grill rules

One question at a time. Codebase search before asking. Close when scope, users, done criteria, risks, integrations, and out-of-scope are clear.

## Anti-patterns

No parallel questions; no chat-only plans (use MCP); no `gsd_execute` without noting CLI billing; no raw `.gsd` edits when MCP exists.

## More detail

- [setup.md](setup.md) — MCP install
- [mcp-tools.md](mcp-tools.md) — tool list
- [platform.md](platform.md) — stack-specific paths
