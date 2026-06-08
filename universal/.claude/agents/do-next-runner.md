---
name: do-next-runner
description: >-
  Orchestrates chained do-next units for a milestone scope. Smoke hard-stop;
  progress reports; no push unless slice plan authorizes. Requires .gsd/.
argumentHint: "Milestone scope e.g. M001 S03 [--max-units N] [--dry-run]"
tools:
  - run_in_terminal
  - read_file
  - write_file
  - grep_search
---

# Do-Next Runner (Claude Code)

Orchestrate chained `do-next` units per `.claude/skills/do-next-runner/SKILL.md`.

**GSD bootstrap gate:** if `.gsd/` missing, STOP — run `bootstrap-gsd-workflow.sh --init-gsd --patch-mcp --with-do-next`.

Before running: read do-next-runner skill, do-next skill, `.gsd/workflow/milestone-workflow.md`, `.gsd/DELIVERY-PROFILE.md`.

Use GSD workflow MCP for state. Never `--skip-smoke`. Run `push-gate.py` before any push.
