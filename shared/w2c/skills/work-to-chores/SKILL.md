---
name: work-to-chores
description: >-
  Use when turning a ticket, spec, or work description into an implementation
  plan of milestones, slices, and tasks before any product code is written.
  Triggers: work to chores, work-to-chores, /work-to-chores. Not for executing
  planned tasks (use do-chores).
---

# Work to Chores

**Plan only.** Interview, review, plan, validate, write `.w2c/` artifacts. Never implement product code.

Read `USAGE.md` in this folder for the plain-English invocation.

## Prerequisites (hard stop)

Before Stage 1:

1. Confirm **grilling** and **brainstorming** are invocable in this environment.
2. Confirm `.w2c/scripts/w2c.sh` (or `w2c.py`) exists in the current repo.

If grilling or brainstorming is missing: **STOP**. Tell the user which skill is missing and ask them to add it. Do not invent a substitute interview.

If scripts are missing: **STOP**. Tell the user to run:

```bash
bash scripts/install-w2c-to-project.sh --repo .
```

(From the playbook repo that contains that script.) Then they re-invoke this skill.

If `.w2c/` ledger files are missing, run `.w2c/scripts/w2c.sh init`.

## Status writes

Use the CLI only for STATE.md, QUEUE.md, ROADMAP emojis, task checkboxes, DECISIONS rows, and new CONTEXT versions:

```bash
.w2c/scripts/w2c.sh status
.w2c/scripts/w2c.sh decide --scope ... --decision ... --choice ... --rationale ...
.w2c/scripts/w2c.sh context-new --minor   # or --major
.w2c/scripts/w2c.sh next-milestone-id
.w2c/scripts/w2c.sh milestone-new --slug ...
.w2c/scripts/w2c.sh milestone-status M001 PLANNING
```

Never hand-edit those status bits. Authoring plan content (vision, tasks, verify commands) is allowed after Stage 5 approval.

## Stage 1 - Gather context

Always run this stage, even when a ticket or spec is pasted.

Need a hint of the work. If the prompt has no ticket, spec, or description: ask for one before interviewing.

Then, in order:

1. **Grilling** - one question at a time. Search the codebase before asking. Recommended option marked. Close when **scope, users, done criteria, risks, integrations, and out-of-scope** are clear.
2. **Brainstorming** - find structural gaps (edge cases, empty states, testing seams).
3. **Grilling again** - confirm each gap and pick a solution.

Save knowledge with `w2c context-new` (first pass may use the `CONTEXTv1.0.md` from `init`; later loops always create a new file). Never overwrite an existing CONTEXT file.

Version bump: **major** if scope, users, or done-criteria change; **minor** for clarifications, risks, out-of-scope, wording.

Record major decisions with `w2c decide`.

## Stage 2 - Review context

Review collected knowledge for architectural or design gaps that would break the original requirement.

If you find an issue, present in plain English:

- what is wrong
- impact
- multiple options
- a recommended option

Wait for a choice. Save it with `w2c decide`. Then return to Stage 1 with a new CONTEXT version.

## Stage 3 - Plan

Break work into milestones `M###` (unique; `w2c next-milestone-id` / `w2c milestone-new --slug`). Each milestone has slices `S01`, `S02`, ... and tasks `T01`, `T02`, ... fully specified with a Verify line.

Milestone states: PLANNING, TODO, PAUSED, INPROGRESS, DONE, ERROR, STOP.

Each task needs a testing or other verification plan. Embed this execution rule in every slice plan (do **not** execute it here):

- A task is not complete until Verify passes and **requesting-code-review** is clean. Loop fix, verify, review until both succeed. Then `w2c complete`.

Default guardrails in each `M###-ROADMAP.md` Delivery and Guardrails table:

- commit cadence = milestone (one commit after the milestone is verified)
- no push/PR without explicit user approval
- no per-run git handshake

Do not implement product code in this skill.

## Stage 4 - Validate the plan

Until there are no pending issues or gaps, loop Stages 1-4. Never rewrite an existing CONTEXT; `w2c context-new --major` or `--minor`. Save decisions with `w2c decide`.

## Stage 5 - User review

Ask the user to review the plan. If they request a change:

1. Do not trust it until checked against the original requirement.
2. If it fits: restate what you understood and your suggested adjustment; wait for confirmation; then Stage 1 with a new CONTEXT version.
3. If it does not fit: explain the mismatch; do not change the plan.

## Write the plan (after approval only)

Canonical tree:

```text
.w2c/
  plans/M###-<slug>/
    M###-ROADMAP.md
    M###-CONTEXT.md
    M###-S##-PLAN.md
  contexts/CONTEXTvX.Y.md
  DECISIONS.md
  ROADMAP.md
  STATE.md
  QUEUE.md
```

Use `w2c milestone-new` then fill ROADMAP/CONTEXT/slice plan content. Formats: follow the templates in `shared/w2c/templates/` and `shared/w2c/README.md`. Milestone files are `M###-ROADMAP.md` + `M###-CONTEXT.md` + slice plans - never a second `M###-PLAN.md`.

`w2c milestone-status` / `w2c set` for pointers. `w2c smoke` before handing off to do-chores.

## Red flags - STOP

- Implementing product code
- Skipping grilling or brainstorming
- Overwriting CONTEXTvX.Y.md
- Hand-editing STATE/QUEUE/checkboxes/ROADMAP emojis
- Writing milestone files before Stage 5 approval
- Reusing a milestone id
