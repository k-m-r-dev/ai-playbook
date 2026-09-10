# Gitflow — mobile release train

Applies to iOS and Android repos using this playbook.

## Branches

| Branch | Role |
| --- | --- |
| `main` | Production pointer — what you ship to stores |
| `develop` | Integration — feature merges land here first |
| `feature/*` | Short-lived; branched from `develop`; PR → `develop` |
| `release/*` | RC line from `main` (e.g. `release/v1.0.0-RC`); cherry-pick feature merge commits from `develop` |
| `hotfix/*` | From `main` (e.g. `hotfix/SHO-123`); fix + **marketing version bump** → PR → `main` |

## Flows

### Feature (day-to-day)

```text
feature/SHO-NNN  →  develop  →  (auto internal/test track upload when shipping paths change)
```

### Release candidate

```text
main  →  release/vX.Y.Z-RC  (cherry-picks)
       →  PR to main when ready
       →  auto release-track upload on merge (iOS: External + Internal)
```

Pre-merge RC testing: use **manual deploy** workflow against the `release/*` ref (no auto-upload on every RC push).

### Hotfix

```text
main  →  hotfix/SHO-NNN
       →  fix + manual MARKETING_VERSION bump (patch)
       →  PR → main  →  release-track upload
       →  back-merge main → develop
```

### Rollback (revert a bad release on main)

Same playbook as hotfix — **not** a separate CI workflow:

```text
main  →  hotfix/SHO-NNN-revert (or hotfix/SHO-NNN)
       →  git revert <bad-merge-sha>  (+ conflict resolution)
       →  manual MARKETING_VERSION patch bump (e.g. 1.0.0 → 1.0.1)
       →  PR → main  →  release-track upload
       →  back-merge → develop
```

If using GitHub’s “Revert” button, add the version-bump commit on that PR branch before merge.

## Back-merge rule

After **every** merge to `main` (RC, hotfix, rollback), merge `main` into `develop` (or merge the hotfix branch into both) so `develop` does not reintroduce reverted code.
