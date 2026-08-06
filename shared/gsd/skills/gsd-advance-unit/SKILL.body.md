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

Call **`playbook_gsd_bridge_health`** then **`playbook_gsd_task_begin`**. Read `T##-PLAN.md`. Implement per `ARCHITECTURE.md` + [platform.md](platform.md). Verify. **`gsd_task_complete`**, then **`playbook_gsd_task_publish`** if `nextStage` is `verify` (abort with **`playbook_gsd_task_abort`** on cancel).

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

- No unsupervised full-milestone `gsd_execute` / terminal `/gsd next` unless user explicitly requests auto/TUI billing
- No `gsd_task_complete` without `playbook_gsd_task_begin` on canonical tasks; publish when `nextStage` is `verify`
- No raw `.gsd/` DB edits when MCP exists
- No `gsd_task_complete` without verification
- No multiple units unless user says "run N steps"

## More detail

- [setup.md](setup.md), [mcp-tools.md](mcp-tools.md), [platform.md](platform.md)
