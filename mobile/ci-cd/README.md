# Mobile CI/CD — portable spec

Source of truth for **iOS and Android** release automation. App repos opt in by linking from `AGENTS.md` or `.w2c/DELIVERY-PROFILE.md` (CI/CD spec field) — do **not** duplicate full guides under each app’s `docs/ci-cd/`.

## Contents

| Doc | Purpose |
| --- | --- |
| [GITFLOW.md](./GITFLOW.md) | Branching, RC, hotfix, rollback, back-merge |
| [VERSIONING.md](./VERSIONING.md) | Marketing vs build numbers |
| [SECRETS.md](./SECRETS.md) | Secret **names**, GitHub Actions, local `.env` (never commit values) |
| [IOS-TESTFLIGHT.md](./IOS-TESTFLIGHT.md) | Fastlane + GitHub Actions → TestFlight ([operator runbook 1–6](./IOS-TESTFLIGHT.md#operator-runbook-16)) |
| [ANDROID-PLAY.md](./ANDROID-PLAY.md) | Android extension points (stub) |

## Design principles

1. **Manual marketing version** — humans (or an explicit bump workflow) set `x.y.z`; CI never auto-patches on merge.
2. **Auto build number** — store/ASC latest + 1 at upload; do not commit build counters.
3. **Separate test vs release tracks** — develop/internal vs main/external (iOS groups; Play tracks on Android).
4. **One upload queue** — serialize store uploads to avoid build-number races.
5. **Path filters** — auto-upload only when shipping paths change; manual deploy always available.
6. **No production submit in CI** until explicitly added — TestFlight / internal testing first.
7. **Local secrets in `.env`** — same variable names as CI; gitignored; loaded via direnv and/or Fastlane `Dotenv`.

## First-time checklist (any app)

For the short post-scaffold path, see **[Operator runbook (1–6)](./IOS-TESTFLIGHT.md#operator-runbook-16)**.

- [ ] Store admin access (ASC / Play Console)
- [ ] API key / service account for CI (no interactive Apple ID in CI)
- [ ] Private Match (or equivalent) certificates repo + deploy key or PAT
- [ ] GitHub Actions secrets configured (see [SECRETS.md](./SECRETS.md))
- [ ] Local `.env` filled for admin Match init (see [SECRETS.md](./SECRETS.md#local-env-direnv--fastlane))
- [ ] Tester groups created in the store console
- [ ] First Match init pushed encrypted certs
- [ ] First manual deploy proves end-to-end upload

## Per-app instance (fill in the client repo)

Document only in the app’s delivery profile / Fastlane README — not as hard-coded defaults in this playbook:

- Bundle ID / application ID
- Apple team ID / Play package name
- Match git URL
- TestFlight / Play track or group names
- Path filters for the app sources
