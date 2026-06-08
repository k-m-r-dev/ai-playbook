# Do-Next Runner — Context

## Summary

Portable orchestrator that chains `do-next` workflow units for a scoped milestone, slice, or task. Project-management infrastructure reusable across repos — not product milestone work.

## Problem

`do next` advances **one unit per chat turn** and pauses at the Task Handoff Gate. For long execute phases (many tasks in a slice), manually saying `do next` dozens of times is slow and loses momentum.

## Solution

`$do-next-runner` wraps `do-next` in a controlled loop:

- Smoke gate before every unit (never `--skip-smoke`)
- Hard stop on smoke FAIL, validation FAIL, or gate `flag`
- Async progress reports after each successful unit
- No remote push unless slice plan explicitly authorizes

## Requirements

| ID | Requirement |
| --- | --- |
| R1 | Accept scope: `M###`, `M### S##`, `M### S## T##` |
| R2 | Run smoke before every unit via `.workflow/scripts/gsd-smoke.sh` |
| R3 | Stop immediately on smoke FAIL with gap report; no auto-sync |
| R4 | Delegate execution to `do-next` phases 0 → 0.5 → 1 → 2x → 3 |
| R5 | Emit async progress report after each successful task/slice/gate unit |
| R6 | Never `git push` / `gh pr create` unless `S##-PLAN.md` has `push_after_slice: true` |
| R7 | Respect `DELIVERY-PROFILE.md` commit cadence (slice commits, not per-task) |
| R8 | Safety cap via `--max-units` (default 25) |
| R9 | `--dry-run` for orient + smoke + route without mutations |
| R10 | Portable across projects via idea template + personal skill install |

## Auto-continue contract

The Task Handoff Gate in `.gsd/workflow/milestone-workflow.md` normally pauses for `do next`. **Overridden only** when the user explicitly invokes `$do-next-runner`. That invocation is explicit multi-unit consent (same as `do next` anti-pattern exception for "run N steps").

Interactive single-step work still uses `do next`.

## Constraints (non-negotiable)

- Do not invent a parallel execution path — delegate to `do-next`
- Do not use `gsd_execute`, terminal `/gsd next`, or `gsd-next-cursor`
- Do not auto-sync markdown ↔ DB on drift
- Do not edit `.gsd/gsd.db` or `.gsd/STATE.md` directly — MCP + `--rebuild-state`
- Do not push without slice-level authorization in plan
- If GSD MCP unavailable, stop (never guess from markdown alone)

## Stakeholders

- Developer running milestone execution in Cursor
- GSD workflow MCP for state persistence
- Abstract workflow in `.gsd/workflow/` (project-agnostic)
- Per-project `DELIVERY-PROFILE.md` for validation and commit rules

## Success criteria

1. `$do-next-runner M001 S03 --dry-run` produces orient + smoke + route without edits
2. Smoke FAIL stops the runner with gap report
3. Successful task unit appends JSONL entry under `.gsd/runtime/do-next-runner/`
4. Slice complete commits locally but does not push without `push_after_slice: true`
5. Skill installable to `~/.cursor/skills/do-next-runner/` for cross-project reuse
