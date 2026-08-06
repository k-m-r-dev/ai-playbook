# Do-Next Runner

**Multi-unit orchestrator** wrapping `do-next`. Chains tasks/slices until scope complete, blocked, or `--max-units` reached.

For single-step interactive work, use **`do next`** / **`$do-next`**.

<!-- SYNC: shared/gsd/idea/do-next-runner/templates/SKILL.body.md -->

## GSD bootstrap gate

<!-- include: skills/_includes/GSD_BOOTSTRAP_GATE.md -->

## Invocation

```text
$do-next-runner [M###] [S##] [T##] [--max-units N] [--dry-run]
```

| Flag | Default | Purpose |
| --- | --- | --- |
| `--max-units` | 25 | Safety cap |
| `--dry-run` | off | Orient + smoke + route only |

## Prerequisites

- GSD MCP in `.mcp.json` (`GSD_WORKFLOW_PROJECT_ROOT` = repo root)
- `.workflow/scripts/gsd-smoke.sh`
- `.gsd/workflow/milestone-workflow.md` + `.gsd/DELIVERY-PROFILE.md`
- Project `do-next` skill (see path table in GSD bootstrap gate)

## Read order (each loop iteration)

1. `.gsd/workflow/milestone-workflow.md`
2. `.gsd/DELIVERY-PROFILE.md`
3. `do-next` skill — execute phases inline
4. Active `S##-PLAN.md` / `T##-PLAN.md`
5. `ARCHITECTURE.md`

## Git policy handshake (required)

Before first execution unit, ask and confirm one mode:

- `none` — no push/PR workflow required
- `slice` — push/PR checkpoint at each slice completion
- `milestone` — push/PR checkpoint at milestone progression

If mode is not explicitly confirmed, STOP.

At every slice completion, re-ask whether this slice should run push/PR now (projects can differ by slice).
At every milestone progression boundary, re-ask whether milestone push/PR is required before advancing.

No auto push/PR in runner mode. All git stages require explicit confirmation.

## Auto-continue contract

`$do-next-runner` **overrides** Task Handoff Gate pause. Cap with `--max-units`.

## Orchestration loop

```text
INIT → while (pending in scope AND units < max-units):
  0 Orient → 0.5 Smoke → 1 Route → 2x Execute → 3 Report → CONTINUE
FINAL REPORT
```

### INIT

1. Parse scope and flags
2. Generate `runId` (UUID)
3. Ensure `.gsd/runtime/do-next-runner/` exists
4. `RUN_LOG=.gsd/runtime/do-next-runner/RUN-{runId}.jsonl`

### 0.5 Smoke (mandatory)

**Never** `--skip-smoke`.

```bash
.workflow/scripts/gsd-smoke.sh --milestone {MILESTONE_ID}
.workflow/scripts/playbook-gsd-health.sh   # or MCP playbook_gsd_bridge_health
```

Bridge health DEGRADED → STOP or explicit degrade (do not claim ledger done).

FAIL → gap report → ask sync direction → **STOP**

**Compat projection drift is the exception to "ask sync direction".** If the FAIL is `total md=0 db=N files=0 DRIFT` for every slice AND the rendered `NN-MM-PLAN.md` files exist with `<tasks>` AND `grep -c "<M###>/S0" .gsd/.compat.json` is `0`, it is a stale projection INDEX (gsd-pi `gsd_plan_slice` does not record slice-PLAN projections), not a content conflict. Self-heal instead of asking:

```bash
node .workflow/scripts/gsd-reproject-compat.mjs <M###>   # then re-run smoke --milestone <M###>
```

Full detection guard, cause, and inline fallback (for repos without the script): **do-next skill § 0.5.1 Compat projection drift**. Any real markdown↔DB content mismatch still uses the normal sync-direction STOP.

### 1. Route

Map to do-next phases 2a/2b/2c/2d/2e (one unit). Respect `T##` / `S##` scope.

### 2x Execute

Per do-next skill (including **playbook_gsd_task_begin** → implement → **gsd_task_complete** → **playbook_gsd_task_publish**). Verify per DELIVERY-PROFILE. `gsd_slice_complete` when the slice is ready.

When execution reaches slice completion or milestone boundary, enforce staged confirmations:

- Stage A: confirm push
- Stage B: after push, confirm PR creation
- Stage C: confirm continue/wait-for-merge behavior

If user declines any stage, STOP and report pending checkpoint.

### 3. Report

```bash
python3 .gsd/idea/do-next-runner/scripts/append-run-report.py \
  --run-id {runId} --milestone {M} --slice {S} --task {T} \
  --unit-type task|slice|gate --smoke PASS \
  --verification-cmd "{cmd}" --verification-exit 0 \
  --files "path1,path2" --commit "{hash}" --next-action "{from gsd_progress}"
```

## Push hard rule

Before any `git push` / `gh pr create`:

```bash
python3 .gsd/idea/do-next-runner/scripts/push-gate.py --milestone {M} --slice {S}
```

Exit non-zero → block and STOP.

Apply this only when current confirmed Git mode requires push/PR (`slice` or `milestone`).

## Stop conditions

Smoke FAIL, verification FAIL, gate `flag`, MCP unavailable, `--max-units`, unauthorized push, awaiting user checkpoint confirmation, scope complete.

## Anti-patterns

- No `--skip-smoke`
- No auto-sync on drift
- No unsupervised full-milestone `gsd_execute` as backend (playbook-gsd claim/publish is required for ledger)
- No raw DB/STATE edits or hand-edited PLAN checkboxes
- No push/PR without explicit staged user confirmations
- No continuing the chain if begin/publish fails without an explicit degrade decision
