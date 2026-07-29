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

Run a **Git policy handshake** before routing milestone progression:

1. Ask: "Do we require git push / PR workflow for this project scope right now?"
2. Require one explicit mode for this invocation:
   - `none` — no push/PR gating
   - `slice` — push/PR checkpoints at each slice completion
   - `milestone` — push/PR checkpoints at milestone progression only
3. If user does not confirm mode, **STOP** and wait.

When in `slice` or `milestone` mode, never auto-run git operations. Each stage needs explicit confirmation in-order.

If MCP unavailable, stop — do not guess from markdown alone.

If no active milestone, stop — direct user to **`$gsd-plan-milestone`**.

### 0.5. Plan coherence gate

**Default:** run smoke every `do next`.

**Skip when** the user message includes **`--skip-smoke`**. Do not skip silently.

```bash
.workflow/scripts/gsd-smoke.sh
```

**On FAIL:** STOP → gap report per slice → ask user: **markdown → DB** or **DB → markdown** → wait. No auto-sync.

### 0.5.1 Compat projection drift (self-heal)

**Symptom:** smoke `plan-coherence` FAILs with `total md=0 db=N files=0 DRIFT` for **every** slice, while the DB and the rendered `NN-MM-PLAN.md` files both hold the tasks.

**Guard — self-heal ONLY when all three hold** (otherwise it is a real content conflict → keep the STOP above and ask *markdown → DB / DB → markdown*, no auto-sync):

1. smoke shows `md=0 db>0 files=0 DRIFT` for the slices,
2. rendered PLANs exist with tasks — `ls .gsd/phases/*/*-PLAN.md` and each has a `<tasks>` block,
3. the index is missing entries — `grep -c "<M###>/S0" .gsd/.compat.json` returns `0`.

**Cause (gsd-pi bug):** `gsd_plan_slice` writes the DB rows and renders the PLAN files but never records their `.compat.json` projection entries (`writeAndStore()` records a projection only when `basePath` is passed; the PLAN/slice renderers omit it). `gsd_checkpoint_db` and MCP reload do not backfill, and `resolve_slice_plan` needs those entries.

**Fix (index-only, additive; regenerates from the correct DB/rendered files via gsd-pi's compat-marker API — never hand-edit `.compat.json`):**

```bash
node .workflow/scripts/gsd-reproject-compat.mjs <M###>
.workflow/scripts/gsd-smoke.sh --milestone <M###>   # expect PASS
```

If the script is absent (fresh repo), recreate it from the canonical copy at `.workflow/scripts/gsd-reproject-compat.mjs`, or run the inline equivalent:

```bash
M=<M###> node --input-type=module -e '
import{readFileSync as R,readdirSync as D}from"node:fs";import{join as J}from"node:path";
const r=process.cwd(),M=process.env.M,X=process.env.GSD_PI_EXT||J(process.env.HOME,".npm-global/lib/node_modules/@opengsd/gsd-pi/dist/resources/extensions/gsd");
const{readCompatMarker:rd,writeCompatMarker:wr,computeProjectionSha:sha}=await import(J(X,"compat/compat-marker.js"));
const p=J(r,".gsd","phases"),m=rd(r);let n=0;
for(const d of D(p,{withFileTypes:true})){if(!d.isDirectory())continue;const a=J(p,d.name),F=D(a).filter(f=>f.endsWith(".md"));
const rm=F.find(f=>/-ROADMAP\.md$/.test(f));if(!rm)continue;const rt=R(J(a,rm),"utf8"),id=(rt.match(/^#\s*(M\d+)\b/m)||[])[1];if(!id||(M&&id!==M))continue;
m.projections["phases/"+d.name+"/"+rm]={sha:sha(rt),entities:[id]};n++;
for(const f of F){const g=f.match(/^\d+-(\d+)-(PLAN|SUMMARY|UAT|REPLAN|ASSESSMENT)\.md$/);if(!g)continue;const t=R(J(a,f),"utf8");m.projections["phases/"+d.name+"/"+f]={sha:sha(t),entities:[id,id+"/S"+g[1]]};n++;}}
m.lastWriter="gsd-pi";m.lastProjectedAt=new Date().toISOString();wr(r,m);console.log("reprojected",n);'
```

Report the gsd-pi bug upstream so `gsd_plan_slice` records slice-PLAN projections.

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
4. **Slice checkpoint (always ask):**
   - Ask whether this slice should run push/PR now.
   - If mode is `none`: skip push/PR and continue.
   - If mode is `milestone`: ask "defer push/PR to milestone checkpoint?"; require explicit yes/no.
   - If mode is `slice`: run staged confirmations below.
5. **Stage confirmations for slice mode (strict order):**
   - Stage A: "Push current branch now?"
   - Stage B (only after successful push): "Create PR now?"
   - Stage C (after PR create/skip): "Proceed to next unit?"
   - Any "no" stops progression and reports pending stage.
6. Update `.workflow/progress_tracker.md` if applicable

### 2d. Milestone gate

Wait for prerequisite milestone in **`gsd_milestone_status`**.

At milestone progression boundary, run **milestone checkpoint**:

1. Ask whether milestone-level push/PR is required for this project right now.
2. If user says no: continue with no Git gate.
3. If user says yes: execute staged confirmations in-order:
   - Stage A: confirm push for milestone branch
   - Stage B: after push, confirm PR creation
   - Stage C: after PR exists, confirm waiting for merge before advancing
4. If milestone push/PR is required but not completed/merged, **BLOCK** advancement to next milestone.

### 3. Report

Unit summary, verification, smoke status, chosen Git mode, checkpoint outcomes, next `gsd_progress` state.

End with: **Say `do next` for the next unit.**

## Skip smoke

User opt-out: **`do next --skip-smoke`**.

Still run step **0. Orient** via **`gsd_progress`**. Report `SKIPPED (--skip-smoke)` in summary.

Do not skip on: new session, slice boundary, after gate saves / plan edits, branch switch, previous FAIL.

## Anti-patterns

- No auto-sync on markdown/DB drift
- No raw `.gsd/gsd.db` or `.gsd/STATE.md` edits
- No push/PR without explicit stage confirmation
- No multiple units unless user says "run N steps"
- No `gsd_execute` / terminal `/gsd next` as backend

## vs gsd-advance-unit

| | `do-next` | `gsd-advance-unit` |
| --- | --- | --- |
| Coherence smoke | required (skippable) | optional |
| Q3/Q4 + STATE rebuild | yes | GSD phase only |
| Slice commit rules | DELIVERY-PROFILE | GSD defaults |
| Task Handoff Gate | pause every task | one GSD unit |
