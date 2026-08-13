# Using configure-client-project (from ai-playbook)

Playbook-operator skill — run from **this repo** (`ai-playbook`) to configure a **client checkout** elsewhere on disk.

## One-time setup

Install the skill into your personal hub (Cursor + Claude bridges):

```bash
cd /Users/khandkermahmudur/Workspace/self/ai-playbook
bash scripts/update-personal-skill.sh configure-client-project
```

Reload Cursor (or start a new chat) so `/configure-client-project` is available.

## Quick preflight (no writes)

Before involving the agent, inspect a client repo:

```bash
bash scripts/configure-client-check.sh \
  --source-repo /Users/khandkermahmudur/Workspace/self/ai-playbook \
  --client-repo /path/to/client-repo
```

Example (email-sender):

```bash
bash scripts/configure-client-check.sh \
  --source-repo /Users/khandkermahmudur/Workspace/self/ai-playbook \
  --client-repo /Users/khandkermahmudur/Workspace/fieldnation/email-sender
```

Read `[MISSING]` / `[PLACEHOLDER]` lines — those are what the skill will fix.

## Use the skill in Cursor (recommended)

1. Open the **ai-playbook** workspace in Cursor (this repo).
2. Start a new agent chat.
3. Invoke with the client path:

```
/configure-client-project

Configure /Users/khandkermahmudur/Workspace/fieldnation/email-sender
```

Or plain English:

```
Set up GSD for /Users/khandkermahmudur/Workspace/self/relom
```

4. The agent will:
   - Run `configure-client-check.sh` (discover)
   - Run `bootstrap-gsd-workflow.sh --check` (dry check)
   - Print a **gap inventory** of everything MISSING / PLACEHOLDER
   - Ask **one gap at a time** — yes/no to fix each (overlay, workflow, gsd.db, gsd-workflow MCP, playbook-gsd MCP, delivery profile, …)
   - Show a summary and ask **confirm before writing**
   - Run only approved fixes (overlay, bootstrap, MCP merge, DELIVERY-PROFILE), verify, hand off
   - List under **Deferred** only gaps you declined — not leftover homework for approved items

5. After handoff, **open the client repo** in Cursor and run `$gsd-plan-milestone`.

## Use without the skill (terminal only)

If you prefer shell prompts for delivery profile only:

```bash
bash scripts/bootstrap-gsd-workflow.sh \
  --source-repo /Users/khandkermahmudur/Workspace/self/ai-playbook \
  --client-repo /path/to/client-repo \
  --platform universal \
  --init-gsd --with-do-next --patch-mcp \
  --interactive
```

`--interactive` needs a real terminal (TTY). In Cursor agent chat, use the skill instead — it interviews in chat and writes the profile.

## Typical full bring-up (what the skill runs)

Equivalent manual sequence (for reference):

```bash
PLAYBOOK=/Users/khandkermahmudur/Workspace/self/ai-playbook
CLIENT=/path/to/client-repo

# 1. Overlay (if needed)
bash "$PLAYBOOK/scripts/install-client-ai-overlay.sh" \
  --source-repo "$PLAYBOOK" --client-repo "$CLIENT" \
  --platform universal --mode symlink --existing-policy merge

# 2. GSD workflow bootstrap
bash "$PLAYBOOK/scripts/bootstrap-gsd-workflow.sh" \
  --source-repo "$PLAYBOOK" --client-repo "$CLIENT" \
  --platform universal --init-gsd --with-do-next --patch-mcp --harness-context

# 3. Delivery profile — skill fills this in chat, or use --interactive in terminal
```

## After configuration

| Step | Where | Action |
| --- | --- | --- |
| MCP | Client repo | Ensure `.mcp.json` has approved servers (`gsd-workflow`, `playbook-gsd` if you said yes) |
| Open project | Client repo | `cursor /path/to/client-repo` |
| Plan | Client chat | `$gsd-plan-milestone` + feature description |
| Execute | Client chat | `do next` or `$do-next-runner` |

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| Skill not found | Run `update-personal-skill.sh configure-client-project`; reload Cursor |
| `--interactive` skipped | Normal in agent chat — use the skill, not `--interactive` |
| `.mcp.json` missing playbook-gsd | Re-run skill and answer **yes** to the playbook-gsd gap; or `bash scripts/merge-mcp-template.sh --source-repo <playbook> --client-repo <client>` |
| Profile still has `main or develop` | Re-run skill or `bootstrap --interactive --force` |
| Health check fails | Set `PLAYBOOK_ROOT` in client's `playbook-gsd-health.sh` or env when running from client |

## What this skill does NOT do

- Install itself into client repos (playbook-operator only)
- Plan or execute milestones (use `$gsd-plan-milestone` / `do next` in the client repo)
- Replace `gsd-config` (upstream GSD preferences)
