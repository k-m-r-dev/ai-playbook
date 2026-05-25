---
name: gsd-pi-cursor
description: >-
  Runs GSD Pi (gsd-pi) in Cursor — grill the user on a new feature, then
  persist CONTEXT, requirements, and ROADMAP via the gsd-workflow MCP server.
  Use when the user wants GSD milestone planning in Cursor, says "grill me then
  plan a milestone", mentions gsd-pi, gsd-workflow MCP, or planning
  the next milestone without using the gsd terminal TUI.
---

# GSD Pi in Cursor

Orchestrate **discuss → formalize → plan** using **Cursor's model** plus **`gsd-workflow` MCP**. Use **`.gsd/`** (gsd-pi v3), not `.planning/`.

## Template context

This skill ships with the **Flutter Riverpod** ai-playbook overlay. Read [platform.md](platform.md) for module paths, doc read order, and verification commands.

## Invocation

- `$gsd-pi-cursor` + feature description
- "Grill me and plan a milestone for …"

## Phases

0. **Orient** — `gsd_milestone_status`, `gsd_milestone_generate_id` if needed  
1. **Grill** — one question per message (Recommendation + Alternatives); no impl code  
2. **Formalize** — `gsd_requirement_save` → `gsd_decision_save` → `gsd_summary_save` (CONTEXT)  
3. **Plan** — `gsd_plan_milestone` → `M###-ROADMAP.md`  
4. **Verify** — `.gsd/milestones/M###/` artifacts; update `.workflow/progress_tracker.md`  
5. **Handoff** — **`$gsd-next-cursor`** for Cursor-billed step execution; optional: terminal `gsd` + `/gsd auto` only if user wants gsd-pi / Copilot billing

## Prerequisites

- `.mcp.json` has `gsd-workflow` with `GSD_WORKFLOW_PROJECT_ROOT` = client repo root ([setup.md](setup.md))
- `.gsd/` exists (`gsd` once in repo if missing)
- Read `AGENTS.md`, `ARCHITECTURE.md`, `.workflow/progress_tracker.md` first
- Read MCP tool schemas before calling `gsd_*`

## Grill rules (inline)

One question at a time. Codebase search before asking (use [platform.md](platform.md) module map). Close when scope, users, done criteria, risks, integrations, and out-of-scope are clear. Wrap-up: "Lock context and move to formal GSD artifacts?" — only then Phase 2–3.

Pair with **grill-me** discipline when the user asks to be stress-tested.

## Anti-patterns

No parallel questions; no chat-only plans (use MCP); no `gsd_execute` without noting CLI model billing; no raw `.gsd` edits when MCP tools exist.

## More detail

- [setup.md](setup.md) — MCP install (placeholders)
- [mcp-tools.md](mcp-tools.md) — tool list
- [platform.md](platform.md) — Flutter Riverpod modules and docs
