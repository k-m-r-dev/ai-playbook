# Cursor Ruflo hooks (playbook SoT)

## Problem

Cursor PreToolUse expects JSON with `permissionDecision` on stdout. Ruflo's
`hook-handler.cjs` prints human-readable text (for example `[OK]`). Cursor treats
that as invalid JSON and blocks the tool.

## Source of truth

SoT lives in this directory (`ai-playbook/config/cursor-hooks/`). Installed copies
live at `~/.cursor/hooks/`.

| File | Role |
|------|------|
| `ruflo-cursor-adapter.cjs` | Wraps the Ruflo handler and emits Cursor-safe JSON |
| `fix-ruflo-cursor-hooks.cjs` | Patches `~/.cursor/hooks.json` and project `.claude/settings.json` to use the adapter |

## Install (home)

```bash
bash scripts/install-ruflo-cursor-hooks.sh
```

That installs the `.cjs` files into `~/.cursor/hooks/`, adds
`~/.local/bin/fix-ruflo-cursor-hooks`, and runs the fixer (global by default).

## Per-client (after `ruflo init`)

```bash
fix-ruflo-cursor-hooks /path/to/client
# or
bash scripts/repair-after-ruflo.sh \
  --source-repo /path/to/ai-playbook \
  --client-repo /path/to/client
```

`repair-after-ruflo.sh` restores playbook helpers and also runs the Cursor hooks
installer unless `--skip-cursor-hooks` is passed.

## After editing SoT

Re-run the install script so `~/.cursor/hooks/` picks up the new copies (or
symlinks, if you used `--mode symlink`).

## Secrets

Do not commit secrets. Keep API keys and tokens out of hooks and settings.
