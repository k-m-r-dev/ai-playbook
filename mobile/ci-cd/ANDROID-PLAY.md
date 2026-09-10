# Android — Play Console (extension stub)

Use the same **gitflow** and **versioning** rules as iOS ([GITFLOW.md](./GITFLOW.md), [VERSIONING.md](./VERSIONING.md)).

## Planned stack (when implemented)

- **Gradle** — `versionName` manual in git; `versionCode` from Play API latest + 1 at upload (mirror iOS build rule)
- **GitHub Actions** — `ubuntu-latest` or self-hosted; `bundle exec fastlane` or Gradle tasks
- **Signing** — encrypted keystore in secrets ([SECRETS.md](./SECRETS.md))
- **Tracks:** internal testing on `develop` merges; production track candidate on `main` merges

## Workflows to mirror (names TBD per repo)

| iOS analogue | Android intent |
| --- | --- |
| `testflight-develop.yml` | `play-internal-develop.yml` |
| `testflight-main.yml` | `play-release-main.yml` |
| `deploy-testflight.yml` | `deploy-play.yml` |
| `bump-version.yml` | same — bump `versionName` only |

## Reference

Implement against [IOS-TESTFLIGHT.md](./IOS-TESTFLIGHT.md) workflow matrix; keep secret names and branch triggers identical across mobile repos where possible.
