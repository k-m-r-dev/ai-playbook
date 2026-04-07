---
applyTo: "**"
excludeAgent: ["Reviewer"]
---

# Flutter BLoC implementation instructions

## Mission

Build maintainable Flutter software with clear architecture, safe defaults, and reviewable changes.

## Architecture rules

- Read **`ARCHITECTURE.md`** before implementing any feature, refactor, or structural change.
- Keep app shell, feature logic, shared services, and design system concerns separate.
- Prefer explicit boundaries between UI, domain, and data access.
- **`architecture.instructions.md`** is a thin router—do not duplicate full layer rules here.

## Project-specific appendix

If **`doc/copilot-project-appendix.md`** exists, read it **after** this file for database paths, assets, bespoke scripts, navigation notes, and team workflow that are unique to this repository.

## Session and progress documentation

- Follow **`SESSION_WORKFLOW.md`** and **`session-progress.instructions.md`**; apply substantive edits only under **`.workflow/`** (see playbook—do not duplicate lifecycle here).

## Code generation

When the project uses **build_runner** (e.g. **injectable**, **freezed**, **json_serializable**, **drift_dev**):

```bash
dart run build_runner build --delete-conflicting-outputs
```

Active development:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

Regenerate when you change annotations, Drift tables, or injectable constructors. A change that requires codegen is not done until generation succeeds and the app analyzes cleanly.

## Feature module layout

Match **`ARCHITECTURE.md`**. Typical shape:

```text
lib/features/<feature>/
  data/
    models/
    repositories/
  state/        # blocs/cubits per ARCHITECTURE
  view/
    screens/
    widgets/
```

Do not invent a different layout without updating **`ARCHITECTURE.md`**.

## BLoC conventions

- Scope **Bloc**/**Cubit** with **`BlocProvider`** / **`MultiBlocProvider`** per feature as **`ARCHITECTURE.md`** describes.
- Keep event handling and state transitions inside bloc/cubit classes; UI stays dumb.
- Use **`BlocBuilder`** for rebuilds; **`BlocListener`** for one-off side effects (navigation, snackbars).
- Keep side effects and I/O behind **repositories** and **use cases**, not inside widgets.

## Dependency injection

If the stack uses **GetIt** + **injectable** (or similar): annotate constructors/modules per project rules, run code generation after DI graph changes, and resolve dependencies the way **`ARCHITECTURE.md`** describes—do not assume a pattern the project does not use.

## Repositories

- Repositories own data access (HTTP, local DB, preferences).
- Blocs/cubits depend on repository abstractions; widgets do not call repositories directly.
- If **`ARCHITECTURE.md`** defines **`init`**/**`dispose`** or a **`BaseRepository`** pattern, follow it consistently.

## Local persistence

For **Drift** / **SQLite** / bundled databases: singletons, migrations, and asset-to-disk copy logic belong in the core data layer. Document **concrete filenames, asset paths, and regeneration commands** in **`doc/copilot-project-appendix.md`** or **`ARCHITECTURE.md`**, not only in chat.

## Quality requirements

- Run **`flutter analyze`** and **`flutter test`** after substantive changes; a change is not done until checks pass.
- Add or update tests when behavior changes.
- Avoid broad refactors unless scoped and justified.

## Common pitfalls

- Skipping **`build_runner`** after annotation or Drift/schema changes.
- UI not handling all bloc states (loading / error) explicitly.
- New types not wired in DI (missing annotation or registration).
- Business logic leaking into widgets instead of blocs/cubits.
