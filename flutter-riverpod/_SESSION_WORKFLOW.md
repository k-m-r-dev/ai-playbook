# Session & progress documentation workflow

This project uses **three living documents** under [`.workflow/`](.workflow/) plus **this playbook** at the repository root as `SESSION_WORKFLOW.md` (peer to `AGENTS.md` and `ARCHITECTURE.md`). **Cursor** loads `.cursor/rules/20-session-progress.mdc`; **Claude** uses `CLAUDE.md` plus the **`session-progress-workflow`** skill; **GitHub Copilot** uses `.github/instructions/session-progress.instructions.md`—all **thin** pointers (see below). With default overlay install, **`SESSION_WORKFLOW.md`** is symlinked as `_SESSION_WORKFLOW.md` into your private `ai-playbook`; committed `SESSION_WORKFLOW.md` wraps it; **`.workflow/`** is **copied** per project so each codebase keeps its own session state and tracker.

Follow the rhythm for **every** meaningful work block (task, feature slice, or AI/human session), not only at release.

| Document | Role | When to touch |
|----------|------|----------------|
| [`.workflow/current_session_progress.md`](.workflow/current_session_progress.md) | **Scratch pad** for the *active* session: goals, diffs, decisions, blockers, next steps | **Start:** set session header + goals. **During:** append as you go. **End:** summarize; then reset file using the template below. |
| [`.workflow/previous_session_progress.md`](.workflow/previous_session_progress.md) | **Archive** of closed sessions (newest first) | **End of session:** paste the closing summary from current into a new block here; keep entries short and scannable. |
| [`.workflow/progress_tracker.md`](.workflow/progress_tracker.md) | **Project source of truth**: features, schema (if applicable), sprint, backlog, priorities | **When something actually ships or the plan changes:** checkboxes, feature links, schema section if persistence changes, footer date/version. **Optional at session start:** skim sprint section for focus. |

**Feature specs** under `doc/` (or elsewhere) are **not** session logs; link them from `.workflow/progress_tracker.md` and update them when behaviour is agreed or implemented.

### Thin tool surfaces (shared contract — not similar, **identical**)

**Cursor** `.cursor/rules/20-session-progress.mdc`, **Claude** `session-progress-workflow`, and **Copilot** `session-progress.instructions.md` use the **same markdown body** (word-for-word routing rules). Only the **wrapper** differs: Cursor adds `globs` + `alwaysApply`, Claude uses skill YAML, Copilot uses `applyTo`. They are **not** where lifecycle steps or templates live — that is **only** in this file (`SESSION_WORKFLOW.md`). When process changes, edit **this file** in `ai-playbook` once; update the three thin files together only if you change the **routing** wording itself.

---

## Session lifecycle (standard)

### 1. Session start (human or AI)

1. Open [`.workflow/current_session_progress.md`](.workflow/current_session_progress.md).
2. If it still holds a **closed** session, archive it first (step 4 below), then apply the **empty template**.
3. Fill **Session Date**, **Session ID** (short label), **Session Goals** (checkboxes).
4. Skim [`.workflow/progress_tracker.md`](.workflow/progress_tracker.md) *Current sprint* for alignment.

### 2. During work

- Update **Work Completed**, **Code Changes**, **Decisions**, **Blockers** in `.workflow/current_session_progress.md` as you make progress (brief bullets; link PRs/commits if useful).
- If you complete a tracker task, check it off in `.workflow/progress_tracker.md` **in the same change set** when the work is merged or verified.

### 3. Before declaring the session done

- Run project verification when code changed (`flutter analyze`, `flutter test` per `AGENTS.md`).
- Ensure `.workflow/progress_tracker.md` reflects any completed tasks, new specs, or schema changes.

### 4. Session end (handoff)

1. **Append** to [`.workflow/previous_session_progress.md`](.workflow/previous_session_progress.md) under **Session History** using the block template (see below). **Prepend** new sessions so **newest is on top**.
2. **Replace** [`.workflow/current_session_progress.md`](.workflow/current_session_progress.md) with the empty template from the bottom of this file (keep the “Workflow” link line).
3. Bump **Last Updated** / **Document Version** in `.workflow/progress_tracker.md` if that session changed the tracker.

**Single tiny fix?** You may only touch `.workflow/current_session_progress.md` (one line under Completed) and skip a full archive entry—use judgment; still update the tracker if a sprint item closed.

---

## Archive entry template (for `.workflow/previous_session_progress.md`)

```markdown
### Session: YYYY-MM-DD - Short title

**Duration**: (optional)  
**Participants**: (optional)

**Goals**:
- [x] Done item
- [ ] Deferred item → carry to next session

**Completed**:
- Bullet(s) + optional file paths

**Decisions**:
- Short bullets

**Blockers / risks**:
- None / …

**Carry over**:
- Next-session tasks or open questions

---
```

---

## Empty template for `.workflow/current_session_progress.md`

Copy everything below the `---` into `.workflow/current_session_progress.md` after archiving.

```markdown
# Current Session Progress

> **Workflow**: [SESSION_WORKFLOW.md](SESSION_WORKFLOW.md)  
> **Session Date**: YYYY-MM-DD  
> **Session ID**: (e.g. onboarding, settings-ui)  
> **Developer/AI**: (name or tool)

---

## Session Goals

- [ ] Goal 1
- [ ] Goal 2

---

## Work Completed This Session

(TBD)

---

## Decisions Made

(TBD)

---

## Code Changes

(TBD — paths, scope)

---

## Blockers

None

---

## Notes for Next Session

(TBD)

---

## Questions to Address

(TBD)

---

**Session Duration**: (fill at end)  
**Files Modified**: (approx.)  
**Next Session Priority**: (one line)
```

---

## Why three files?

- **current_** → fast context for “what are we doing *right now*?” without editing the long tracker.
- **previous_** → short history so new sessions do not rely on chat logs alone.
- **progress_tracker** → durable backlog, sprint, schema, and feature map for humans and AI.

---

**Document version**: 1.1  
**Last updated**: 2026-04-08
