---
name: do-chores
description: >-
  Use when executing the next planned implementation task from a .w2c plan.
  Triggers: do chores, do-chores, /do-chores. One task by default. Not for
  creating the plan (use work-to-chores).
---

# Do Chores

Execute planned work from `.w2c/`. Default: **one** next task.

Read `USAGE.md` in this folder for the plain-English invocation.

## Invocation

```text
do chores [M###] [S##] [T##] [--max-units N] [--dry-run]
```

| Args | Meaning |
| --- | --- |
| (none) | Next open task globally; stop after one |
| `M011` | Next open task in that milestone; still one unless `--max-units` |
| `M011 S02` | Next open task in that slice; still one unless `--max-units` |
| `M011 S02 T03` | That task if still open |
| `--max-units N` | Chain up to N units in the implied scope |
| `--dry-run` | Smoke + name the next unit; do not implement |

Scope only narrows the queue. It does not drain a milestone unless `--max-units` is set.

## Prerequisites (hard stop)

1. **requesting-code-review** must be invocable. If missing: STOP and tell the user to add it.
2. `.w2c/scripts/w2c.sh` must exist. If missing: STOP and tell the user:

```bash
bash scripts/install-w2c-to-project.sh --repo .
```

3. A plan must exist (ROADMAP + at least one slice plan with tasks). If not: STOP and tell the user to run work-to-chores.

## Status writes

Never hand-edit STATE.md, QUEUE.md, ROADMAP emojis, or `[ ]` / `[x]` on tasks.

```bash
.w2c/scripts/w2c.sh smoke
.w2c/scripts/w2c.sh next [--milestone M###] [--slice S##] [--task T##]
.w2c/scripts/w2c.sh complete --milestone M### --slice S## --task T##
.w2c/scripts/w2c.sh status
```

## Loop

Every unit:

1. **Smoke** — `.w2c/scripts/w2c.sh smoke`. On FAIL: STOP with the report. Do not implement.
2. **Pick** — `w2c next` with any M/S/T filters from the invocation.
3. If `--dry-run`: print the unit and STOP.
4. If no open task: print that and STOP.
5. **Read order:** STATE.md, ROADMAP.md, active `M###-ROADMAP.md` (guardrails), slice `M###-S##-PLAN.md`, `M###-CONTEXT.md`, latest `contexts/CONTEXTvX.Y.md`, DECISIONS.md.
6. **Implement** that task only.
7. **Verify** — run the task’s Verify commands. On failure: find root cause, fix, re-verify. Loop until green.
8. **Review** — invoke requesting-code-review. On findings: find root cause, fix, re-verify, re-review. Loop until clean.
9. **Complete** — only then `w2c complete --milestone … --slice … --task …`.
10. **Report** — task id/title, files changed, verify commands + outcomes, review result, blockers.
11. If `--max-units` is set and units remain and the scope still has open tasks: go to step 1. Otherwise STOP.

No-args always stops after one completed or failed unit.

Honor Delivery & Guardrails on the milestone ROADMAP: commit cadence (default milestone), no push/PR without explicit user approval.

## Red flags — STOP

- Marking a task complete by editing the markdown checkbox
- Skipping smoke, verify, or requesting-code-review
- Continuing after smoke FAIL
- Implementing more than one task when `--max-units` is absent
- Pushing or opening a PR without explicit user approval
