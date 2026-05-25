---
name: gsd-next-cursor
description: >-
  Advance one GSD Pi unit in Cursor using gsd-workflow MCP for state and Cursor
  for planning/implementation. Use after a milestone ROADMAP exists ($gsd-pi-cursor
  or prior formalize). Says "gsd next", "run next GSD step", "execute M005 S01".
  Cursor billing only — never gsd_execute or terminal /gsd next unless user explicitly
  wants Copilot.
---

# GSD Next in Cursor

Step-mode: **one unit per invocation**; state in **`.gsd/`** (gsd-pi v3); **MCP** for persistence; **Cursor** for planning and implementation.

## Template context

This skill ships with the **Flutter Riverpod** ai-playbook overlay. Read [platform.md](platform.md) for verify commands and module paths.

## Invocation

- `$gsd-next-cursor`
- "Run GSD next" / "gsd next" (in Cursor — not the terminal TUI)
- Optional scope: `$gsd-next-cursor M005` or `M005 S01`

## Prerequisites

- `.mcp.json` has `gsd-workflow` with `GSD_WORKFLOW_PROJECT_ROOT` = client repo root ([setup.md](setup.md))
- `.gsd/` exists (`gsd` once in repo if missing)
- Active milestone has `M###-ROADMAP.md` under `.gsd/milestones/M###/`
- Read MCP tool schemas before calling `gsd_*`
- Read `ARCHITECTURE.md` before any implementation task

## Relationship to gsd-pi-cursor

| Skill | Phase |
| --- | --- |
| `gsd-pi-cursor` | Discuss → formalize → `gsd_plan_milestone` → ROADMAP |
| `gsd-next-cursor` | Plan slice → execute tasks → complete slice / milestone |

Start this skill only after a ROADMAP exists (from `$gsd-pi-cursor` or equivalent formalize).

## Phases (single unit per chat turn)

### 0. Orient (no gsd-pi LLM cost)

Call `gsd_progress` with `projectDir` = client repo root; optionally `gsd_milestone_status`.

Show the user: active milestone / slice / task, `phase`, `nextAction`, blockers.

### 1. Route

Map `nextAction` / `phase` to **exactly one** action below. If the user passed `M###` or `S##`, respect that scope.

Use `gsd_progress.nextAction` as the primary signal. Examples:

- "Slice S01 has no DB tasks. Plan slice tasks before execution." → **2a Plan slice**
- Active task T01 → **2b Execute task**
- All tasks done, slice still open → **2c Complete slice**

### 2a. Plan slice

**When:** no DB tasks for the active slice, or `phase` is `plan`, or `nextAction` says plan slice.

1. Read `.gsd/milestones/M###/M###-ROADMAP.md` and `.gsd/milestones/M###/M###-CONTEXT.md`
2. Read slice goal, demo, and success criteria from the ROADMAP
3. Break into tasks (T01, T02, …) with files and verify steps — **Cursor plans**
4. Call MCP `gsd_plan_slice` with `milestoneId`, `sliceId`, `goal`, `tasks[]` (read tool schema first)
5. Do **not** implement product code in this unit

### 2b. Execute task

**When:** a pending task exists and `phase` is execute.

1. Read `.gsd/milestones/M###/slices/S##/tasks/T##-PLAN.md` (or path from MCP result)
2. Implement in the repo per `ARCHITECTURE.md` and [platform.md](platform.md)
3. Run verification from [platform.md](platform.md) (e.g. `flutter analyze`, `flutter test`)
4. Call `gsd_task_complete` when the task is done (read schema)
5. **One task** per `$gsd-next-cursor` unless the user asks for more

### 2c. Complete slice

**When:** all tasks in the slice are done.

1. Call `gsd_slice_complete` (read schema)
2. Update `.workflow/progress_tracker.md` if the milestone shipped user-visible work

### 2d. Milestone gate

When the ROADMAP documents dependencies (e.g. M006 depends on M005), do not start downstream production integration until the prerequisite milestone shows complete in `gsd_milestone_status` (or document fixture-only work explicitly).

### 3. Report

Summarize: unit run, files changed, verification output, what `gsd_progress` will show next.

Tell the user: "Say `$gsd-next-cursor` again for the next unit."

## Depth verification

If `gsd_summary_save` CONTEXT is blocked, confirm via MCP `ask_user_questions` with the first option exactly `Yes, you got it (Recommended)` — same as `gsd-pi-cursor`. Rare during execute; use only when required.

## Anti-patterns

- No `gsd_execute` or terminal `/gsd next` unless the user explicitly requests Copilot / gsd-pi billing
- No Codex `$gsd-next` or `.planning/`
- No raw edits to `.gsd/` DB files when MCP tools exist
- No multiple units in one invocation unless the user says "run N steps"
- No `gsd_task_complete` without running verification first

## More detail

- [setup.md](setup.md) — MCP install (placeholders)
- [mcp-tools.md](mcp-tools.md) — execute-phase tool list
- [platform.md](platform.md) — Flutter Riverpod modules and verify commands

## Client rollout

After merging ai-playbook, refresh the client overlay:

```bash
bash scripts/add-cursor-skills-to-overlay.sh \
  --source-repo <path-to-ai-playbook> \
  --client-repo <path-to-client> \
  --platform flutter-riverpod
```

Or reinstall the full overlay. Skill path: `.cursor/skills/gsd-next-cursor/`.
