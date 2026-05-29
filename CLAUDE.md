# AI Playbook repository (meta)

This repo is the **source template** for client overlays — not a typical application codebase.

## For agents working *in this repo*

- **Framework docs:** [FRAMEWORK.md](FRAMEWORK.md), [EXTENDING.md](EXTENDING.md)
- **Default client overlay:** [universal/](universal/) — install with `--platform universal`
- **Mobile overlays:** `ios/`, `android/`, `flutter-riverpod/`, `flutter-bloc/`
- **Do not** treat root `.claude/` (Ruflo demo) as the installable client template — client projects receive platform-specific `.claude/skills` via the install script

## Client project ledger template

The installable **`CLAUDE.md`** lives at `universal/CLAUDE.md` (and platform variants). It is the cross-tool **project ledger** described in FRAMEWORK.md.

## Local engines (optional, for dogfooding this repo)

```bash
npx ruflo@latest memory search --query "playbook overlay" --namespace patterns
graphify build   # when graphify CLI installed
```

## Rules

- Prefer editing existing playbook files over creating duplicates
- Keep thin routing surfaces byte-synced across Cursor / Claude / Copilot (see SYNC comments)
- No secrets in committed files; use `config/claude.settings.local.example.json` for personal hooks
