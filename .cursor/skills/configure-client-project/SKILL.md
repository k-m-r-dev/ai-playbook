---
name: configure-client-project
description: Playbook-operator skill. Configure a client repo for GSD workflow from ai-playbook — discover stack, dry-check, flag every gap and ask yes/no to fix each one, run overlay + bootstrap + MCP merge, fill DELIVERY-PROFILE, verify health. Use when bringing up a client checkout (e.g. email-sender, relom) from the playbook workspace. Trigger phrases — configure client, bootstrap client, set up GSD for, configure delivery profile for.
---

# Configure Client Project (playbook-operator)

Orchestrate full GSD client bring-up from the **ai-playbook** workspace. This skill is **not** installed in client repos — it runs when you configure a target checkout path from playbook.

## When to use

- New client repo needs overlay + `.gsd/workflow` + `DELIVERY-PROFILE.md`
- Existing client has placeholder delivery profile, missing workflow, or missing MCP servers
- You want guided setup with verification before `$gsd-plan-milestone`

## When NOT to use

- Planning or executing milestones inside an already-configured client — use `$gsd-plan-milestone` / `do next`
- Upstream GSD prefs (`gsd-config`) — different layer

## Hard rules

1. **One interview question at a time** — wait for the user's answer before the next question.
2. **Every option gets a plain-English explanation** — no jargon without context.
3. **Recommend a default** on each question; mark it `[recommended]`.
4. **Look up facts** (stack, git branch, existing files) — do not ask the user what you can discover.
5. **Flag every gap** from discovery — never silently skip a `MISSING` / `PLACEHOLDER` item.
6. **Ask yes/no to fix each gap** before writing — do not dump “merge manually later” for gaps the user can approve now.
7. **Do not guess** delivery-profile fields — interview when fixing the profile.
8. **Do not append** `CLAUDE.md` / `AGENTS.md` wrapper content into `DELIVERY-PROFILE.md`.
9. **Summarize locked choices** and get confirmation before any write commands.
10. **Only hand off deferred work** for gaps the user explicitly declined.

## Paths

| Variable | Default |
| --- | --- |
| `PLAYBOOK_ROOT` | ai-playbook workspace root (where `scripts/bootstrap-gsd-workflow.sh` lives) |
| `CLIENT_REPO` | Absolute path to target client checkout |

Scripts (from `PLAYBOOK_ROOT`):

- `scripts/configure-client-check.sh` — read-only preflight
- `scripts/install-client-ai-overlay.sh` — overlay install
- `scripts/bootstrap-gsd-workflow.sh` — GSD workflow bootstrap
- `scripts/merge-mcp-template.sh` — merge missing MCP servers into existing `.mcp.json`

## Phase 0 — Preconditions

1. Confirm `PLAYBOOK_ROOT` contains `shared/gsd/` and `scripts/bootstrap-gsd-workflow.sh`.
2. Require **absolute** `CLIENT_REPO`; verify directory exists.
3. Verify `CLIENT_REPO` is a git repo (`git -C "$CLIENT_REPO" rev-parse --git-dir`).
4. If `CLIENT_REPO` is inside `PLAYBOOK_ROOT`, stop unless user explicitly opts in to dogfood.

## Phase 1 — Discover (read-only)

Run:

```bash
bash "$PLAYBOOK_ROOT/scripts/configure-client-check.sh" \
  --source-repo "$PLAYBOOK_ROOT" \
  --client-repo "$CLIENT_REPO"
```

Capture every `[OK]`, `[MISSING]`, `[PLACEHOLDER]`, `[CONFIGURED]`, and `[DISCOVER]` line.

## Phase 2 — Dry check + gap inventory

Run:

```bash
bash "$PLAYBOOK_ROOT/scripts/bootstrap-gsd-workflow.sh" \
  --source-repo "$PLAYBOOK_ROOT" \
  --client-repo "$CLIENT_REPO" \
  --check
```

**Before asking any configuration question**, print a **Gap inventory** table of all non-OK items. Example:

| Gap ID | Status | What it means |
| --- | --- | --- |
| `overlay` | MISSING | No playbook overlay (`_AGENTS.md`) |
| `workflow` | MISSING | No `.gsd/workflow/` rules pack |
| `gsd.db` | MISSING | No GSD database |
| `delivery-profile` | PLACEHOLDER / MISSING | Delivery settings not filled |
| `gsd-workflow-mcp` | MISSING | Ledger MCP not in `.mcp.json` |
| `playbook-gsd-mcp` | MISSING | do-next claim bridge not in `.mcp.json` |
| `do-next-health` | MISSING | Health script for do-next not installed |
| `workflow-dir` | MISSING | `.workflow/` session scripts missing |

If there are **zero gaps**, say so and ask whether to re-interview delivery profile only (or stop).

Then say: “I will ask about each gap one at a time — yes to fix now, no to leave as-is.”

## Phase 3 — Gap + delivery interview

### 3A — Platform (always ask once)

Which playbook platform pack?

1. **universal** — backend, frontend, desktop, infra, or generic. `[recommended]` when no mobile markers.
2. **ios** / **android** / **flutter-riverpod** / **flutter-bloc** — as detected.

### 3B — One question per gap (only for gaps that exist)

For **each** row in the gap inventory, ask separately. Skip gaps that are already OK.

#### Gap: `overlay`

Install the AI overlay (skills + `_AGENTS.md` wrappers)?

1. **yes** — run `install-client-ai-overlay.sh`. `[recommended]` when missing.
2. **no** — leave without overlay.

#### Gap: `workflow` / `workflow-dir` / `do-next-health`

These are usually fixed together via bootstrap. Ask:

Install / refresh GSD workflow files under `.gsd/workflow/` (and related scripts)?

1. **yes** — bootstrap will copy workflow. `[recommended]` when workflow missing.
2. **no** — leave missing.

If workflow fix = yes, also ask **do-next stack**:

Also install do-next packages + `playbook-gsd-health.sh`?

1. **yes** — `--with-do-next`. `[recommended]` when you want agent-driven do-next (also implies claim bridge).
2. **no** — workflow only; pure GSD / `$gsd-advance-unit`.

#### Gap: `gsd.db`

Initialize GSD database (`--init-gsd`)?

1. **yes** — `[recommended]` when `gsd.db` missing and `gsd` is on PATH.
2. **no** — skip.

#### Gap: `gsd-workflow-mcp`

Add **gsd-workflow** (GSD ledger MCP) to `.mcp.json`?

1. **yes** — create or merge via `merge-mcp-template.sh` / `--patch-mcp`. `[recommended]` when missing.
2. **no** — leave without ledger MCP (planning/execution skills will stop).

#### Gap: `playbook-gsd-mcp`

Add **playbook-gsd** (do-next claim/publish bridge) to `.mcp.json`?

1. **yes** — merge into existing `.mcp.json` (does not overwrite other servers). `[recommended]` when do-next = yes or gap is missing and user wants do-next.
2. **no** — leave missing; do-next claim bridge will not work.

**Never** defer this to a post-setup “merge manually” note if the user answered **yes**.

#### Gap: `delivery-profile` (MISSING or PLACEHOLDER)

Configure delivery profile now?

1. **yes** — ask Q-delivery (strategy, branch, cadence, review, tickets) one at a time. `[recommended]`.
2. **no** — leave placeholder / missing (agents may stop at planning).

If yes, ask the five delivery questions (same plain-English options as bootstrap `--interactive`):

- Integration strategy: `trunk-direct` / `feature-branch`
- Integration branch: `main` / `develop` / other
- Commit cadence: `slice` / `milestone`
- Review unit: adapt to strategy (`none` / `pr-per-milestone` / `pr-per-slice`)
- External tickets: `none` / Linear / JIRA / GitHub Issues / other

Derive checkpoint mode from review unit.

#### Optional (not always a gap): harness context

Seed platform `platform.md` via `--harness-context`?

1. **yes** — `[recommended]` on first bring-up.
2. **no**.

### 3C — Confirmation gate

Print a **locked plan**:

- Platform
- Each gap → FIX / SKIP
- Bootstrap flags that will run
- Delivery profile values (if configuring)

Wait for explicit user confirmation before Phase 4.

## Phase 4 — Execute

Only after confirmation. Execute **only** approved fixes.

### 4a — Overlay (if approved)

```bash
bash "$PLAYBOOK_ROOT/scripts/install-client-ai-overlay.sh" \
  --source-repo "$PLAYBOOK_ROOT" \
  --client-repo "$CLIENT_REPO" \
  --platform "$PLATFORM" \
  --mode symlink \
  --existing-policy merge
```

### 4b — Bootstrap (if workflow / init / do-next / harness approved)

```bash
bash "$PLAYBOOK_ROOT/scripts/bootstrap-gsd-workflow.sh" \
  --source-repo "$PLAYBOOK_ROOT" \
  --client-repo "$CLIENT_REPO" \
  --platform "$PLATFORM" \
  --project-style auto \
  [--init-gsd] [--with-do-next] [--patch-mcp] [--harness-context] [--force]
```

- Pass `--patch-mcp` if user approved **either** `gsd-workflow-mcp` or `playbook-gsd-mcp` (bootstrap merges missing servers via `merge-mcp-template.sh`).
- Do **not** pass `--interactive` when the agent writes the profile in Phase 5.

### 4c — MCP merge (if MCP gaps approved and still missing after bootstrap)

```bash
bash "$PLAYBOOK_ROOT/scripts/merge-mcp-template.sh" \
  --source-repo "$PLAYBOOK_ROOT" \
  --client-repo "$CLIENT_REPO" \
  --servers "gsd-workflow,playbook-gsd"
```

Pass only the servers the user approved. Existing servers are never overwritten.

## Phase 5 — Write DELIVERY-PROFILE (if approved)

Patch `$CLIENT_REPO/.gsd/DELIVERY-PROFILE.md` with interviewed fields.

Rules:

- Preserve `<!-- BEGIN AUTO:PROJECT-VALIDATION -->` block from bootstrap.
- Never append `@_CLAUDE.md` / `@_AGENTS.md` sections.
- If profile was already configured and user did not approve overwrite, skip.

## Phase 6 — Verify

Re-run:

```bash
bash "$PLAYBOOK_ROOT/scripts/configure-client-check.sh" \
  --source-repo "$PLAYBOOK_ROOT" \
  --client-repo "$CLIENT_REPO"
```

Report **PASS / FAIL / SKIPPED** per gap:

| Result | Meaning |
| --- | --- |
| PASS | Gap was approved and is now OK |
| FAIL | Gap was approved but still broken — fix or remediate now |
| SKIPPED | User said no — list under deferred |

**Do not** mark an approved MCP merge as PASS with a “merge manually later” note. If still MISSING after execute → FAIL and remediate in-session.

If do-next + health script approved:

```bash
bash "$CLIENT_REPO/.workflow/scripts/playbook-gsd-health.sh"
```

## Phase 7 — Handoff

Print:

1. Summary of what was fixed.
2. **Deferred gaps only** (user said no) — optional next steps.
3. Open client in Cursor; run **`$gsd-plan-milestone`**.

**Forbidden handoff lines** when the user approved the fix:

- “Merge playbook-gsd into `.mcp.json` manually…”
- “Edit paths in the template yourself…”

Those are only valid under **Deferred** when the user chose **no**.

## Anti-patterns

- Skipping the gap inventory and jumping to delivery questions
- Asking multiple gap questions in one message
- Treating “`.mcp.json` exists” as “MCP is fine” without checking `playbook-gsd`
- Leaving approved gaps as homework
- Installing this skill into client repos via `install-workflow-tools.sh`
