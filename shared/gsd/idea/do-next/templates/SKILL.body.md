# Do Next

**One unit per invocation.** GSD MCP for state persistence, plus milestone workflow (Task Handoff Gate, delivery profile, slice commits).

For **pure GSD** routing without custom gates or commit rules, use **`$gsd-advance-unit`**.

<!-- SYNC: shared/gsd/idea/do-next/templates/SKILL.body.md -->

## GSD bootstrap gate

<!-- include: skills/_includes/GSD_BOOTSTRAP_GATE.md -->

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
.workflow/scripts/playbook-gsd-health.sh   # or MCP playbook_gsd_bridge_health
```

**On smoke FAIL:** STOP → gap report per slice → ask user: **markdown → DB** or **DB → markdown** → wait. No auto-sync.

**On bridge DEGRADED:** STOP unless user explicitly accepts degrade (code may ship; ledger stays pending via `gsd_decision_save` — never fake PLAN/DB).

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

Canonical gsd-pi (≥1.12) tasks need a **running Attempt** before `gsd_task_complete`, then host publish before PLAN checkboxes update. Use the **playbook-gsd** MCP (never hand-edit PLAN/DB).

1. **`playbook_gsd_bridge_health`** (or `.workflow/scripts/playbook-gsd-health.sh`). If degraded: STOP or take the documented degrade path (`gsd_decision_save` + ship on filesystem evidence — do **not** fake checkboxes).
2. Read `T##-PLAN.md` (resolve path via `.gsd/.compat.json` / `gsd_progress` — do not hardcode layout).
3. **`playbook_gsd_task_begin`** with `milestoneId` / `sliceId` / `taskId` (claims Attempt). On lease conflict: STOP; do not steal auto leases.
4. Implement per `ARCHITECTURE.md`
5. Verify per `.gsd/DELIVERY-PROFILE.md` and skill **`platform.md`**
6. **`gsd_task_complete`** with required fields + `verificationEvidence`
7. If response `nextStage` is **`verify`**: **`playbook_gsd_task_publish`** (required). If **`route`**: STOP for recovery — do not publish. Treat complete-without-publish as incomplete.
8. On cancel/interrupt mid-task: **`playbook_gsd_task_abort`** so Attempts are not left `running`.
9. **Task Handoff Gate:** pause for next `do next`
10. **No commit** when `commit_cadence: slice`

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
- No hand-toggling PLAN `[ ]` / `[x]` or inventing completion
- No push/PR without explicit stage confirmation
- No multiple units unless user says "run N steps"
- No unsupervised full-milestone `gsd_execute` / terminal `/gsd next` as do-next backend (user may opt in explicitly; default is playbook-gsd begin→complete→publish)
- No `gsd_task_complete` without a prior successful `playbook_gsd_task_begin` on canonical tasks
- No treating `gsd_task_complete` as done when `nextStage` is still `verify` — must publish

## vs gsd-advance-unit

| | `do-next` | `gsd-advance-unit` |
| --- | --- | --- |
| Coherence smoke | required (skippable) | optional |
| Q3/Q4 + STATE rebuild | yes | GSD phase only |
| Slice commit rules | DELIVERY-PROFILE | GSD defaults |
| Task Handoff Gate | pause every task | one GSD unit |
