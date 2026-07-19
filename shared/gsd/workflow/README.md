---
name: ticket-to-milestone-plan
description: Use at the start of GSD planning for any new ticket or unit of scope, ticketed or not. Reads this project's milestone workflow files and delivery profile first, gates grill-me and superpowers/brainstorming on actual ambiguity in the input rather than running them unconditionally, then produces a milestone/slice/task plan that fills the Required Milestone Map and cites (rather than restates) this project's Task Handoff Gate, Commit Gate, Remote Mutation Rule, Validation Rule, and Commit Message Format. Stops for human approval before any execution begins.
---

# Ticket to Milestone Plan

## When this applies

Any time planning starts for a new piece of scope — a Linear/Jira ticket, a
pasted ticket description with no live tracker connection, a chore with no
ticket at all, or a multi-milestone workstream. External tickets are always
optional; never block planning on a missing tracker entry.

## Step 0 — Read the workflow files, in order

Before doing anything else:

1. `.gsd/workflow/milestone-workflow.md` — execution rules, Task Handoff
   Gate, delivery profile vocabulary, commit/PR rules
2. `.gsd/workflow/milestone-planing-workflow.md` — planning rules, Required
   Milestone Map, multi-milestone splitting, size limits
3. `.gsd/DELIVERY-PROFILE.md` — this project's actual settings
4. `AGENTS.md` — project overrides and learned preferences, if present

**Stop condition:** if `.gsd/DELIVERY-PROFILE.md` is missing or its
Required fields are ambiguous, stop and ask before planning anything. Do
not guess an integration strategy or commit cadence.

## Step 1 — Take in the scope

Accept the ticket however it arrives: fetched live via an MCP tracker
integration, or pasted directly as text when no live ticket exists. Both are
valid inputs to this skill — do not treat a pasted description as lower
quality than a fetched one.

## Step 2 — Gate ambiguity-resolution skills on actual ambiguity

Assess whether the input leaves real implementation-relevant decisions
unmade (persistence, interaction surface, scope boundaries, accessibility,
edge-case handling, etc.).

- **If genuinely ambiguous:** run `mattpocock/grill-me` against the input.
  Ask questions one at a time. Record each answer into the working scope
  before moving to the next question.
- **If fully specified:** skip `grill-me` and say so explicitly, with the
  reason ("scope is fully specified — no ambiguity to interrogate"). Skipping
  the interrogation is not license to skip the design-approval step in Step
  5 — that still applies regardless of how much ambiguity existed going in.

After scope is either clarified or confirmed complete, run
`superpowers/brainstorming` to check for structural gaps the Q&A pass
wouldn't surface on its own — edge cases, empty states, testing seams,
idempotency concerns. Skip only if the scope is trivially small and the
brainstorming pass would clearly produce nothing.

## Step 3 — Determine milestone/slice structure

Apply the Full Upfront Planning Rule: the plan must exist from workstream →
milestone → slice → task before execution starts.

- Single milestone unless the scope exceeds ~1000–1500 LOC, in which case
  split into `M001`, `M002`, … per the multi-milestone workstream rules,
  each with its own size budget and dependency mapping.
- Within a milestone, use slices for vertical cuts (data/logic/UI where
  applicable), each independently verifiable.

## Step 4 — Fill the Required Milestone Map completely

Do not proceed to task breakdown until every required field is filled:
milestone/planning ID, human-readable scope slug, workstream name (if
multi-milestone), external ticket ID (optional), integration strategy,
integration branch, commit cadence, review unit, Git/PR checkpoint mode,
branch name (if applicable), execution sequence, validation commands,
completion condition, size budget.

Pull integration strategy, branch, commit cadence, review unit, and
checkpoint mode from `.gsd/DELIVERY-PROFILE.md` rather than re-deciding
them per ticket, unless this ticket has an explicit, stated reason to
deviate — in which case record the deviation and why.

## Step 5 — Break slices into tasks

Each task needs explicit inputs and outputs and a validation gate (build
passes, tests pass, no force-unwraps/fatalError as applicable to the
language). Every task that produces or changes code must include test
coverage as part of its definition of done — not a follow-up task.

Present the resulting design — even a few sentences for a small scope — and
get explicit human approval before any task execution begins. This applies
regardless of scope size; "this is too simple to need a design" is not a
valid reason to skip this step.

## Step 6 — Cite guardrails, don't restate them

Write a "Guardrails" section into the milestone and slice-level plan files
that references this project's own workflow files by name and section,
rather than paraphrasing the rules inline:

- Task Handoff Gate (`.gsd/workflow/milestone-workflow.md`) — pause after
  each task, structured task report (task id/title, files changed,
  verification commands + outcomes, deviations/blockers), wait for explicit
  `do next`
- Commit Gate (`.gsd/workflow/milestone-workflow.md`) — commit only after
  the relevant scope (task/slice/milestone per `commit_cadence`) is verified
- Remote Mutation Rule (`.gsd/workflow/milestone-workflow.md`) — no push,
  PR, or remote mutation without explicit user approval, gated further by
  the active `Git/PR checkpoint mode`
- Validation Rule (`.gsd/workflow/milestone-workflow.md`) — run the
  validation commands recorded in the milestone map before each commit and
  before each push
- Commit Message Format (`.gsd/workflow/milestone-workflow.md`) —
  `feat(TICKET-ID): summary` when an external ticket exists,
  `feat(scope-slug): summary` when it doesn't; never use local planning IDs
  (`M001`, `S02`) in commit messages or PR titles

Citing these means an execution agent picking up the plan later — in a
separate session, possibly a different tool entirely — reads the canonical
rule from its source file, not a summary that can drift out of sync with it.

## A note on referring to plan artifacts

GSD's on-disk file layout is an internal implementation detail, not a
stable contract — it has already changed once (nested
`milestones/M001/slices/S01/...` → flat `phases/01-<slug>/...`) and may
change again. Refer to milestones, slices, and tasks by their DB
identifiers (`M001`, `S01`, `T01`) — those are stable — never by a
hardcoded file path. When a specific file needs to be read or shown
directly, resolve the current path via `.gsd/.compat.json` (the ground
truth for what path each entity currently projects to) or via the `gsd_*`
tools, rather than assuming a layout.

## Stop conditions

Stop and ask rather than proceeding if: the milestone map is incomplete,
the delivery profile is missing or ambiguous, the wrong branch is active,
validation fails, the diff exceeds the size limit for the chosen review
unit, or a remote mutation would occur without explicit approval.
