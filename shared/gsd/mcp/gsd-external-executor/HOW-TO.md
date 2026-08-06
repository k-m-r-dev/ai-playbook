# How to use playbook-gsd (do-next + gsd-pi 1.12+)

Simple guide for planning with **ticket-to-plan** and executing with **do-next** / **do-next-runner** after the external-executor bridge.

## Why this exists

gsd-pi 1.12+ will not mark a task done unless:

1. Someone **claims** the task (starts an Attempt)
2. You call **`gsd_task_complete`**
3. Something **publishes** the result (host verify)

Stock `gsd-workflow` MCP has complete, but not claim/publish for agents outside gsd auto-mode.  
**playbook-gsd** fills that gap. Your agent still writes the code; the ledger can stay honest.

## One-time setup

1. Install / keep `@opengsd/gsd-pi` **1.12.x**.
2. Add the **playbook-gsd** MCP next to **gsd-workflow** (same project root).  
   Template: `config/mcp.template.json`  
   Package: `shared/gsd/mcp/gsd-external-executor/`
3. Reload MCP in Cursor / Claude / your CLI.
4. Check health:

```bash
.workflow/scripts/playbook-gsd-health.sh   # copied from shared/gsd/scripts/ on bootstrap
# or MCP: playbook_gsd_bridge_health
```

You want `"status": "ok"`.

Client repos: bootstrap with `--patch-mcp --with-do-next`, or merge `playbook-gsd` into `.mcp.json` by hand. Point `args` at your ai-playbook copy of `bin/playbook-gsd-mcp.mjs`.

## Plan (ticket-to-plan)

Unchanged:

1. Run **ticket-to-plan** (or `$gsd-plan-milestone` flow).
2. Plans are created only through **`gsd_plan_*`** tools.
3. Review under `.gsd/phases/…` (paths from `.compat.json` / `gsd_progress`).
4. Approve the plan before any execute.

Do **not** hand-edit PLAN checkboxes or `.gsd/gsd.db`.

## Execute one task (do next)

Say **`do next`** (or `$do-next`). The agent should:

| Step | Tool / action |
| --- | --- |
| 1 | `gsd_progress` — see next task |
| 2 | Smoke + **bridge health** |
| 3 | **`playbook_gsd_task_begin`** — claim the Attempt |
| 4 | Implement + verify in the repo |
| 5 | **`gsd_task_complete`** — stage the result |
| 6 | If `nextStage` is `verify` → **`playbook_gsd_task_publish`** |
| 7 | Pause at Task Handoff Gate (unless using runner) |

After step 6, PLAN checkboxes and summaries should update from the DB.

### do-next-runner

Same steps, looped for many tasks. Still needs playbook-gsd. Still no unsupervised full-milestone `gsd_execute` unless you ask for it.

## If something goes wrong

| Problem | What to do |
| --- | --- |
| Bridge health not ok | Fix gsd-pi version / `GSD_PI_ROOT` / MCP path; reload MCP |
| `gsd_task_complete` says needs running Attempt | You skipped **begin** — call begin, then complete again |
| Complete returned `verify` but PLAN still unchecked | Call **publish** |
| Lease held by another worker | Wait or stop the other gsd auto session; do not force-steal |
| Stuck / cancelled mid-task | **`playbook_gsd_task_abort`**, then begin again |
| Bridge broken and you must ship | Finish code + verify; record with `gsd_decision_save`; leave ledger pending — **never** fake checkboxes |

## Rules (short)

- Planning = `gsd_plan_*` only  
- Execution claim/publish = `playbook_gsd_*`  
- Completion record = `gsd_task_complete`  
- No raw DB edits, no hand-toggled `[x]`  
- No full auto `gsd_execute` as the default do-next path  

## More detail

- Package README: [README.md](./README.md)  
- Spike proof: [SPIKE.md](./SPIKE.md)  
- Later (own ledger / OpenSpec): [STAGE-B.md](./STAGE-B.md)
