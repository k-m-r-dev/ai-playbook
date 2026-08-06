# SPIKE — gsd-pi external executor (2026-08-06)

## Result: PASS against `@opengsd/gsd-pi@1.12.0`

Command:

```bash
GSD_PI_ROOT=~/.npm-global/lib/node_modules/@opengsd/gsd-pi \
  node shared/gsd/mcp/gsd-external-executor/scripts/spike-e2e.mjs
```

Observed flow:

1. `registerAutoWorker` + `claimMilestoneLease` + `recordDispatchClaim`
2. `claimTaskAttempt` → running Attempt
3. `stageTaskCompletion` → `nextStage=verify`
4. `recordTaskTechnicalVerdict` (pass) + `publishVerifiedTaskCompletion`
5. `tasks.status=complete`, PLAN checkbox `[x]` refreshed

## Import map (dist)

| Op | Module under `dist/resources/extensions/gsd/` |
| --- | --- |
| open DB | `gsd-db.js` |
| worker | `db/auto-workers.js` |
| lease | `db/milestone-leases.js` |
| dispatch | `db/unit-dispatches.js` |
| claim/settle | `task-execution-domain-operation.js` |
| stage/publish | `task-completion-compatibility-adapter.js` |
| verdict | `task-verification-domain-operation.js` |
| source snapshot | `verification-source-integrity.js` |

## Failure modes

- Lease held by another worker → begin fails (do not steal by default)
- `gsd_task_complete` without running Attempt → stock MCP error
- Publish without `nextStage=verify` → bridge error
- gsd-pi version outside `1.12.x` → health degraded / refuse
- Missing `.gsd/gsd.db` → health / begin refuse

## Guardrails

Bridge is **execution-only**. Planning remains `gsd_plan_*` only. No hand-edits to PLAN/DB.
