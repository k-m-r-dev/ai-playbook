# Versioning — marketing vs build

## Marketing version (`x.y.z`)

- **Always manual** — commit on the branch or run the **Bump marketing version** GitHub Action.
- Bump before merging production-bound work to `main` (hotfix, rollback, RC when you intentionally change the customer-visible version).
- Use SemVer patch for hotfix/rollback (`1.0.0` → `1.0.1`, `1.4.3` → `1.4.4`).
- RC may keep marketing version stable until you explicitly bump for a new train.

## Build number (iOS `CFBundleVersion` / Android `versionCode`)

- **Auto at upload:** CI reads latest build for the app (and marketing version on iOS) from the store API and uses **latest + 1**.
- **Do not commit** build increments from CI — avoids bot commits and merge races.
- Repo `CURRENT_PROJECT_VERSION` / `versionCode` may lag TestFlight; that is expected.

## Workflows

| Action | Marketing | Build |
| --- | --- | --- |
| Merge to `develop` (auto TF) | unchanged in git | ASC +1 at upload |
| Merge to `main` (auto TF) | must already be bumped on PR branch | ASC +1 at upload |
| **Bump marketing version** (manual GHA) | commits bump | unchanged |
| **Deploy TestFlight** (manual GHA) | unchanged | ASC +1 at upload |

## iOS implementation notes

- Fastlane: `latest_testflight_build_number` + `increment_build_number` before `gym` (in-memory / workspace only).
- Bump lane: `agvtool` / `increment_version_number` for marketing only.

## Android (future)

- `versionCode` from Play Console API or Gradle script; same manual `versionName` rule.
