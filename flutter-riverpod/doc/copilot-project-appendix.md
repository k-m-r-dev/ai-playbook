# Copilot / agent appendix (project-specific)

**Purpose:** Hold **app-specific** facts that should not live in the shared playbook—database paths, bundled assets, codegen quirks, internal tools, team git rules, product domain notes.

**Copilot:** `implementation.instructions.md` tells agents to read this file **when it exists**.

## Fill in for your app

Replace the bullets below with real values; delete sections that do not apply.

- **App / domain one-liner:** _e.g. what the product does in one sentence_
- **Pre-bundled DB or large assets:** _path under `assets/`, how it is copied on first launch, how to regenerate (e.g. `tools/` scripts)_
- **Non-default packages:** _Drift vs Hive vs X; router package; anything `ARCHITECTURE.md` does not already spell out_
- **Codegen:** _extra `build_runner` flags, custom entrypoints, or modules that always need rebuild_
- **Feature checklist:** _link to tracker or “how we add a feature” if not fully covered in `ARCHITECTURE.md`_
- **Git / PR conventions:** _branch names, required reviewers, CI commands_

Keep **`ARCHITECTURE.md`** the source for layer and folder layout; avoid duplicating long prose here—**pointers and commands** only.

## Migrating from a monolithic `.github/copilot-instructions.md`

If an older repo used one large Copilot file: keep **generic** Flutter + Riverpod/BLoC guidance in the playbook **`implementation.instructions.md`** (via overlay) and move **only** app-specific bullets (assets, DB names, `tools/` scripts, product domain, git rules) into this appendix. You can delete the monolith once coverage matches.
