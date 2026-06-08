# Do-Next Runner — Research

## Existing patterns analyzed

### do-next (`.cursor/skills/do-next/SKILL.md`)

**Strengths:** Smoke gate, Q3/Q4 evaluation, DELIVERY-PROFILE commit rules, GSD MCP state, Task Handoff Gate.

**Limitation:** One unit per invocation; pauses after each task. Runner wraps this in a loop while preserving all phases.

**Key phases to reuse:**

| Phase | Purpose |
| --- | --- |
| 0 Orient | `gsd_progress`, `gsd_milestone_status` |
| 0.5 Smoke | `gsd-smoke.sh` — mandatory for runner |
| 1 Route | Map nextAction to 2a/2b/2c/2d/2e |
| 2b Execute | Implement + verify + `gsd_task_complete` |
| 2c Complete slice | Verify + `gsd_slice_complete` + commit |
| 2e Gates | Q3/Q4 + `gsd_save_gate_result` + rebuild state |

### gsd-next-cursor (`.claude/skills/gsd-next-cursor/SKILL.md`)

Pure GSD routing without smoke, Q3/Q4 rebuild, or slice commit rules. **Not suitable** as runner backend.

### gsd-autonomous (`.cursor/skills/gsd-autonomous/SKILL.md`)

Uses `.planning/` phase model (discuss → plan → execute). Different state model from milestone/slice/task under `.gsd/milestones/`. **Not suitable.**

### gsd-executor (`.cursor/agents/gsd-executor.md`)

Executes PLAN.md waves with per-task commits. Different from GSD milestone DB + slice plans. **Agent structure reused** (role, files_to_read, MCP usage) but not execution model.

### gsd-smoke (`.workflow/scripts/gsd-smoke.py`)

Validates:

1. Plan coherence — markdown vs DB task counts
2. Gate-evaluate readiness — Q3/Q4 status
3. STATE.md sync — phase drift detection

Supports `--milestone M001` and `--rebuild-state`. Runner always passes milestone scope to smoke.

### milestone-workflow (`.gsd/workflow/milestone-workflow.md`)

**Remote Mutation Rule:** No push/PR without profile allowance + user approval.

**Task Handoff Gate:** Pause between tasks unless plan allows auto-continue. Runner invocation = auto-continue contract.

**Stop conditions:** Missing profile, wrong branch, validation fail, unauthorized remote mutation.

## Design decisions

| Decision | Rationale |
| --- | --- |
| Inline do-next phases (not spawn subagent per unit) | Lower cost, shared context, faster iteration |
| Background reporter subagent | Async reports without blocking next smoke gate |
| `push_after_slice` in slice plan | Explicit opt-in per slice; satisfies hard user rule |
| Idea template + personal skill | Cross-project reuse with single source of truth |
| JSONL + markdown summary | Machine-parseable + human-readable run logs |
| `--max-units` default 25 | Safety against runaway loops |

## Push authorization detection

Parse active `S##-PLAN.md` for:

```markdown
## Delivery
- push_after_slice: true
```

Or `push: approved`. Absent or `false` → block all remote mutations.

## Async reporting mechanism

After successful unit:

1. Build report payload (milestone, slice, task, smoke, verification, files, commit, nextAction)
2. Call `append-run-report.py` synchronously (fast) OR spawn background Task for summary markdown
3. Main loop proceeds immediately to next iteration

Using the Python helper synchronously for JSONL (fast append) keeps reliability; markdown summary can be appended by same script.

## Open questions (resolved)

| Question | Resolution |
| --- | --- |
| Personal vs project skill? | Both — idea template + install script |
| Skip smoke in steady state? | Never for runner |
| Commit per task? | No — follow DELIVERY-PROFILE `slice` cadence |
