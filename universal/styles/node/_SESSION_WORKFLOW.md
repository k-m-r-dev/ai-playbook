# Session & progress documentation workflow

Three living documents under [`.workflow/`](.workflow/) plus **this playbook** (`SESSION_WORKFLOW.md`, peer to `AGENTS.md` and `ARCHITECTURE.md`). **Cursor** loads `.cursor/rules/20-session-progress.mdc`; **Claude** uses `CLAUDE.md` plus **`session-progress-workflow`**; **Copilot** uses `.github/instructions/session-progress.instructions.md` — all **thin** pointers. With default overlay install, **`SESSION_WORKFLOW.md`** is symlinked as `_SESSION_WORKFLOW.md` into your private `ai-playbook`; committed `SESSION_WORKFLOW.md` wraps it; **`.workflow/`** is **copied** per project.

| Document | Role | When to touch |
|----------|------|----------------|
| [`.workflow/current_session_progress.md`](.workflow/current_session_progress.md) | Scratch pad for the *active* session | Start, during, end |
| [`.workflow/previous_session_progress.md`](.workflow/previous_session_progress.md) | Archive of closed sessions (newest first) | End of session |
| [`.workflow/progress_tracker.md`](.workflow/progress_tracker.md) | Backlog, sprint, shipped features | When plan or delivery changes |

Feature specs under `docs/` or `doc/` are not session logs — link them from the tracker.

### Thin tool surfaces (identical routing body)

**Cursor** `20-session-progress.mdc`, **Claude** `session-progress-workflow`, **Copilot** `session-progress.instructions.md` share one definition. Lifecycle steps live **only** in this file.

---

## Session lifecycle

### 1. Session start

1. Open [`.workflow/current_session_progress.md`](.workflow/current_session_progress.md).
2. Archive any closed session first, then apply the empty template.
3. Fill **Session Date**, **Session ID**, **Session Goals**.
4. Read **`CLAUDE.md`** (milestone + topography) and skim [`.workflow/progress_tracker.md`](.workflow/progress_tracker.md).

### 2. During work

- Update current session file as you progress.
- Use graphify / ruflo before broad repo searches.
- Check off tracker items when work is verified.

### 3. Before declaring done

- Run verification from `AGENTS.md` / `ARCHITECTURE.md` (build, test, lint).
- Sync `.workflow/progress_tracker.md` if scope shipped or plan changed.
- Update **`CLAUDE.md`** milestone and learnings sections at meaningful handoffs.

### 4. Session end

1. Append summary to [`.workflow/previous_session_progress.md`](.workflow/previous_session_progress.md) (newest on top).
2. Reset [`.workflow/current_session_progress.md`](.workflow/current_session_progress.md) with the empty template below.
3. Bump tracker **Last Updated** if changed.
4. Optional: `npx ruflo@latest memory consolidate --target local` then copy durable bullets into **`CLAUDE.md`**.

---

## Archive entry template

```markdown
### Session: YYYY-MM-DD - Short title

**Goals**:
- [x] Done
- [ ] Deferred → next session

**Completed**:
- Bullets + paths

**Decisions**:
- Short bullets

**Carry over**:
- Next tasks
---
```

---

## Empty template for `.workflow/current_session_progress.md`

```markdown
# Current Session Progress

> **Workflow**: [SESSION_WORKFLOW.md](SESSION_WORKFLOW.md)  
> **Session Date**: YYYY-MM-DD  
> **Session ID**: (short label)  
> **Developer/AI**: (name or tool)

---

## Session Goals

- [ ] Goal 1

---

## Work Completed This Session

(TBD)

---

## Decisions Made

(TBD)

---

## Code Changes

(TBD)

---

## Blockers

None

---

## Notes for Next Session

(TBD)

---

**Next Session Priority**: (one line)
```

---

**Document version**: 2.0 (universal)
