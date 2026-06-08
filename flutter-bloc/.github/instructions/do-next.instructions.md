---
applyTo: "**"
---

<!-- SYNC: shared/gsd/idea/do-next/templates/SKILL.body.md -->

# Do Next

**One unit per invocation.** GSD MCP for state persistence, plus milestone workflow (Task Handoff Gate, delivery profile, slice commits).

For **pure GSD** routing without custom gates or commit rules, use **`$gsd-advance-unit`**.

<!-- SYNC: shared/gsd/idea/do-next/templates/SKILL.body.md -->

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


## Invocation

- **`do next`** — default; runs smoke (step 0.5)
- **`$do-next`** — same
- **`do next --skip-smoke`** — skip step 0.5; see [Skip smoke](#skip-smoke)
- Optional scope: `M001`, `S01`, `S01 T03`

## Read order (every invocation)

1. `.gsd/workflow/milestone-workflow.md`
2. `.gsd/DELIVERY-PROFILE.md`
3. `.gsd/DECISIONS.md` — when scope is ambiguous
4. Active `T##-PLAN.md`
5. `ARCHITECTURE.md` — before implementation
6. Platform `platform.md` in the do-next skill folder — verification commands

Also read `AGENTS.md` → *Milestone / Multi-PR Work*.

## Phases (single unit per chat turn)

### 0. Orient

Call **`gsd_progress`** (+ optionally **`gsd_milestone_status`**). Show milestone / slice / task, phase, nextAction, blockers.

If MCP unavailable, stop — do not guess from markdown alone.

If no active milestone, stop — direct user to **`$gsd-plan-milestone`**.

### 0.5. Plan coherence gate

**Default:** run smoke every `do next`.

**Skip when** the user message includes **`--skip-smoke`**. Do not skip silently.

```bash
.workflow/scripts/gsd-smoke.sh
```

**On FAIL:** STOP → gap report per slice → ask user: **markdown → DB** or **DB → markdown** → wait. No auto-sync.

### 1. Route

| Signal | Action |
| --- | --- |
| `evaluating-gates` | **2e Evaluate gates** |
| Plan slice | **2a Plan slice** |
| `execute` / `executing` + pending task | **2b Execute task** |
| All slice tasks done | **2c Complete slice** |
| Milestone dependency | **2d Milestone gate** |

### 2e. Evaluate quality gates (Q3, Q4)

1. Read `S##-PLAN.md` + `DECISIONS.md`
2. **`gsd_save_gate_result`** per gate
3. `.workflow/scripts/gsd-smoke.sh --rebuild-state`
4. Re-run **`gsd_progress`**
5. No product code until gates cleared

### 2a. Plan slice

1. Read roadmap + context
2. Plan tasks (markdown plans are input)
3. **`gsd_plan_slice`**
4. No product code

### 2b. Execute task

1. Read `T##-PLAN.md`
2. Implement per `ARCHITECTURE.md`
3. Verify per `.gsd/DELIVERY-PROFILE.md` and skill **`platform.md`**
4. **`gsd_task_complete`** after verification passes
5. **Task Handoff Gate:** pause for next `do next`
6. **No commit** when `commit_cadence: slice`

### 2c. Complete slice

1. Slice-level verification
2. **`gsd_slice_complete`**
3. One commit per DELIVERY-PROFILE: `feat({scope-slug}): {summary}`
4. **No push** without explicit approval
5. Update `.workflow/progress_tracker.md` if applicable

### 2d. Milestone gate

Wait for prerequisite milestone in **`gsd_milestone_status`**.

### 3. Report

Unit summary, verification, smoke status, next `gsd_progress` state.

End with: **Say `do next` for the next unit.**

## Skip smoke

User opt-out: **`do next --skip-smoke`**.

Still run step **0. Orient** via **`gsd_progress`**. Report `SKIPPED (--skip-smoke)` in summary.

Do not skip on: new session, slice boundary, after gate saves / plan edits, branch switch, previous FAIL.

## Anti-patterns

- No auto-sync on markdown/DB drift
- No raw `.gsd/gsd.db` or `.gsd/STATE.md` edits
- No push without approval
- No multiple units unless user says "run N steps"
- No `gsd_execute` / terminal `/gsd next` as backend

## vs gsd-advance-unit

| | `do-next` | `gsd-advance-unit` |
| --- | --- | --- |
| Coherence smoke | required (skippable) | optional |
| Q3/Q4 + STATE rebuild | yes | GSD phase only |
| Slice commit rules | DELIVERY-PROFILE | GSD defaults |
| Task Handoff Gate | pause every task | one GSD unit |
