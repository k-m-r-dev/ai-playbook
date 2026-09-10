# Global git hooks (machine backup)

This folder stores backups of **machine-global** git hooks that lived under
`~/.git-hooks` (configured via `git config --global core.hooksPath`).

## Disabled (2026-09-10)

The large-diff / line-ending `pre-commit` hook was **disabled system-wide** because it
blocked intentional Match commits of encrypted `.mobileprovision` / cert blobs
(false-positive “LARGE DIFF DETECTED”).

- Backup: [`backup/pre-commit.large-diff-line-endings.2026-09-10`](./backup/pre-commit.large-diff-line-endings.2026-09-10)
- Global config change: `git config --global --unset core.hooksPath`
- Local file: `~/.git-hooks/pre-commit` renamed to `pre-commit.disabled` (if present)

## Restore

```bash
mkdir -p ~/.git-hooks
cp scripts/git-hooks/backup/pre-commit.large-diff-line-endings.2026-09-10 ~/.git-hooks/pre-commit
chmod +x ~/.git-hooks/pre-commit
git config --global core.hooksPath ~/.git-hooks
```

Optional: allow Match repos without re-enabling globally:

```bash
git -C /path/to/match-certificates config core.hooksPath /dev/null
```

Or teach the hook to skip `certs/` and `profiles/` before restoring.

## Related

- Match / TestFlight troubleshooting: [`mobile/ci-cd/IOS-TESTFLIGHT.md`](../../mobile/ci-cd/IOS-TESTFLIGHT.md#troubleshooting)
