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
