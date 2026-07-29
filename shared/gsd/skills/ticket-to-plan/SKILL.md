---
name: ticket-to-plan
description: Use at the start of GSD planning for any new ticket or unit of scope, ticketed or not. Reads this project's workflow files and delivery profile first, verifies grilling and brainstorming skills are invocable (hard stop if not), gates grill-me and superpowers/brainstorming on actual ambiguity in the input rather than running them unconditionally, then produces a full top-level-unit/slice/task plan via GSD workflow MCP that fills the Required Milestone Map, embeds execution guardrails into milestone and slice plan docs, uses milestone-level commit cadence (single commit per milestone), and cites (rather than restates) this project's Task Handoff Gate, Commit Gate, Remote Mutation Rule, Validation Rule, and Commit Message Format. Stops for human approval before any execution begins. Terminology-agnostic to whatever GSD currently calls its top-level planning unit (phase, milestone, or otherwise).
---

# Ticket to Plan

## Terminology

This skill deliberately avoids binding itself to either "milestone" or "phase." GSD's own on-disk/display term for the top-level planning unit has already changed once (milestone → phase) and may change again; the DB identifier prefix (`M001`) and the workflow files' vocabulary ("milestone," "Required Milestone Map") are unaffected by that and stay as written. Below, **top-level unit** means whatever GSD currently displays that as (phase, milestone, or otherwise) — use whichever term the running GSD version actually shows, and don't assume it matches the term used in this skill or in the workflow files.

## When this applies

Any time planning starts for a new piece of scope — a Linear/Jira ticket, a pasted ticket description with no live tracker connection, a chore with no ticket at all, or a workstream spanning multiple top-level units. External tickets are always optional; never block planning on a missing tracker entry.

## Full skill compliance

Run **every** step of this skill in order. Do not skip, reorder, or partially apply steps. Partial runs are a stop condition — restart from Step 0 rather than continuing from a skipped step.

## Step 0 — Read the workflow files, in order

Before doing anything else:

1. `.gsd/workflow/milestone-workflow.md` — execution rules, Task Handoff Gate, delivery profile vocabulary, commit/PR rules
2. `.gsd/workflow/milestone-planing-workflow.md` — planning rules, Required Milestone Map, multi-unit splitting, size limits
3. `.gsd/DELIVERY-PROFILE.md` — this project's actual settings
4. `AGENTS.md` — project overrides and learned preferences, if present

**Stop condition:** if `.gsd/DELIVERY-PROFILE.md` is missing or its Required fields are ambiguous, stop and ask before planning anything. Do not guess an integration strategy or commit cadence.

## Step 0.5 — Verify prerequisite skills are invocable

Before taking in scope or running ambiguity resolution, confirm that both of the following skills are available and invocable in the current environment:

- `/grilling` (also known as `mattpocock/grill-me` / grilling)
- `/brainstorming` (also known as `superpowers/brainstorming`)

**Stop condition:** if either skill cannot be invoked (missing from the skill set, unloadable, or otherwise unavailable), stop immediately and tell the user which skill(s) are missing. Do not proceed to Step 1, do not invent a substitute Q&A or design process, and do not create GSD plan artifacts until both skills are available.

This gate is independent of Step 2's ambiguity check — availability must be confirmed even when the later steps will skip running one of them.

## Step 1 — Take in the scope

Accept the ticket however it arrives: fetched live via an MCP tracker integration, or pasted directly as text when no live ticket exists. Both are valid inputs to this skill — do not treat a pasted description as lower quality than a fetched one.

## Step 2 — Gate ambiguity-resolution skills on actual ambiguity

Assess whether the input leaves real implementation-relevant decisions unmade (persistence, interaction surface, scope boundaries, accessibility, edge-case handling, etc.).

- **If genuinely ambiguous:** run `mattpocock/grill-me` (or `/grilling`) against the input. Ask questions one at a time. Record each answer into the working scope before moving to the next question.
- **If fully specified:** skip `grill-me` and say so explicitly, with the reason ("scope is fully specified — no ambiguity to interrogate"). Skipping the interrogation is not license to skip the design-approval step in Step 5 — that still applies regardless of how much ambiguity existed going in.

After scope is either clarified or confirmed complete, run `superpowers/brainstorming` (or `/brainstorming`) to check for structural gaps the Q&A pass wouldn't surface on its own — edge cases, empty states, testing seams, idempotency concerns. Skip only if the scope is trivially small and the brainstorming pass would clearly produce nothing.

## Step 3 — Determine top-level-unit/slice structure

Apply the Full Upfront Planning Rule: the plan must exist from workstream → top-level unit → slice → task before execution starts. Incomplete depth (milestone without slices, slices without tasks, or chat-only outlines) is a stop condition — finish the full tree first, or context will be missing at execution time.

- Single top-level unit unless the scope exceeds ~1000–1500 LOC, in which case split into multiple units (`M001`, `M002`, … by DB identifier, whatever GSD displays them as) per the multi-unit workstream rules, each with its own size budget and dependency mapping.
- Within a unit, use slices for vertical cuts (data/logic/UI where applicable), each independently verifiable.

### GSD workflow MCP — planning artifacts

Create and persist all milestone / slice / task plan artifacts **only** through the GSD workflow MCP (`gsd_*` tools such as `gsd_plan_milestone`, `gsd_plan_slice`, `gsd_plan_task` / `gsd_task_plan`, and related save/status tools). Do not hand-author a partial `.gsd/` tree or substitute chat-only plans when MCP is available.

**Stop condition:** if the GSD workflow MCP is unavailable or the required `gsd_*` tools cannot be called, stop and ask — do not invent plan files by hand.

### GSD artifact completeness

Always create **all** files/artifacts that GSD normally creates for the milestone, each slice, and each task (whatever the running GSD version projects via MCP / `.gsd/.compat.json`). Do not omit CONTEXT, ROADMAP, slice plans, task plans, or other standard artifacts that GSD would produce for a complete plan of that depth.

### Verify projections after persisting — compat drift self-heal

Known gsd-pi bug: `gsd_plan_slice` writes the DB rows and renders the slice PLAN files but does **not** record their `.gsd/.compat.json` projection entries (only `gsd_plan_milestone`'s ROADMAP projection is written). The next coherence/smoke check then reports `plan-coherence` `md=0 db=N files=0 DRIFT` for every slice even though the DB and the rendered markdown fully agree — a stale projection **index**, not a markdown↔DB content conflict, and not "partially created artifacts".

Run this only once the full plan tree — including tasks (Step 5) — has been persisted via MCP, since the drift signature appears only after `gsd_plan_slice` has written task rows. Then run the coherence check. If it FAILs with that exact signature — `md=0 db>0 files=0 DRIFT` for the slices, the rendered `NN-MM-PLAN.md` files exist with `<tasks>`, and `grep -c "<M###>/S0" .gsd/.compat.json` returns `0` — self-heal the index (do **not** treat it as incomplete artifacts or a content conflict, and never hand-edit `.compat.json`):

```bash
node .workflow/scripts/gsd-reproject-compat.mjs <M###>   # if the repo has it
```

If the script is absent (fresh repo, or this global skill running elsewhere), run the inline equivalent — it uses gsd-pi's own compat-marker API to rewrite the milestone's phase projections from the on-disk rendered files (index-only, additive, idempotent):

```bash
M=<M###> node --input-type=module -e '
import{readFileSync as R,readdirSync as D}from"node:fs";import{join as J}from"node:path";
const r=process.cwd(),M=process.env.M,X=process.env.GSD_PI_EXT||J(process.env.HOME,".npm-global/lib/node_modules/@opengsd/gsd-pi/dist/resources/extensions/gsd");
const{readCompatMarker:rd,writeCompatMarker:wr,computeProjectionSha:sha}=await import(J(X,"compat/compat-marker.js"));
const p=J(r,".gsd","phases"),m=rd(r);let n=0;
for(const d of D(p,{withFileTypes:true})){if(!d.isDirectory())continue;const a=J(p,d.name),F=D(a).filter(f=>f.endsWith(".md"));
const rm=F.find(f=>/-ROADMAP\.md$/.test(f));if(!rm)continue;const rt=R(J(a,rm),"utf8"),id=(rt.match(/^#\s*(M\d+)\b/m)||[])[1];if(!id||(M&&id!==M))continue;
m.projections["phases/"+d.name+"/"+rm]={sha:sha(rt),entities:[id]};n++;
for(const f of F){const g=f.match(/^\d+-(\d+)-(PLAN|SUMMARY|UAT|REPLAN|ASSESSMENT)\.md$/);if(!g)continue;const t=R(J(a,f),"utf8");m.projections["phases/"+d.name+"/"+f]={sha:sha(t),entities:[id,id+"/S"+g[1]]};n++;}}
m.lastWriter="gsd-pi";m.lastProjectedAt=new Date().toISOString();wr(r,m);console.log("reprojected",n);'
```

Then re-run the coherence check and confirm PASS after Step 5 (task persistence) and before requesting/recording final plan approval or handing off to execution (`do next`). Applies to the current flat-phase `.gsd/phases/` layout; if the check shows a genuine content mismatch (e.g. `md=2 db=4`), that is a real conflict — fall back to the normal stop-and-ask, do not auto-heal.

## Step 4 — Fill the Required Milestone Map completely

Do not proceed to task breakdown until every required field is filled: top-level-unit/planning ID, human-readable scope slug, workstream name (if multi-unit), external ticket ID (optional), integration strategy, integration branch, commit cadence, review unit, Git/PR checkpoint mode, branch name (if applicable), execution sequence, validation commands, completion condition, size budget.

Pull integration strategy, branch, commit cadence, review unit, and checkpoint mode from `.gsd/DELIVERY-PROFILE.md` rather than re-deciding them per ticket, unless this ticket has an explicit, stated reason to deviate — in which case record the deviation and why.

**Milestone commit cadence (this skill):** for plans produced by this skill, set `commit_cadence` to `milestone` — do **not** commit at each slice complete; make a **single commit for the milestone** after the milestone scope is verified. If `.gsd/DELIVERY-PROFILE.md` specifies a different cadence, record the deviation and why (this skill's milestone cadence wins for the plan output). Write this rule into **each slice plan** so execution agents do not commit on slice completion.

**This is a required, explicit output artifact, not an implicit outcome of planning.** GSD's own native context/roadmap template does not include a slot for these fields by default — do not assume completing the rest of the plan satisfies this step. Add a section titled exactly `## Delivery & Guardrails` to the top-level unit's own record file (whichever file this project's GSD version treats as that record — `CONTEXT.md`/`ROADMAP.md` in the flat-phase layout, or the equivalent in whatever layout is current) containing the full Required Milestone Map as a table, with every field above given a value — not left blank, not described only in prose elsewhere in the document. If any field cannot be filled because `.gsd/DELIVERY-PROFILE.md` doesn't specify it, that is the Step 0 stop condition — stop and ask, don't proceed with the field missing.

## Step 5 — Break slices into tasks

Each task needs explicit inputs and outputs and a validation gate (build passes, tests pass, no force-unwraps/fatalError as applicable to the language). Every task that produces or changes code must include test coverage as part of its definition of done — not a follow-up task.

Plan tasks through GSD workflow MCP (see Step 3). Ensure every slice has its task list persisted as GSD expects before asking for design approval.

Present the resulting design — even a few sentences for a small scope — and get explicit human approval before any task execution begins. This applies regardless of scope size; "this is too simple to need a design" is not a valid reason to skip this step.

## Step 6 — Cite guardrails, don't restate them

In the same `## Delivery & Guardrails` section from Step 4, add a "Guardrails" subsection that names the source file and rule explicitly for each item below — not a paraphrase of the behavior. A guardrail entry that describes the correct behavior but doesn't name its source is still a paraphrase and does not satisfy this step; the test is whether someone reading only this section would know which file to open to get the canonical version if this summary and that file ever disagree.

Required format per entry: **Rule name** (`source file`) — one-line description.

- **Task Handoff Gate** (`.gsd/workflow/milestone-workflow.md`) — pause after each task, structured task report (task id/title, files changed, verification commands + outcomes, deviations/blockers), wait for explicit `do next`
- **Commit Gate** (`.gsd/workflow/milestone-workflow.md`) — commit only after the relevant scope (task/slice/unit per `commit_cadence`) is verified
- **Remote Mutation Rule** (`.gsd/workflow/milestone-workflow.md`) — no push, PR, or remote mutation without explicit user approval, gated further by the active `Git/PR checkpoint mode`
- **Validation Rule** (`.gsd/workflow/milestone-workflow.md`) — run the validation commands recorded in the Required Milestone Map before each commit and before each push
- **Commit Message Format** (`.gsd/workflow/milestone-workflow.md`) — `feat(TICKET-ID): summary` when an external ticket exists, `feat(scope-slug): summary` when it doesn't; never use local planning IDs (`M001`, `S02`) in commit messages or PR titles
- **Full Ticket-to-Plan Steps** (`shared/gsd/skills/ticket-to-plan/SKILL.md`) — run every step of this skill in order; no partial runs
- **Prerequisite Skill Availability Gate** (`shared/gsd/skills/ticket-to-plan/SKILL.md`) — `/grilling` and `/brainstorming` must be invocable; stop immediately if either is unavailable
- **GSD Workflow MCP Planning Rule** (`shared/gsd/skills/ticket-to-plan/SKILL.md`) — create milestone/slice/task plan artifacts only via GSD workflow MCP (`gsd_*`)
- **GSD Workflow MCP Execution Rule** (`shared/gsd/skills/ticket-to-plan/SKILL.md`) — during execution, always use GSD workflow MCP for progress and state mutations (`gsd_progress`, `gsd_task_complete`, `gsd_slice_complete`, etc.)
- **GSD Artifact Completeness Rule** (`shared/gsd/skills/ticket-to-plan/SKILL.md`) — create all files/artifacts GSD normally creates for milestone/slice/task; no partial trees
- **Full Plan Depth Rule** (`shared/gsd/skills/ticket-to-plan/SKILL.md`) — plan must exist from workstream → milestone → slice → task before execution
- **Milestone Commit Cadence** (`shared/gsd/skills/ticket-to-plan/SKILL.md`) — do not commit at each slice complete; single commit per milestone after milestone verification; state this in each slice plan
- **Plan-Doc Embed Rule** (`shared/gsd/skills/ticket-to-plan/SKILL.md`) — embed these execution guardrails into the top-level unit's `## Delivery & Guardrails` and into each slice plan so later agents cannot miss them

Citing these by name and source means an execution agent picking up the plan later — in a separate session, possibly a different tool entirely — reads the canonical rule from its source file, not a summary that can drift out of sync with it.

### Embed guardrails into milestone and slice plan docs

After filling `## Delivery & Guardrails` on the top-level unit record, also copy the Guardrails list (and the milestone commit-cadence note) into **each slice plan** produced for this unit. Execution agents must see the GSD MCP execution rule, milestone commit cadence, Task Handoff Gate, and related rules without relying on chat history.

## A note on referring to plan artifacts

GSD's on-disk file layout and its display term for the top-level unit are both internal implementation details, not stable contracts — the layout has already changed once (nested `milestones/M001/slices/S01/...` → flat `phases/01-<slug>/...`, milestone → phase) and either may change again. Refer to top-level units, slices, and tasks by their DB identifiers (`M001`, `S01`, `T01`) — those are stable — never by a hardcoded file path or a specific display term. When a specific file needs to be read or shown directly, resolve the current path via `.gsd/.compat.json` (the ground truth for what path each entity currently projects to) or via the `gsd_*` tools, rather than assuming a layout.

## Stop conditions

Stop and ask rather than proceeding if: the Required Milestone Map is incomplete, the delivery profile is missing or ambiguous, the wrong branch is active, validation fails, the diff exceeds the size limit for the chosen review unit, a remote mutation would occur without explicit approval, `/grilling` or `/brainstorming` is not invocable, the GSD workflow MCP is unavailable for planning or execution, the plan tree is incomplete (missing slice or task depth), or GSD artifacts for the milestone/slice/task set are only partially created.
