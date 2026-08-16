---
name: configure-client-project
description: Playbook-operator skill. Configure a client repo from ai-playbook with exclusive planning engine gsd, w2c, or none — discover stack, flag gaps, confirm, then run scripts/configure-client-project.sh. Use when bringing up a client checkout from the playbook workspace.
---

# Configure Client Project (playbook-operator)

Configure a client checkout from the **ai-playbook** workspace. This skill is **not** installed in client repos - it runs as a playbook operator and wraps `scripts/configure-client-project.sh`.

## When to use

- New client repo needs the AI overlay plus one exclusive planning choice: GSD, W2C, or none.
- Existing client has overlay, GSD, or W2C gaps and needs a guided configure pass.
- You want discovery, gap review, confirmation, one orchestrator command, verification, and the right handoff.

## When NOT to use

- Planning or executing work inside an already-configured client - use `$gsd-plan-milestone` for GSD or `work to chores` for W2C.
- Upstream GSD prefs (`gsd-config`) - different layer.

## Hard rules

1. **One interview question at a time** - wait for the user's answer before the next question.
2. **Every option gets a plain-English explanation** - no jargon without context.
3. **Recommend a default** on each question; mark it `[recommended]`.
4. **Look up facts** (stack, git branch, existing files) - do not ask the user what you can discover.
5. **Flag every in-scope gap** from discovery - never silently skip an engine-selected `MISSING` / `PLACEHOLDER` item; list out-of-scope engine gaps as `SKIPPED`.
6. **Ask yes/no to fix each gap** before writing - do not dump "merge manually later" for gaps the user can approve now.
7. **Do not guess** delivery-profile fields - interview when fixing the profile.
8. **Do not append** `CLAUDE.md` / `AGENTS.md` wrapper content into `DELIVERY-PROFILE.md`.
9. **Summarize locked choices** and get confirmation before any write commands.
10. **Only hand off deferred work** for gaps the user explicitly declined.

## Paths

| Variable | Default |
| --- | --- |
| `PLAYBOOK_ROOT` | ai-playbook workspace root (where `scripts/configure-client-project.sh` lives) |
| `CLIENT_REPO` | Absolute path to target client checkout |

Scripts (from `PLAYBOOK_ROOT`):

- `scripts/configure-client-check.sh` - read-only preflight.
- `scripts/configure-client-project.sh` - **only command this skill executes for configuration writes**.
- `scripts/install-w2c-to-project.sh` - W2C installer called by the orchestrator for `--engine w2c`.
- `scripts/install-client-ai-overlay.sh` - overlay installer called by the orchestrator.
- `scripts/bootstrap-gsd-workflow.sh` - GSD bootstrap called by the orchestrator for `--engine gsd`.
- `scripts/merge-mcp-template.sh` - MCP merge helper called by the orchestrator/bootstrap.

## Phase 0 - Preconditions

1. Confirm `PLAYBOOK_ROOT` contains `shared/gsd/` and `scripts/configure-client-project.sh`.
2. Require **absolute** `CLIENT_REPO`; verify directory exists.
3. Verify `CLIENT_REPO` is a git repo (`git -C "$CLIENT_REPO" rev-parse --git-dir`).
4. If `CLIENT_REPO` is inside `PLAYBOOK_ROOT`, stop unless user explicitly opts in to dogfood.

## Phase 1 - Discover (read-only)

Run:

```bash
bash "$PLAYBOOK_ROOT/scripts/configure-client-check.sh" \
  --source-repo "$PLAYBOOK_ROOT" \
  --client-repo "$CLIENT_REPO"
```

Capture every `[OK]`, `[MISSING]`, `[PLACEHOLDER]`, `[CONFIGURED]`, and `[DISCOVER]` line.

## Phase 2 - Gap inventory

**Before asking any configuration question**, print a **Gap inventory** table from the check output. Include all non-OK items and the discovered default engine. Example:

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
| `w2c-scripts` | MISSING | W2C command scripts are not installed |
| `w2c-copilot` | MISSING | W2C Copilot instructions are not installed |

Also surface `[DISCOVER]` lines such as platform guess, GSD presence, W2C presence, and default engine. If there are **zero in-scope gaps**, say so and ask whether to run a no-op verification or stop.

Then say: "I will ask about the platform, the planning engine, and each in-scope gap one at a time - yes to fix now, no to leave as-is."

## Phase 3 - Interview

### 3A - Platform (always ask once)

Which playbook platform pack?

1. **universal** - backend, frontend, desktop, infra, or generic. `[recommended]` when no mobile markers.
2. **ios** / **android** / **flutter-riverpod** / **flutter-bloc** - as detected.

### 3B - Planning engine (always ask once)

Which planning engine should this client use?

1. **w2c** - install Work-to-Chores and the `.w2c/` markdown ledger. `[recommended]` when discovery says default engine is `w2c`, usually because there is no existing `.gsd`.
2. **gsd** - install the GSD workflow, optional do-next bridge, MCP support, and delivery profile. `[recommended]` when discovery says default engine is `gsd`, usually because `.gsd` already exists.
3. **none** - install overlay only; no GSD or W2C planning engine.

Only one engine may be selected. Never ask GSD gap questions when engine is `w2c` or `none`. Never ask W2C install questions when engine is `gsd` or `none`.

### 3C - Overlay gap (if missing)

Install the AI overlay (skills + `_AGENTS.md` / `_CLAUDE.md` wrappers)?

1. **yes** - pass overlay install through `configure-client-project.sh` using `--mode symlink --existing-policy merge`. `[recommended]` when missing.
2. **no** - leave without overlay; only valid if the user explicitly declines.

### 3D - GSD questions (engine = gsd only)

For each existing GSD gap, ask separately. Skip gaps that are already OK. List W2C gaps as out-of-scope `SKIPPED`.

#### Gap: `workflow` / `workflow-dir` / `do-next-health`

Install / refresh GSD workflow files under `.gsd/workflow/` and related scripts?

1. **yes** - pass workflow setup through the orchestrator. `[recommended]` when workflow is missing.
2. **no** - leave missing.

If workflow fix = yes, also ask **do-next stack**:

Also install do-next packages + `playbook-gsd-health.sh`?

1. **yes** - pass `--with-do-next`. `[recommended]` when you want agent-driven do-next (also implies claim bridge).
2. **no** - workflow only; pure GSD / `$gsd-advance-unit`.

#### Gap: `gsd.db`

Initialize GSD database (`--init-gsd`)?

1. **yes** - pass `--init-gsd`. `[recommended]` when `gsd.db` is missing and `gsd` is on PATH.
2. **no** - skip.

#### Gap: `gsd-workflow-mcp`

Add **gsd-workflow** (GSD ledger MCP) to `.mcp.json`?

1. **yes** - pass `--patch-mcp`; the orchestrator/bootstrap handles the merge. `[recommended]` when missing.
2. **no** - leave without ledger MCP (planning/execution skills will stop).

#### Gap: `playbook-gsd-mcp`

Add **playbook-gsd** (do-next claim/publish bridge) to `.mcp.json`?

1. **yes** - pass `--patch-mcp`; existing servers are not overwritten. `[recommended]` when do-next = yes or the user wants do-next.
2. **no** - leave missing; do-next claim bridge will not work.

**Never** defer this to a post-setup "merge manually" note if the user answered **yes**.

#### Gap: `delivery-profile` (MISSING or PLACEHOLDER)

Configure delivery profile now?

1. **yes** - ask Q-delivery (strategy, branch, cadence, review, tickets) one at a time. `[recommended]`.
2. **no** - leave placeholder / missing (agents may stop at planning).

If yes, ask the five delivery questions (same plain-English options as bootstrap `--interactive`):

- Integration strategy: `trunk-direct` / `feature-branch`
- Integration branch: `main` / `develop` / other
- Commit cadence: `slice` / `milestone`
- Review unit: adapt to strategy (`none` / `pr-per-milestone` / `pr-per-slice`)
- External tickets: `none` / Linear / JIRA / GitHub Issues / other

Derive checkpoint mode from review unit.

#### Optional (not always a gap): harness context

Seed platform `platform.md` via `--harness-context`?

1. **yes** - `[recommended]` on first bring-up.
2. **no**.

### 3E - W2C questions (engine = w2c only)

List GSD gaps as out-of-scope `SKIPPED`, not as questions.

Install full W2C now?

1. **yes** - run the orchestrator with `--engine w2c`; it calls `install-w2c-to-project.sh` and uses symlink mode to match overlay mode. `[recommended]`
2. **no** - do not configure W2C; ask whether the engine should be `none` instead before proceeding.

### 3F - None questions (engine = none only)

Do not ask GSD or W2C gap questions. List missing GSD/W2C lines as out-of-scope `SKIPPED`. Only overlay is in scope.

### 3G - Confirmation gate

Print a **locked plan**:

- Platform
- Engine: `gsd`, `w2c`, or `none`
- Each in-scope gap -> FIX / SKIP
- Out-of-scope engine gaps -> SKIPPED
- Orchestrator flags that will run
- Wrapper plan: source repo, client repo, platform, engine, mode, existing policy
- Delivery profile values (if configuring)

Wait for explicit user confirmation before Phase 4.

## Phase 4 - Execute

Only after confirmation. Execute exactly one configuration command:

```bash
bash "$PLAYBOOK_ROOT/scripts/configure-client-project.sh" \
  --source-repo "$PLAYBOOK_ROOT" \
  --client-repo "$CLIENT_REPO" \
  --platform "$PLATFORM" \
  --engine gsd|w2c|none \
  --mode symlink \
  --existing-policy merge \
  # GSD only: [--init-gsd] [--with-do-next] [--patch-mcp] [--harness-context] [--force]
```

- Never call `install-client-ai-overlay.sh`, `bootstrap-gsd-workflow.sh`, `install-w2c-to-project.sh`, or `merge-mcp-template.sh` directly from this skill.
- Never pass GSD flags with `--engine w2c` or `--engine none`.
- For W2C, default install mode is symlink mode because the orchestrator receives the same `--mode symlink` as overlay.
- Do **not** pass `--interactive` to bootstrap. The skill interviews delivery profile values in chat.

## Phase 5 - Write DELIVERY-PROFILE (engine = gsd only, if approved)

After the orchestrator completes, patch `$CLIENT_REPO/.gsd/DELIVERY-PROFILE.md` with interviewed fields if the user approved delivery-profile configuration and bootstrap did not run interactively.

Rules:

- Preserve `<!-- BEGIN AUTO:PROJECT-VALIDATION -->` block from bootstrap.
- Never append `@_CLAUDE.md` / `@_AGENTS.md` sections.
- If profile was already configured and user did not approve overwrite, skip.

## Phase 6 - Verify

Run either the orchestrator check or the preflight check.

Preferred:

```bash
bash "$PLAYBOOK_ROOT/scripts/configure-client-project.sh" \
  --source-repo "$PLAYBOOK_ROOT" \
  --client-repo "$CLIENT_REPO" \
  --check
```

Fallback:

```bash
bash "$PLAYBOOK_ROOT/scripts/configure-client-check.sh" \
  --source-repo "$PLAYBOOK_ROOT" \
  --client-repo "$CLIENT_REPO"
```

Report **PASS / FAIL / SKIPPED** per gap:

| Result | Meaning |
| --- | --- |
| PASS | Gap was approved and is now OK |
| FAIL | Gap was approved but still broken - fix or remediate now |
| SKIPPED | User said no or the gap belongs to an unselected engine |

For `--engine w2c` or `--engine none`, missing GSD lines are `SKIPPED`, not failures. For `--engine none`, missing W2C lines are also `SKIPPED`.

**Do not** mark an approved MCP merge or W2C install as PASS with a "merge manually later" note. If an approved in-scope gap is still MISSING after execute -> FAIL and remediate in-session through the orchestrator path or explicit user approval.

If do-next + health script approved:

```bash
bash "$CLIENT_REPO/.workflow/scripts/playbook-gsd-health.sh"
```

## Phase 7 - Handoff

Print:

1. Summary of what was fixed.
2. **Deferred gaps only** (user said no) - optional next steps.
3. Engine-specific next action:
   - `gsd` -> open the client repo in Cursor and run `$gsd-plan-milestone`.
   - `w2c` -> open the client repo in Cursor and run `work to chores`.
   - `none` -> overlay only; no planning-engine handoff.

**Forbidden handoff lines** when the user approved the fix:

- "Merge playbook-gsd into `.mcp.json` manually..."
- "Edit paths in the template yourself..."
- "Run `install-w2c-to-project.sh` yourself..."

Those are only valid under **Deferred** when the user chose **no**.

## Anti-patterns

- Skipping the gap inventory and jumping to delivery questions.
- Asking multiple gap questions in one message.
- Asking GSD questions after the user chose `w2c` or `none`.
- Passing GSD-only flags with `--engine w2c` or `--engine none`.
- Treating "`.mcp.json` exists" as "MCP is fine" without checking `playbook-gsd`.
- Leaving approved gaps as homework.
- Installing this skill into client repos via `install-workflow-tools.sh`.
- Calling overlay/bootstrap/W2C installers directly instead of `configure-client-project.sh`.
