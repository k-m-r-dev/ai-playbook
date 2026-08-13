#!/usr/bin/env python3
"""Patch do-next family skills for playbook-gsd Attempt lifecycle."""
from pathlib import Path

ROOT = Path("/Users/khandkermahmudur/Workspace/self/ai-playbook")

EXECUTE_OLD = """### 2b. Execute task

1. Read `T##-PLAN.md`
2. Implement per `ARCHITECTURE.md`
3. Verify per `.gsd/DELIVERY-PROFILE.md` and skill **`platform.md`**
4. **`gsd_task_complete`** after verification passes
5. **Task Handoff Gate:** pause for next `do next`
6. **No commit** when `commit_cadence: slice`
"""

EXECUTE_NEW = """### 2b. Execute task

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
"""

ANTI_OLD = """## Anti-patterns

- No auto-sync on markdown/DB drift
- No raw `.gsd/gsd.db` or `.gsd/STATE.md` edits
- No push/PR without explicit stage confirmation
- No multiple units unless user says "run N steps"
- No `gsd_execute` / terminal `/gsd next` as backend
"""

ANTI_NEW = """## Anti-patterns

- No auto-sync on markdown/DB drift
- No raw `.gsd/gsd.db` or `.gsd/STATE.md` edits
- No hand-toggling PLAN `[ ]` / `[x]` or inventing completion
- No push/PR without explicit stage confirmation
- No multiple units unless user says "run N steps"
- No unsupervised full-milestone `gsd_execute` / terminal `/gsd next` as do-next backend (user may opt in explicitly; default is playbook-gsd begin→complete→publish)
- No `gsd_task_complete` without a prior successful `playbook_gsd_task_begin` on canonical tasks
- No treating `gsd_task_complete` as done when `nextStage` is still `verify` — must publish
"""

SMOKE_OLD = """```bash
.workflow/scripts/gsd-smoke.sh
```

**On FAIL:** STOP → gap report per slice → ask user: **markdown → DB** or **DB → markdown** → wait. No auto-sync.
"""

SMOKE_NEW = """```bash
.workflow/scripts/gsd-smoke.sh
.workflow/scripts/playbook-gsd-health.sh   # or MCP playbook_gsd_bridge_health
```

**On smoke FAIL:** STOP → gap report per slice → ask user: **markdown → DB** or **DB → markdown** → wait. No auto-sync.

**On bridge DEGRADED:** STOP unless user explicitly accepts degrade (code may ship; ledger stays pending via `gsd_decision_save` — never fake PLAN/DB).
"""

do_next = ROOT / "shared/gsd/idea/do-next/templates/SKILL.body.md"
text = do_next.read_text()
for old, new, label in [
    (EXECUTE_OLD, EXECUTE_NEW, "execute"),
    (ANTI_OLD, ANTI_NEW, "anti"),
    (SMOKE_OLD, SMOKE_NEW, "smoke"),
]:
    if old not in text:
        raise SystemExit(f"do-next: {label} block not found")
    text = text.replace(old, new, 1)
do_next.write_text(text)
print("patched do-next SKILL.body.md")

runner = ROOT / "shared/gsd/idea/do-next-runner/templates/SKILL.body.md"
rtext = runner.read_text()
r_exec_old = """### 2x Execute

Per do-next skill. Verify per DELIVERY-PROFILE. `gsd_task_complete` / `gsd_slice_complete` as appropriate.
"""
r_exec_new = """### 2x Execute

Per do-next skill (including **playbook_gsd_task_begin** → implement → **gsd_task_complete** → **playbook_gsd_task_publish**). Verify per DELIVERY-PROFILE. `gsd_slice_complete` when the slice is ready.
"""
r_anti_old = """## Anti-patterns

- No `--skip-smoke`
- No auto-sync on drift
- No `gsd_execute` / `gsd-advance-unit` as backend
- No raw DB/STATE edits
- No push/PR without explicit staged user confirmations
"""
r_anti_new = """## Anti-patterns

- No `--skip-smoke`
- No auto-sync on drift
- No unsupervised full-milestone `gsd_execute` as backend (playbook-gsd claim/publish is required for ledger)
- No raw DB/STATE edits or hand-edited PLAN checkboxes
- No push/PR without explicit staged user confirmations
- No continuing the chain if begin/publish fails without an explicit degrade decision
"""
smoke_old = """```bash
.workflow/scripts/gsd-smoke.sh --milestone {MILESTONE_ID}
```
"""
smoke_new = """```bash
.workflow/scripts/gsd-smoke.sh --milestone {MILESTONE_ID}
.workflow/scripts/playbook-gsd-health.sh   # or MCP playbook_gsd_bridge_health
```

Bridge health DEGRADED → STOP or explicit degrade (do not claim ledger done).
"""
for old, new, label in [
    (r_exec_old, r_exec_new, "exec"),
    (r_anti_old, r_anti_new, "anti"),
    (smoke_old, smoke_new, "smoke"),
]:
    if old not in rtext:
        raise SystemExit(f"runner: {label} block not found")
    rtext = rtext.replace(old, new, 1)
runner.write_text(rtext)
print("patched do-next-runner SKILL.body.md")

# gsd-advance-unit body
adv = ROOT / "shared/gsd/skills/gsd-advance-unit/SKILL.body.md"
at = adv.read_text()
# find execute + complete pattern
needle = "**`gsd_task_complete`**"
if needle not in at:
    raise SystemExit("advance-unit: gsd_task_complete not found")
# insert a short Attempt lifecycle note before first occurrence of implement complete line
marker = "Read `T##-PLAN.md`. Implement per `ARCHITECTURE.md` + [platform.md](platform.md). Verify. **`gsd_task_complete`**."
replacement = (
    "Call **`playbook_gsd_bridge_health`** then **`playbook_gsd_task_begin`**. "
    "Read `T##-PLAN.md`. Implement per `ARCHITECTURE.md` + [platform.md](platform.md). Verify. "
    "**`gsd_task_complete`**, then **`playbook_gsd_task_publish`** if `nextStage` is `verify` "
    "(abort with **`playbook_gsd_task_abort`** on cancel)."
)
if marker not in at:
    # try looser
    print("advance marker missing; dumping lines with complete:")
    for i, line in enumerate(at.splitlines(), 1):
        if "gsd_task_complete" in line or "Execute" in line:
            print(f"{i}: {line}")
    raise SystemExit(1)
at = at.replace(marker, replacement, 1)
anti_a = "- No `gsd_execute` / terminal `/gsd next` unless user explicitly requests TUI billing"
anti_b = (
    "- No unsupervised full-milestone `gsd_execute` / terminal `/gsd next` unless user explicitly requests auto/TUI billing\n"
    "- No `gsd_task_complete` without `playbook_gsd_task_begin` on canonical tasks; publish when `nextStage` is `verify`"
)
if anti_a in at:
    at = at.replace(anti_a, anti_b, 1)
adv.write_text(at)
print("patched gsd-advance-unit SKILL.body.md")

# ticket-to-plan light touch
ttp = ROOT / "shared/gsd/skills/ticket-to-plan/SKILL.md"
tt = ttp.read_text()
insert_after = "### Verify projections after persisting — compat drift self-heal"
note = """

### Execution handoff (gsd-pi ≥1.12)

After plan approval, execution via **do-next / do-next-runner** requires the **playbook-gsd** MCP (`playbook_gsd_task_begin` → `gsd_task_complete` → `playbook_gsd_task_publish`). Planning stays on stock `gsd_plan_*` only — do not hand-edit PLAN checkboxes or `.gsd/gsd.db`. Review plans via `gsd_progress` / `gsd_milestone_status` and `.compat.json`-resolved `.gsd/phases/*` files.
"""
if "Execution handoff (gsd-pi" not in tt:
    if insert_after not in tt:
        raise SystemExit("ticket-to-plan insert point missing")
    tt = tt.replace(insert_after, insert_after + note, 1)
    ttp.write_text(tt)
    print("patched ticket-to-plan SKILL.md")
else:
    print("ticket-to-plan already has handoff note")

# Patch assembled wrappers' MCP blurb if present
for wrap in [
    ROOT / "shared/gsd/idea/do-next/templates/SKILL.cursor.md",
    ROOT / "shared/gsd/idea/do-next-runner/templates/SKILL.cursor.md",
]:
    if not wrap.exists():
        continue
    w = wrap.read_text()
    old = "- **`.mcp.json`** at repo root with `gsd-workflow` and `GSD_WORKFLOW_PROJECT_ROOT` = repo root"
    new = (
        "- **`.mcp.json`** at repo root with `gsd-workflow` + **`playbook-gsd`** "
        "and `GSD_WORKFLOW_PROJECT_ROOT` = repo root"
    )
    if old in w:
        wrap.write_text(w.replace(old, new, 1))
        print(f"patched {wrap.name}")

print("DONE")
