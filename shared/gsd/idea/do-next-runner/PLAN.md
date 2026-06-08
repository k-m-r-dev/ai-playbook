# Do-Next Runner — Plan (canonical spec)

See attached plan in `.cursor/plans/do-next_runner_agent_609bf43f.plan.md` for the full orchestration diagram and implementation sequence.

This file is the **repo-local canonical copy** of the idea spec. Do not edit the Cursor plan file; update this file when the spec evolves.

## Invocation

```
$do-next-runner [M###] [S##] [T##] [--max-units N] [--dry-run]
```

| Argument | Behavior |
| --- | --- |
| `M001` | Run from pending slice/task through milestone completion |
| `M001 S03` | Run only S03 |
| `M001 S03 T02` | Single task unit then stop |
| `--max-units N` | Safety cap (default 25) |
| `--dry-run` | Orient + smoke + route only |

## Loop (per unit)

1. **Orient** — `gsd_progress` (+ `gsd_milestone_status`)
2. **Smoke** — `.workflow/scripts/gsd-smoke.sh --milestone {M###}` — STOP on FAIL
3. **Route** — one of 2a/2b/2c/2d/2e per do-next
4. **Execute** — implement, verify, MCP complete
5. **Report** — append JSONL + summary (async-friendly)
6. **Continue** — if scope has more units and under max-units

## Push gate

Only when `S##-PLAN.md` contains:

```markdown
## Delivery
- push_after_slice: true
```

## Artifacts

| Path | Purpose |
| --- | --- |
| `.gsd/idea/do-next-runner/` | Source of truth (this directory) |
| `.cursor/skills/do-next-runner/SKILL.md` | Project skill |
| `.cursor/agents/do-next-runner.md` | Spawnable agent |
| `.gsd/runtime/do-next-runner/` | Run logs |
| `~/.cursor/skills/do-next-runner/` | Personal skill (via install script) |

## Verification

See [VERIFICATION.md](VERIFICATION.md).
