# Work-to-chores / do-chores

Markdown planning and execution. Plans live as markdown under `.w2c/` in the **client repo**. A Python CLI is the only writer of status bits (STATE, QUEUE, ROADMAP emojis, task checkboxes).

## How to use (plain English)

**Plan:** Say `work to chores` (or `/work-to-chores`) and paste a ticket, spec, or a short description of the work. The agent will interview you, check the codebase, and write a plan under `.w2c/`. It will not change product code.

**Do:** Say `do chores` to do the next small task in that plan. Add `M011` or `S02` to stay inside that scope. Add `--max-units 5` to do several tasks in a row. Add `--dry-run` to see the next task without doing it.

**Need first:** grilling and brainstorming for planning; requesting-code-review for doing. If any of those are missing, the skill stops and tells you to add them. Worktree isolation also requires **using-git-worktrees**.

**Need in the repo:** `.w2c/scripts/` from `scripts/install-w2c-to-project.sh`. If scripts are missing, the skill stops and prints that command.

Cursor and Claude pick the skills up from `~/.agents/skills` after hub install. Copilot only sees them after the project installer writes `.github/instructions/`.

## Git isolation

Every milestone `M###-ROADMAP.md` and slice `M###-S##-PLAN.md` must include a **`## Git Operation Plan`** table.

- **Modes:** `worktree` or `branch` only (no in-place).
- **Branch names:** Local branch == Remote branch == external ticket id (e.g. `MOR-252`) or a confirmed slug when there is no ticket.
- **Scope:** one isolation per ticket; reuse across milestones.
- **Timing:** plan in the current checkout; create/reuse isolation on the **first `do-chores`**. For `worktree`, the executor must invoke **using-git-worktrees** (hard stop if missing).
- **Plan commit:** after writing plans, `work-to-chores` asks approval to commit only `.w2c/` ledger/plan files onto the ticket branch (never `runtime/`, never product code, no push) so a worktree can see the ledger.
- **Push:** after milestone verification, only with explicit user approval, to `origin/<Remote branch>` exactly.

`w2c smoke` **FAIL**s when the Git Operation Plan is missing, Isolation mode is invalid, Local≠Remote, branch is empty/`N/A`, worktree mode lacks `using-git-worktrees` in the Worktree skill field, or a slice disagrees with its milestone. Older plans without this section must be updated (re-run work-to-chores or add the section manually) before smoke/handoff will pass.

The CLI does **not** run git mutations; skills instruct the agent.

## Install

Personal hub (Cursor + Claude):

```bash
bash scripts/install-personal-agents-hub.sh --force --skills work-to-chores,do-chores
# or
bash scripts/update-personal-skill.sh work-to-chores
bash scripts/update-personal-skill.sh do-chores
```

Client repo (Copilot instructions + CLI scripts):

```bash
bash scripts/install-w2c-to-project.sh --repo /path/to/client
```

That copies:

- `.github/instructions/work-to-chores.instructions.md`
- `.github/instructions/do-chores.instructions.md`
- `.w2c/scripts/` (`w2c.py`, `w2c.sh`, `w2c-smoke.py`, `w2c-smoke.sh`)
- a `.gitignore` entry for `.w2c/runtime/`

It does **not** overwrite an existing `DECISIONS.md` or `STATE.md`.

## CLI

From the client repo:

```bash
python3 .w2c/scripts/w2c.py <command>
# or
.w2c/scripts/w2c.sh <command>
```

| Command | Purpose |
| --- | --- |
| `init` | Create ledger stubs if missing |
| `status` | Print STATE.md |
| `next [--milestone M###] [--slice S##] [--task T##]` | Next open task |
| `complete --milestone M### --slice S## --task T##` | Mark task done (requires `S##-T##-SUMMARY.md`; does not close the slice) |
| `slice-complete --milestone M### --slice S##` | Mark slice done (requires `S##-UAT.md` + `S##-SUMMARY.md`) |
| `milestone-complete M###` | Mark milestone DONE (requires `M###-VALIDATION.md` + `M###-SUMMARY.md`) |
| `set --active-milestone M### [--active-slice S##] [--phase NAME]` | Update active pointer |
| `milestone-status M### PLANNING\|TODO\|PAUSED\|INPROGRESS\|DONE\|ERROR\|STOP` | Set milestone emoji/status |
| `next-milestone-id` | Next unused `M###` |
| `milestone-new --slug SLUG` | Allocate id and create plan folder stubs |
| `decide --scope … --decision … --choice … --rationale …` | Append a DECISIONS.md row |
| `context-new --major\|--minor` | New `contexts/CONTEXTvX.Y.md` (never overwrite) |
| `event --skill … --stage … --event …` | Append one local runtime event |
| `events [--tail N] [--skill …]` | Print last N local events (`0` = all) |
| `smoke` | Ledger coherence checks (includes Git Operation Plan field checks) |

Agents must not hand-edit STATE.md, QUEUE.md, ROADMAP status emojis, or `[ ]` / `[x]` on tasks.

**Closeout reports are committed** with the plan folder (`S##-T##-SUMMARY.md`, `S##-UAT.md`, `S##-SUMMARY.md`, `M###-VALIDATION.md`, `M###-SUMMARY.md`). The CLI will not flip the matching status bit until those files exist.

**Events are local-only.** They live at `.w2c/runtime/events.jsonl`, which is gitignored. Do not commit logs.

## Source of truth in this playbook

```text
shared/w2c/
  README.md
  personal-skills.manifest
  templates/
  scripts/
  skills/work-to-chores/
  skills/do-chores/
```

Author these skills only under `shared/w2c/`.
