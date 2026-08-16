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

1. **requesting-code-review** must be invocable. If missing: STOP. Log `--stage prereq --event stop --detail "missing requesting-code-review"` and tell the user to add it.
2. `.w2c/scripts/w2c.sh` must exist. If missing: STOP. Log `--stage prereq --event stop --detail "missing .w2c/scripts"` and tell the user:

```bash
bash scripts/install-w2c-to-project.sh --repo .
```

3. A plan must exist (ROADMAP + at least one slice plan with tasks). If not: STOP. Log `--stage prereq --event stop --detail "no plan"` and tell the user to run work-to-chores.

## Status writes

Never hand-edit STATE.md, QUEUE.md, ROADMAP emojis, or `[ ]` / `[x]` on tasks.

```bash
.w2c/scripts/w2c.sh smoke
.w2c/scripts/w2c.sh next [--milestone M###] [--slice S##] [--task T##]
.w2c/scripts/w2c.sh complete --milestone M### --slice S## --task T##
.w2c/scripts/w2c.sh slice-complete --milestone M### --slice S##
.w2c/scripts/w2c.sh milestone-complete M###
.w2c/scripts/w2c.sh status
```

## Events (local only)

Append-only JSONL at `.w2c/runtime/events.jsonl`. Gitignored. Never commit it. Never hand-edit it. The CLI is the only writer.

```bash
.w2c/scripts/w2c.sh event --skill do-chores --stage STAGE --event EVENT [--milestone M###] [--slice S##] [--task T##] [--detail "..."]
.w2c/scripts/w2c.sh events --tail 20 [--skill do-chores]
```

`--event` is one of: `started`, `complete`, `pass`, `fail`, `stop`, `retry`.

Log at every loop step enter/exit and every hard stop. `complete`, `slice-complete`, `milestone-complete`, and `smoke` also append automatically.

## Report files (committed)

Write these in the milestone plan folder. They are ledger, not runtime logs.

**`S##-T##-SUMMARY.md`** — frontmatter (`id`, `parent`, `milestone`, `key_files`, `verification_result`, `completed_at`) plus What Happened, Verification, Verification Evidence table, Deviations, Known Issues, Files Created/Modified.

**`S##-UAT.md`** — human checklist (leave boxes unchecked). Automated results go in the slice summary.

**`S##-SUMMARY.md`** — frontmatter plus What Happened, Verification (re-ran every task Verify in the slice), Deviations, Follow-ups, Files Created/Modified.

**`M###-VALIDATION.md`** — `verdict` (`pass` / `fail` / `needs-attention`), Success Criteria Checklist, Slice Delivery Audit, Cross-Slice Integration, Requirement Coverage, Verification Class Compliance, Verdict Rationale.

**`M###-SUMMARY.md`** — frontmatter plus What Happened, Success Criteria Results, Deviations, Follow-ups.

## Loop

Every unit:

1. **Smoke** — log `--stage smoke --event started`, then `.w2c/scripts/w2c.sh smoke`. On FAIL: log `--stage smoke --event fail` and STOP with the report. Do not implement. On PASS: log `--stage smoke --event pass`.
2. **Pick** — log `--stage next --event started`, then `w2c next` with any M/S/T filters from the invocation. Include `--milestone` / `--slice` / `--task` on the event when known.
3. If `--dry-run`: log `--stage dry-run --event complete --detail` with the unit id, print the unit, and STOP.
4. If no open task: log `--stage next --event stop --detail "no open task"`, print that, and STOP.
5. **Read order:** STATE.md, ROADMAP.md, active `M###-ROADMAP.md` (guardrails), slice `M###-S##-PLAN.md`, `M###-CONTEXT.md`, latest `contexts/CONTEXTvX.Y.md`, DECISIONS.md.
6. **Implement** that task only. Log `--stage implement --event started` before edits and `--stage implement --event complete` after.
7. **Verify** — log `--stage verify --event started`, then run the task’s Verify commands. On failure: log `--stage verify --event retry`, find root cause, fix, re-verify. Loop until green, then `--stage verify --event pass`.
8. **Review** — log `--stage review --event started`, then invoke requesting-code-review. On findings: log `--stage review --event retry`, find root cause, fix, re-verify, re-review. Loop until clean, then `--stage review --event pass`.
9. **Task summary** — write `.w2c/plans/M###-<slug>/S##-T##-SUMMARY.md` using the task-summary shape below. Do not call `complete` until this file exists and is non-empty. Log `--stage report --event complete --detail task-summary`.
10. **Complete** — `w2c complete --milestone … --slice … --task …`. The CLI refuses without the task summary. It does **not** mark the slice or milestone done.
11. **Slice closeout** — if stdout contains `NEED_SLICE_REPORTS` or `NEED_SLICE_COMPLETE`: re-run every task Verify command in that slice plus the slice Verification section. On failure: fix, re-verify, log `--stage verify --event retry`. Then write `S##-UAT.md` (human checklist, leave boxes unchecked) and `S##-SUMMARY.md` (automated results). Then `w2c slice-complete --milestone … --slice …`.
12. **Milestone closeout** — if stdout contains `NEED_MILESTONE_REPORTS` or `NEED_MILESTONE_COMPLETE`: run milestone Validation commands and check success criteria. Write `M###-VALIDATION.md` (audit/verdict) and `M###-SUMMARY.md` (what shipped). Then `w2c milestone-complete M###`.
13. **Report** — log `--stage report --event complete`. Then: task id/title, files changed, verify commands + outcomes, review result, which reports were written, blockers.
14. If `--max-units` is set and units remain and the scope still has open tasks: go to step 1. Otherwise STOP.

No-args always stops after one completed or failed unit.

Honor Delivery & Guardrails on the milestone ROADMAP: commit cadence (default milestone), no push/PR without explicit user approval.

## Red flags — STOP

- Marking a task complete by editing the markdown checkbox
- Skipping smoke, verify, requesting-code-review, or closeout reports
- Calling `complete` / `slice-complete` / `milestone-complete` without the required report files
- Continuing after smoke FAIL
- Implementing more than one task when `--max-units` is absent
- Pushing or opening a PR without explicit user approval
- Committing `.w2c/runtime/` or hand-editing `events.jsonl`
