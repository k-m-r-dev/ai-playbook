# shared/gsd — GSD milestone workflow bootstrap pack

Canonical source for GSD workflow rules, do-next tooling, and multi-IDE skill templates.

## Layout

| Path | Purpose |
| --- | --- |
| `workflow/` | Abstract milestone rules → copied to client `.gsd/workflow/` |
| `templates/` | `DELIVERY-PROFILE.md`, `DECISIONS.md` starters |
| `skills/` | IDE-neutral skill bodies (`gsd-plan-milestone`, `gsd-advance-unit`) |
| `idea/do-next/` | do-next skill templates + assembly |
| `idea/do-next-runner/` | Runner templates, scripts (`push-gate.py`, etc.) |
| `scripts/` | `bootstrap-gsd-workflow.sh` helpers, smoke, installer |

## Readiness ladder

```text
1. install-client-ai-overlay.sh     → skills (symlinked)
2. bootstrap-gsd-workflow.sh        → .gsd/ REQUIRED
3. $gsd-plan-milestone              → ROADMAP
4. do next / $do-next-runner        → custom workflow execution
   — or $gsd-advance-unit           → pure GSD one unit
```

## Bootstrap (client repo)

```bash
bash /path/to/ai-playbook/scripts/bootstrap-gsd-workflow.sh \
  --source-repo /path/to/ai-playbook \
  --client-repo /path/to/client \
  --platform universal \
  --harness-context \
  --init-gsd --with-do-next --patch-mcp
```

`--platform` + `--harness-context` seed **platform-specific** `.gsd/DELIVERY-PROFILE.md` and
`.cursor/skills/*/platform.md` from `templates/platforms/<platform>/`. Always customize for the client.

## Harness project context only

```bash
bash shared/gsd/scripts/harness-gsd-project-context.sh \
  --source-repo /path/to/ai-playbook \
  --client-repo /path/to/client \
  --platform universal
```

## Install skills only (no overlay)

```bash
bash shared/gsd/scripts/install-workflow-tools.sh \
  --project --cursor --claude --copilot \
  --repo /path/to/client
```

## Personal global skills

```bash
bash shared/gsd/scripts/install-workflow-tools.sh --personal --cursor --claude
```
