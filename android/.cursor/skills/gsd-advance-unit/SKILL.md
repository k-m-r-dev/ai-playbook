---
name: gsd-advance-unit
description: >-
  Advance one pure GSD unit via gsd-workflow MCP (plan slice, execute task,
  complete slice). Triggers: $gsd-advance-unit, gsd next. Requires .gsd/ and active
  milestone. For custom gates use do-next.
---

# GSD Advance Unit

**One GSD unit per invocation**; state in **`.gsd/`**; **MCP** for persistence; chat for planning and implementation.

For custom workflow (smoke, Q3/Q4, slice commits), use **`do next`** instead.

<!-- SYNC: shared/gsd/skills/gsd-advance-unit/SKILL.body.md -->

## GSD bootstrap gate

## GSD bootstrap gate (run before anything else)

If `.gsd/` is missing OR `gsd-workflow` MCP is not configured:

- **STOP immediately**
- Tell the user: *"GSD is not installed in this repo. Bootstrap first:"*

  ```bash
  bootstrap-gsd-workflow.sh --client-repo . --init-gsd --patch-mcp --with-do-next
  ```

  (From ai-playbook: `bash scripts/bootstrap-gsd-workflow.sh --source-repo <ai-playbook> --client-repo . --init-gsd --patch-mcp --with-do-next`)

- Do **not** implement product code or guess next tasks from markdown alone.

If `.gsd/` exists but no active milestone (execution skills only: `do-next`, `do-next-runner`, `gsd-advance-unit`):

- **STOP**
- Tell the user: *"Plan a milestone first: `$gsd-plan-milestone`"*

## Skill path resolution

| Platform | Planning | Pure GSD step | Custom step | Auto-chain |
| --- | --- | --- | --- | --- |
| Cursor | `.cursor/skills/gsd-plan-milestone/SKILL.md` | `.cursor/skills/gsd-advance-unit/SKILL.md` | `.cursor/skills/do-next/SKILL.md` | `.cursor/skills/do-next-runner/SKILL.md` |
| Claude | `.claude/skills/gsd-plan-milestone/SKILL.md` | `.claude/skills/gsd-advance-unit/SKILL.md` | `.claude/skills/do-next/SKILL.md` | `.claude/skills/do-next-runner/SKILL.md` |
| Copilot | `.github/instructions/gsd-plan-milestone.instructions.md` | `.github/instructions/gsd-advance-unit.instructions.md` | `.github/instructions/do-next.instructions.md` | `.github/instructions/do-next-runner.instructions.md` |

## MCP prerequisites

- **`.mcp.json`** at repo root with `gsd-workflow` and `GSD_WORKFLOW_PROJECT_ROOT` = repo root
- **Cursor:** also configure `.cursor/mcp.json` if using Cursor-only MCP servers
- Read MCP tool schemas before `gsd_*` calls
- Smoke script (do-next family): `.workflow/scripts/gsd-smoke.sh`


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

## Compat projection drift (self-heal)

If `gsd-smoke` `plan-coherence` FAILs `md=0 db=N files=0 DRIFT` for every slice while the rendered `NN-MM-PLAN.md` files exist with tasks and `grep -c "<M###>/S0" .gsd/.compat.json` is `0`, it is a stale projection INDEX (gsd-pi `gsd_plan_slice` does not record slice-PLAN projections), not a content conflict. Self-heal, then re-smoke:

```bash
node .workflow/scripts/gsd-reproject-compat.mjs <M###>
.workflow/scripts/gsd-smoke.sh --milestone <M###>
```

Index-only, additive, via gsd-pi's compat-marker API — never hand-edit `.compat.json`. Full guard + inline fallback: **do-next skill § 0.5.1 Compat projection drift**.

## Anti-patterns

- No `gsd_execute` / terminal `/gsd next` unless user explicitly requests TUI billing
- No raw `.gsd/` DB edits when MCP exists
- No `gsd_task_complete` without verification
- No multiple units unless user says "run N steps"

## More detail

- [setup.md](setup.md), [mcp-tools.md](mcp-tools.md), [platform.md](platform.md)
