# Do-Next Runner — Verification

## Prerequisites

- `.gsd/workflow/` + `.gsd/DELIVERY-PROFILE.md` (bootstrap via ai-playbook `bootstrap-gsd-workflow.sh`)
- GSD MCP in `.mcp.json` (+ `.cursor/mcp.json` for Cursor-only servers)
- `.workflow/scripts/gsd-smoke.sh` present
- `mkdir -p .gsd/runtime/do-next-runner`
- Active milestone with pending tasks (M001/S03 at time of authoring)

## Checklist

### V1 — Dry-run

```text
$do-next-runner M001 S03 --dry-run
```

| Check | Expected |
| --- | --- |
| Orient | `gsd_progress` shows M001/S03, next action |
| Smoke | PASS or FAIL reported; no code edits on PASS path |
| Route | Correct phase identified (2b for pending T03) |
| Mutations | No `gsd_task_complete`, no file edits |

**Status:** PASS (2026-06-07)

| Evidence | Result |
| --- | --- |
| Smoke | PASS — plan-coherence, gate-evaluate, state-sync |
| Orient | `gsd_progress` → M001/S03, phase execute, next T03 |
| Route | 2b Execute task (OpinionKeyPointsView) |
| Mutations | None (dry-run path + append-run-report test only) |

### V2 — Smoke fail stop

| Check | Expected |
| --- | --- |
| Inject drift | Smoke FAIL |
| Runner behavior | Stops immediately |
| Gap report | Per-slice counts shown |
| Auto-sync | None |

**Status:** _manual test — do not run in CI_

### V3 — Single task (M001 S03 T03)

```text
$do-next-runner M001 S03 T03
```

| Check | Expected |
| --- | --- |
| Smoke | PASS before unit |
| Implementation | Per T03-PLAN.md |
| Verification | xcodebuild test passes |
| MCP | `gsd_task_complete` called |
| Report | JSONL entry in `.gsd/runtime/do-next-runner/` |
| Push | No push command |

**Status:** DEFERRED — invoke `$do-next-runner M001 S03 T03` in agent session for full implementation path; infra pre-checks PASS (smoke, MCP orient, push-gate, report helper).

### V4 — Max-units cap

```text
$do-next-runner M001 S03 --max-units 2
```

| Check | Expected |
| --- | --- |
| Units run | Exactly 2 |
| Stop message | Resume hint with scope |

**Status:** _pending execution_

### V5 — Push block

| Check | Expected |
| --- | --- |
| Slice plan | No `push_after_slice: true` |
| Slice complete | Local commit only |
| Remote | No `git push` |

**Status:** PASS (2026-06-07) — `push-gate.py --milestone M001 --slice S03` exit 1, BLOCKED message

### V6 — Personal skill install

```bash
.gsd/idea/do-next-runner/scripts/install-personal-skill.sh
```

| Check | Expected |
| --- | --- |
| Target | `~/.cursor/skills/do-next-runner/SKILL.md` exists |
| Content | Matches idea template |

**Status:** PASS (2026-06-07) — `~/.cursor/skills/do-next-runner/SKILL.md` installed

### V7 — Installer dry-run (project + all IDEs)

```bash
.gsd/idea/do-next-runner/scripts/install-workflow-tools.sh \
  --dry-run --project --cursor --claude --copilot --repo .
```

| Check | Expected |
| --- | --- |
| Output | `WRITE` lines for all four tools × Cursor/Claude/Copilot targets |
| Mutations | No files created (`--dry-run`) |

### V8 — Installer project install (all IDEs)

```bash
.gsd/idea/do-next-runner/scripts/install-workflow-tools.sh \
  --project --cursor --claude --copilot --repo . --copy
```

| Check | Expected |
| --- | --- |
| Cursor | `.cursor/skills/{do-next,do-next-runner,gsd-plan-milestone,gsd-advance-unit}/SKILL.md` |
| Claude | `.claude/skills/*` symlinks → `.cursor/skills/*` |
| Copilot | `.github/instructions/{do-next,do-next-runner,gsd-plan-milestone,gsd-advance-unit}.instructions.md` |
### V9 — Cursor dry-run (existing V1)

See **V1** — `$do-next-runner M001 S03 --dry-run`.

### V10 — Claude dry-run

Same as V1 via Claude Code with `.mcp.json` gsd-workflow server; orient + smoke only, no mutations.

**Status:** _manual — requires Claude Code session_

### V11 — Copilot orient

Chat: *"do next --dry-run M001 S03"* — loads `.github/instructions/do-next.instructions.md`; orient + smoke only.

**Status:** _manual — requires Copilot session_

### V12 — Personal install (multi-IDE)

```bash
.gsd/idea/do-next-runner/scripts/install-workflow-tools.sh --personal --cursor --claude --dry-run
```

| Check | Expected |
| --- | --- |
| Cursor | `~/.cursor/skills/do-next-runner/SKILL.md` (and siblings) |
| Claude | `~/.claude/skills/do-next-runner` symlink or copy |

### V13 — ai-playbook bootstrap (fresh client)

```bash
# From ai-playbook repo
install-client-ai-overlay.sh --source-repo <ai-playbook> --client-repo <target> --platform ios
bootstrap-gsd-workflow.sh --source-repo <ai-playbook> --client-repo <target> --init-gsd --patch-mcp --with-do-next --check
```

| Check | Expected |
| --- | --- |
| `.gsd/workflow/` | Present |
| `.workflow/scripts/gsd-smoke.sh` | Present |
| Skills | Overlay symlinks or installer output |

**Status:** _manual — use disposable test clone_

### V14 — Selective IDE (Claude personal only)

```bash
ai-playbook/shared/gsd/scripts/install-workflow-tools.sh --personal --claude --dry-run
```

| Check | Expected |
| --- | --- |
| Cursor | No `WRITE` lines for `~/.cursor/skills` |
| Claude | `WRITE` lines for `~/.claude/skills/*` only |

### V15 — verify-sync (drift)

```bash
.gsd/idea/do-next-runner/scripts/verify-sync.sh .
```

| Check | Expected |
| --- | --- |
| Exit code | 0 |
| Message | PASS — assembled skills match templates |

## Results log

| Date | Test | Result | Notes |
| --- | --- | --- | --- |
| 2026-06-07 | V1 dry-run | PASS | Smoke PASS; gsd_progress → T03; no mutations |
| 2026-06-07 | V5 push block | PASS | push-gate.py exit 1 for S03 |
| 2026-06-07 | V6 personal install | PASS | install-personal-skill.sh |
| 2026-06-07 | append-run-report | PASS | JSONL + summary written |
| 2026-06-07 | V3 single task | DEFERRED | Full T03 impl via agent session |
| 2026-06-08 | V7 installer dry-run | PASS | All four tools × Cursor/Claude/Copilot |
| 2026-06-08 | V14 Claude personal dry-run | PASS | No Cursor personal paths |
| 2026-06-08 | V15 verify-sync | PASS | `verify-sync.sh .` exit 0 |
| 2026-06-08 | bootstrap --check | PASS | `.gsd/workflow`, gsd-workflow MCP |
