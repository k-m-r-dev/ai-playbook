# Milestone Planning Workflow

Read before planning **any** milestone or multi-milestone workstream.

**Execution rules:** `.gsd/workflow/milestone-workflow.md`

---

## Purpose

Prevent scope drift, branch pollution, stale stacked branches, and oversized reviews. Works for:

- single-milestone features,
- multi-milestone workstreams,
- with or without external tickets,
- with trunk-direct or branch-per-slice/milestone strategies.

---

## When This Applies

- New milestone planning
- Multi-milestone roadmaps (one feature → `M001`, `M002`, …)
- Sequential delivery (PRs or direct commits)
- Large migrations or parity work

---

## Full Upfront Planning Rule

Before execution, the plan must exist from **workstream → milestone → slice → task**.

Each **milestone** must define:

- scope slug (human-readable),
- delivery profile fields (see Required Milestone Map),
- execution sequence,
- validation commands,
- completion condition,

and each **slice** must list tasks with description, files, and verification.

Do not execute incomplete plans.

---

## Multi-Milestone Workstreams

Use multiple milestones when one feature exceeds ~1000–1500 LOC or needs sequential review.

**Planning steps:**

1. Define the workstream goal (one paragraph).
2. Split into milestones `M001`, `M002`, … each with a **size budget** (~1000–1500 LOC target).
3. Map dependencies between milestones.
4. Assign optional external ticket **per milestone** (or one ticket for the workstream, or none).
5. Choose integration strategy per milestone or once for the whole workstream.

**Example:**

| Milestone | Scope | ~LOC budget | Ticket (optional) |
| --- | --- | --- | --- |
| M001 | Foundation + API layer | 1200 | PROJ-101 |
| M002 | Feed UI | 1400 | PROJ-102 |
| M003 | Detail + interactions | 1500 | — |

Within each milestone, use **slices** (`S01`, `S02`, …) for vertical cuts.

---

## Required Milestone Map

Fill this before execution. Copy into roadmap, `M###-ROADMAP.md`, or `.gsd/DELIVERY-PROFILE.md`.

| Field | Required | Notes |
| --- | --- | --- |
| Milestone / planning ID | Yes | e.g. `M001` or equivalent |
| Human-readable scope slug | Yes | Used in commits, branches, PR titles |
| Workstream name (if multi-M) | When applicable | Links milestones together |
| External ticket ID | **No** | Optional per milestone or workstream |
| **Integration strategy** | Yes | `trunk-direct` \| `branch-per-slice` \| `branch-per-milestone` \| `branch-per-workstream` |
| **Integration branch** | Yes | e.g. `develop`, `main` |
| **Commit cadence** | Yes | `task` \| `slice` \| `milestone` \| `custom` |
| **Review unit** | Yes | `none` \| `slice` \| `milestone` \| `custom` |
| **Git/PR checkpoint mode** | Yes | `none` \| `slice` \| `milestone`; drives do-next checkpoint defaults |
| Branch name | When strategy ≠ `trunk-direct` | e.g. `feature/opinion-feed` |
| Execution sequence | Yes | Slice order + dependencies |
| Validation commands | Yes | Project-specific |
| Completion condition | Yes | e.g. “S01–S05 verified; commits on develop” |
| Size budget (LOC diff) | Recommended | Target 1000–1500; split if over ~2000 |

---

## Choosing Delivery Settings (guide)

| Situation | Suggested integration | Commit cadence | Review unit |
| --- | --- | --- | --- |
| Small repo, solo/small team, fast loop | `trunk-direct` | `slice` or `task` | `none` |
| Large milestone, want review per vertical slice | `branch-per-slice` | `slice` | `slice` |
| Milestone already ~1000–1500 LOC | `branch-per-milestone` | `milestone` | `milestone` |
| Multi-milestone workstream | mix per milestone | usually `slice` or `milestone` | per map |

These are defaults — **record the actual choice** in the milestone map.

Set `Git/PR checkpoint mode` to match how remote workflow should run:

- `none` — no push/PR gating
- `slice` — push/PR checkpoint at each slice completion
- `milestone` — push/PR checkpoint at milestone progression

---

## Sequential Delivery Rule

Work **one milestone at a time** unless explicitly approved otherwise.

Within a milestone, complete slices in dependency order.

Do not start milestone `M002` until `M001` meets its completion condition (merged PR, or pushed commits per profile).

---

## PR / Push Size Rule

- Target **1000–1500** lines of diff per review unit.
- Hard limit **~2000** lines.
- If over limit: split milestone (multi-M workstream) or split slices **before** execution.

---

## GSD Mapping (optional convention)

| Artifact | Workflow term |
| --- | --- |
| `M###-ROADMAP.md` | Milestone / workstream map |
| `S##-PLAN.md` | Slice |
| Task in slice plan / `T##-PLAN.md` | Task |
| `.gsd/DECISIONS.md` | Durable planning decisions |

GSD is optional; any planning layout works if the Required Milestone Map is complete.

---

## Stop Conditions

Stop if milestone map is incomplete, delivery profile ambiguous, branch wrong, diff polluted, validation fails, size over limit, or remote mutation without approval.
