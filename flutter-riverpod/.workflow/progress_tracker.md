# Project Progress Tracker

> **Purpose**: Project source of truth for continuation across developers and AI sessions.  
> **Session rhythm**: Follow [SESSION_WORKFLOW.md](../SESSION_WORKFLOW.md)—maintain [current_session_progress.md](./current_session_progress.md) while working, [previous_session_progress.md](./previous_session_progress.md) at handoff, and this file when project status changes.

### Using this tracker

When you ship or replan work:

- Update **checklists** in §4 (move items between Completed / Current sprint / Backlog; check boxes only when merged and verified).
- Add **one-line pointers** under the relevant feature in §3 to detailed specs in `doc/` when they exist.
- Add or refresh **§5 Data / schema** when persistence or API contracts change.
- Bump the **footer** (Last Updated, Document Version) after substantive edits.

---

## 1. Project Overview

**Name**: (application name)  
**Type**: Flutter (Dart, Riverpod)  
**Status**: In development  

### Core purpose

(One paragraph: what the app does for users.)

---

## 2. Design decisions

(Summary only; defer detail to `ARCHITECTURE.md`.)

- **Architecture**: (e.g. feature modules, core layer, design system)
- **State**: Riverpod (`ProviderScope`, provider ownership per feature)
- **DI / data**: (e.g. GetIt, repositories, local/remote)

---

## 3. Requirements and features

### 3.1 Implemented

- (Feature: short status + key paths or modules)

### 3.2 Planned

- (Feature: priority, spec link in `doc/` if any)

---

## 4. Tasks and work breakdown

### 4.1 Completed

- [ ] (Add items as you ship)

### 4.2 Current sprint

- [ ] (Active slice of work)

### 4.3 Backlog

**High**

- [ ]  

**Medium**

- [ ]  

**Low / later**

- [ ]  

**Technical debt**

- [ ]  

---

## 5. Data and schema notes

(Tables, entities, migrations, API shapes—only when applicable.)

---

## 6. Known issues and risks

- (Optional list)

---

**Last Updated**: 2026-04-08  
**Document Version**: 0.1  
