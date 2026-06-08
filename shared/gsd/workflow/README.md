# Milestone workflow (reusable)

Abstract, project-agnostic planning and execution rules for milestone-based work. Copy this folder into any repo and wire project-specific settings separately.

## Files in this folder

| File | Purpose |
| --- | --- |
| `milestone-planing-workflow.md` | Planning: Required Milestone Map, multi-milestone splitting (~1000–1500 LOC), size limits, upfront planning rule |
| `milestone-workflow.md` | Execution: Task Handoff Gate, delivery profiles, commit cadence, review units, stop conditions |
| `README.md` | How to adopt and customize (this file) |

These files stay **generic**. Do not put project branches, build commands, or repo-specific decisions here.

## Adopt in a new project

### 1. Copy the abstract workflow

```bash
mkdir -p .gsd/workflow
cp /path/to/source/.gsd/workflow/milestone-workflow.md .gsd/workflow/
cp /path/to/source/.gsd/workflow/milestone-planing-workflow.md .gsd/workflow/
cp /path/to/source/.gsd/workflow/README.md .gsd/workflow/
```

Optional: copy `DELIVERY-PROFILE.md` as a **template** and edit it (see step 2).

### 2. Create `.gsd/DELIVERY-PROFILE.md`

One file per repo (or per workstream) records **how this project delivers**. Fill in at least:

| Field | Examples |
| --- | --- |
| Integration strategy | `trunk-direct` · `branch-per-slice` · `branch-per-milestone` · `branch-per-workstream` |
| Integration branch | e.g. `develop`, `main` |
| Commit cadence | `task` · `slice` · `milestone` · `custom` |
| Review unit | `none` · `slice` · `milestone` · `custom` |
| Remote push | e.g. explicit user approval, CI green, always after slice |
| External tickets | Optional — Jira/Linear/GitHub Issue IDs when used |
| Validation commands | Project-specific test/lint/build (not in abstract workflow) |

**Example — small team, direct to trunk:**

```markdown
| Integration strategy | trunk-direct |
| Integration branch   | develop      |
| Commit cadence       | slice        |
| Review unit          | none         |
```

**Example — large feature, PR per slice:**

```markdown
| Integration strategy | branch-per-slice |
| Integration branch   | develop          |
| Commit cadence       | slice            |
| Review unit          | slice            |
```

Per-milestone overrides (slice order, commit scope slugs, LOC budget) can live in the same file or in each `M###-ROADMAP.md`.

### 3. Add a short block to `AGENTS.md`

Point agents at abstract workflow first, then project overrides:

```markdown
## Milestone / Multi-PR Work

1. `.gsd/workflow/milestone-workflow.md`
2. `.gsd/workflow/milestone-planing-workflow.md`
3. `.gsd/DELIVERY-PROFILE.md` — this project's integration strategy, branch, commit cadence, review unit
```

Include a small table with **this repo’s** active settings (copy from `DELIVERY-PROFILE.md`).

### 4. Plan milestones

Use your planning layout (GSD under `.gsd/milestones/M###/` is one convention). Before execution, complete the **Required Milestone Map** from `milestone-planing-workflow.md` and align it with `DELIVERY-PROFILE.md`.

For workstreams spanning multiple milestones, target **~1000–1500 LOC per milestone** (hard ceiling ~2000) so each milestone stays reviewable.

## Layering (read order)

```
.gsd/workflow/*.md          ← abstract rules (same everywhere)
        ↓
.gsd/DELIVERY-PROFILE.md    ← this project’s delivery choices
        ↓
AGENTS.md                   ← agent-facing summary + learned prefs
        ↓
.gsd/milestones/M###/       ← concrete plans (optional GSD layout)
```

Project overrides win over abstract defaults when they conflict.

## When to change the profile

| Situation | Typical adjustment |
| --- | --- |
| Repo grows; reviews needed | `trunk-direct` → `branch-per-slice`, `review_unit: slice` |
| Single huge milestone | Split into M001, M002, … or slices with `branch-per-slice` |
| Ticket-driven org | Add ticket prefix to commit/PR titles; map tickets in milestone map |
| Faster iteration | `commit_cadence: task` or `milestone` instead of `slice` |

Update `DELIVERY-PROFILE.md` and the `AGENTS.md` table together so agents stay consistent.

## Reference implementation

This repo (`sharansho-app-ios`) uses:

- `trunk-direct` on `develop`
- Commit cadence: `slice`
- Review unit: `none`
- Details: `.gsd/DELIVERY-PROFILE.md`

Use it as a filled example, not as a requirement for other projects.
