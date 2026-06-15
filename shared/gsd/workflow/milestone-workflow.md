# Milestone Workflow

Read at the start of every milestone, slice, and task.

**Planning prerequisite:** `.gsd/workflow/milestone-planing-workflow.md`  
**Project overrides:** `AGENTS.md` → *Milestone / Multi-PR Work*, or `.gsd/DELIVERY-PROFILE.md` when present.

---

## Vocabulary

Planning terms — not required in PR titles unless the team agrees.

| Term | Meaning |
| --- | --- |
| **Workstream** | Large feature spanning multiple milestones |
| **Milestone** | One planned delivery unit (may map to one branch, one PR, or one commit batch) |
| **Slice** | Vertical subset inside a milestone (UI + logic + tests where possible) |
| **Task** | One focused implementation step inside a slice |

**Local planning IDs** (`M001`, `S02`, `T04`) are internal only. Do not use them in PR titles or commit scopes unless the team explicitly agrees.

**External tickets** (Jira, Linear, GitHub Issue, etc.) are **optional**. Never block execution waiting for a tracker ticket.

When using **GSD**, plans live under `.gsd/milestones/M###/`. Other planning layouts are fine if the Required Milestone Map is complete.

---

## Project Delivery Profile

Every project (or workstream) declares a **delivery profile** before execution. Record it in `.gsd/DELIVERY-PROFILE.md`, the milestone map, or `AGENTS.md`.

### Integration strategy

| Profile | Branching | Remote delivery | Typical use |
| --- | --- | --- | --- |
| **`trunk-direct`** | No feature branch; work on integration branch | Commit + push directly to integration branch | Small/medium teams, fast iteration |
| **`branch-per-slice`** | One branch per slice | One PR per slice → integration branch | Large milestone split into reviewable slices |
| **`branch-per-milestone`** | One branch per milestone | One PR per milestone → integration branch | Milestone-sized chunks (~1000–1500 LOC) |
| **`branch-per-workstream`** | One long-lived branch for entire workstream | One or few large PRs | Rare; high coordination cost |

**Integration branch** — name the target (e.g. `develop`, `main`). Default assumption: `develop` if unspecified.

### Commit cadence

Chosen at planning time — **not fixed globally**.

| Cadence | When to commit | When to push |
| --- | --- | --- |
| **`task`** | After each verified task (optional staging per Task Handoff Gate) | Per profile + user approval |
| **`slice`** | One commit after all tasks in a slice pass verification | After slice commit, per profile + user approval |
| **`milestone`** | One commit after all slices in a milestone | After milestone commit, per profile + user approval |
| **`custom`** | Defined explicitly in the milestone map | As defined |

The Task Handoff Gate (`do next`) applies regardless of cadence — agents pause between tasks unless the plan allows auto-continue.

### Review unit

What constitutes a “done” delivery increment for humans:

| Review unit | Meaning |
| --- | --- |
| **`none`** | Trunk-direct; commits on integration branch are the review surface (pair review optional) |
| **`slice`** | Each slice is one PR or one approved push batch |
| **`milestone`** | Each milestone is one PR or one approved push batch |
| **`custom`** | Defined in milestone map |

### Git/PR checkpoint mode (do-next family)

This controls the default checkpoint cadence used by `do next` / `$do-next-runner`:

| Mode | Meaning |
| --- | --- |
| **`none`** | No push/PR checkpoint required by default |
| **`slice`** | Checkpoint push/PR at each slice completion |
| **`milestone`** | Checkpoint push/PR at milestone progression |

Even with a mode set, remote operations still require explicit staged user confirmations.

### Completion rule

A milestone (or slice, when `review_unit: slice`) is **complete** when:

1. All planned tasks verified, **and**
2. Delivery profile satisfied — e.g. PR merged, or commits pushed to integration branch with user approval.

“Local code done” alone is not complete.

---

## Planning Prerequisite

Before executing any milestone:

1. Read `.gsd/workflow/milestone-planing-workflow.md`.
2. Confirm the **Required Milestone Map** is complete (delivery profile included).
3. Read project overrides from `AGENTS.md` / `.gsd/DELIVERY-PROFILE.md`.

---

## Branch Rules

Apply the active **integration strategy**:

- **`trunk-direct`:** Stay on integration branch; do not create feature branches unless the user asks.
- **`branch-per-*`:** Create branch from updated integration branch; name with scope slug, not `M###`.
- **Stale branches:** Never use stale stacked branches as PR bases; preserve as backup/delta sources only.
- **`branch-per-*` retention:** Do not delete milestone/slice branches until merged or explicitly discarded.

---

## Remote Mutation Rule

Agents must not push, open PRs, update PRs, or mutate remotes unless:

- the active delivery profile allows it, **and**
- the user gives explicit approval (e.g. `push`, `open PR`, `do next` when push is implied).

---

## Validation Rule

Before each commit and before each push, run validation commands **recorded in the milestone map** (build, test, lint, format as applicable).

Use project-specific commands from `ARCHITECTURE.md`, `AGENTS.md`, or CI config — do not hardcode one project's commands in this file.

---

## Task Handoff Gate

Default agent behavior for milestone/slice/task work:

1. Complete one task.
2. Verify the task.
3. Stage task-owned changes (when commits happen at task cadence or before slice commit).
4. Share a short **task report**.
5. Pause for explicit user approval: **`do next`**.

Do not auto-advance unless the active plan explicitly allows it.

**Task report must include:** task id/title, files changed, verification commands + outcomes, deviations/blockers.

---

## Commit Gate (slice / milestone / custom)

When `commit_cadence` is **`slice`** or **`milestone`**, create the scoped commit only after:

- all tasks in that scope verified,
- required lint/format checks pass,
- commit message follows **Commit message format** below.

When `commit_cadence` is **`task`**, same rules apply per task.

---

## Commit Message Format

**With external ticket:**  
`feat(TICKET-123): Human-readable summary`

**Without external ticket:**  
`feat(scope-slug): Human-readable summary`

Use a short scope slug (`auth-refactor`, `opinion-feed`) — not `M001` or `S02`.

---

## PR Titles and Descriptions

Only when the delivery profile uses PRs (`branch-per-*` with review).

Same format as commit messages. Understandable without GSD or local planning IDs.

When present, also read:

- `.github/pull_request_template.md`
- `docs/engineering/templates/pr-prep-checklist.md`

---

## Stop Conditions

Stop if:

- delivery profile or milestone map is missing/ambiguous,
- wrong branch or polluted diff,
- validation fails,
- diff exceeds size limits for the chosen review unit,
- remote mutation would occur without approval.

---

## Size Guidance (cross-profile)

When splitting workstreams:

- Target **1000–1500 lines** of diff per milestone (hard ceiling ~2000).
- If a milestone exceeds this, split into additional milestones **before** execution.
- Under **`branch-per-slice`**, each slice should also stay reviewable; split slices if a single slice would exceed limits.
