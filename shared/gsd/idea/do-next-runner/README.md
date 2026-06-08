# Do-Next Runner

Portable milestone execution orchestrator for GSD + `do-next` workflow.

## What it does

Chains `do-next` units for a milestone scope with:

- Mandatory smoke before every unit
- Hard stop on smoke/validation/gate failures
- Async progress reports (JSONL + markdown)
- No remote push unless slice plan authorizes

## Quick start (this repo)

```text
$do-next-runner M001 S03 --dry-run
$do-next-runner M001 S03 T03
$do-next-runner M001 S03 --max-units 5
```

Or spawn the agent: `@do-next-runner M001 S03`

## Adopt in another project

1. Copy `.gsd/idea/do-next-runner/` into the target repo
2. Ensure `.gsd/workflow/` + `DELIVERY-PROFILE.md` exist ([workflow README](../../workflow/README.md))
3. Ensure `.workflow/scripts/gsd-smoke.sh` exists
4. Install personal skill:

   ```bash
   .gsd/idea/do-next-runner/scripts/install-personal-skill.sh
   ```

5. Copy agent template:

   ```bash
   cp .gsd/idea/do-next-runner/templates/agent.md .cursor/agents/do-next-runner.md
   ```

6. Copy or symlink project skill:

   ```bash
   mkdir -p .cursor/skills/do-next-runner
   cp .gsd/idea/do-next-runner/templates/SKILL.md .cursor/skills/do-next-runner/SKILL.md
   ```

7. Create runtime dir: `mkdir -p .gsd/runtime/do-next-runner`
8. Add row to `AGENTS.md` execution triggers (see PLAN.md)

## Files

| File | Purpose |
| --- | --- |
| [CONTEXT.md](CONTEXT.md) | Requirements and constraints |
| [RESEARCH.md](RESEARCH.md) | Pattern analysis |
| [PLAN.md](PLAN.md) | Canonical spec |
| [VERIFICATION.md](VERIFICATION.md) | UAT checklist |
| [templates/SKILL.md](templates/SKILL.md) | Portable skill source |
| [templates/agent.md](templates/agent.md) | Cursor agent definition |
| [scripts/install-personal-skill.sh](scripts/install-personal-skill.sh) | Install to `~/.cursor/skills/` |
| [scripts/append-run-report.py](scripts/append-run-report.py) | Run log helper |
| [scripts/push-gate.py](scripts/push-gate.py) | Slice push authorization check |

## vs do-next

| | `do next` | `do-next-runner` |
| --- | --- | --- |
| Units per invocation | 1 | Many (capped) |
| Task Handoff Gate | Pause | Auto-continue |
| Smoke | Default (skippable) | Always required |
| Push | User approval | Slice plan only |

Interactive work: use `do next`. Batch execution: use `$do-next-runner`.
