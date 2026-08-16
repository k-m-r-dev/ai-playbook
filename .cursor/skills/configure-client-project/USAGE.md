# Using configure-client-project (from ai-playbook)

Playbook-operator skill - run from **this repo** (`ai-playbook`) to configure a **client checkout** elsewhere on disk.

The skill interviews in chat, then runs one orchestrator command: `scripts/configure-client-project.sh`. It does not call overlay, bootstrap, or W2C installers directly.

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

Read `[DISCOVER]`, `[MISSING]`, and `[PLACEHOLDER]` lines. The skill uses those to recommend platform and engine defaults, then flags in-scope gaps.

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
Configure client project /Users/khandkermahmudur/Workspace/self/relom
```

4. The agent will:
   - Run `configure-client-check.sh` for discovery.
   - Print a gap inventory including overlay, GSD, W2C scripts, and W2C Copilot gaps.
   - Ask for platform.
   - Ask for exactly one planning engine: `gsd`, `w2c`, or `none`.
   - Recommend `w2c` when discovery defaults to W2C, usually when no `.gsd` exists; otherwise recommend `gsd`.
   - Ask only the gap questions in scope for the selected engine.
   - Show a locked plan and ask for confirmation before writing.
   - Run `scripts/configure-client-project.sh` once, then verify.
   - Hand off based on engine: `gsd` -> `$gsd-plan-milestone`; `w2c` -> `work to chores`; `none` -> overlay only.

## Use without the skill (terminal only)

Run the same orchestrator directly:

```bash
bash scripts/configure-client-project.sh \
  --source-repo /path/to/ai-playbook \
  --client-repo /path/to/client \
  --platform flutter-riverpod \
  --engine w2c
```

Typical GSD example:

```bash
bash scripts/configure-client-project.sh \
  --source-repo /Users/khandkermahmudur/Workspace/self/ai-playbook \
  --client-repo /path/to/client-repo \
  --platform universal \
  --engine gsd \
  --mode symlink \
  --existing-policy merge \
  --init-gsd --with-do-next --patch-mcp --harness-context
```

Typical W2C example:

```bash
bash scripts/configure-client-project.sh \
  --source-repo /Users/khandkermahmudur/Workspace/self/ai-playbook \
  --client-repo /path/to/client-repo \
  --platform universal \
  --engine w2c \
  --mode symlink \
  --existing-policy merge
```

Overlay-only example:

```bash
bash scripts/configure-client-project.sh \
  --source-repo /Users/khandkermahmudur/Workspace/self/ai-playbook \
  --client-repo /path/to/client-repo \
  --platform universal \
  --engine none \
  --mode symlink \
  --existing-policy merge
```

## After configuration

| Engine | Where | Action |
| --- | --- | --- |
| `gsd` | Client repo chat | Run `$gsd-plan-milestone` with the feature or milestone description. |
| `w2c` | Client repo chat | Run `work to chores` to turn work into W2C chores. |
| `none` | Client repo | Overlay only; use the installed AI instructions without a planning-engine handoff. |

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| Skill not found | Run `update-personal-skill.sh configure-client-project`; reload Cursor. |
| Engine choice feels wrong | Check `[DISCOVER]` lines from `configure-client-check.sh`; choose `w2c` for new non-GSD projects, `gsd` when preserving existing `.gsd`, or `none` for overlay only. |
| GSD gaps shown after W2C/none | Expected; the skill reports them as `SKIPPED` because they are outside the selected engine. |
| W2C files missing after choosing W2C | Re-run the skill or orchestrator with `--engine w2c`; do not call `install-w2c-to-project.sh` directly from the skill. |
| Profile still has placeholders after GSD | Re-run the skill, choose `gsd`, and approve delivery-profile configuration. |

## What this skill does NOT do

- Install itself into client repos (playbook-operator only).
- Pick both GSD and W2C for the same configure run.
- Plan or execute milestones (`gsd` uses `$gsd-plan-milestone`; `w2c` uses `work to chores`).
- Replace `gsd-config` (upstream GSD preferences).
