# GSD Advance Unit

**One GSD unit per invocation**; state in **`.gsd/`**; **MCP** for persistence; chat for planning and implementation.

For custom workflow (smoke, Q3/Q4, slice commits), use **`do next`** instead.

<!-- SYNC: shared/gsd/skills/gsd-advance-unit/SKILL.body.md -->

## GSD bootstrap gate

<!-- include: skills/_includes/GSD_BOOTSTRAP_GATE.md -->

Requires active milestone with `M###-ROADMAP.md`. If none: **STOP** → `$gsd-plan-milestone`.

## Template context

Read [platform.md](platform.md) for verify commands and module paths.

## Invocation

- **`$gsd-advance-unit`**
- "Run GSD next" / "gsd next" (in chat — not terminal TUI unless user requests)
- Optional scope: `M005` or `M005 S01`

## Relationship to gsd-plan-milestone

| Skill | Phase |
| --- | --- |
| `gsd-plan-milestone` | Discuss → formalize → ROADMAP |
| `gsd-advance-unit` | Plan slice → execute task → complete slice |

## Phases (single unit)

### 0. Orient

`gsd_progress` + optional `gsd_milestone_status`. Show milestone/slice/task, phase, nextAction, blockers.

### 1. Route

One of 2a Plan slice / 2b Execute / 2c Complete slice / 2d Milestone gate per `nextAction`.

### 2a. Plan slice

Read ROADMAP + CONTEXT. Plan tasks. **`gsd_plan_slice`**. No product code.

### 2b. Execute task

Read `T##-PLAN.md`. Implement per `ARCHITECTURE.md` + [platform.md](platform.md). Verify. **`gsd_task_complete`**.

### 2c. Complete slice

**`gsd_slice_complete`**. Update `.workflow/progress_tracker.md` if applicable.

### 3. Report

Summarize unit. Say **`$gsd-advance-unit`** for next unit.

## Anti-patterns

- No `gsd_execute` / terminal `/gsd next` unless user explicitly requests TUI billing
- No raw `.gsd/` DB edits when MCP exists
- No `gsd_task_complete` without verification
- No multiple units unless user says "run N steps"

## More detail

- [setup.md](setup.md), [mcp-tools.md](mcp-tools.md), [platform.md](platform.md)
