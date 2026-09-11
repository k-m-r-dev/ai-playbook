# iOS — Fastlane + GitHub Actions → TestFlight

Portable pattern for any iOS app using this playbook.

## Stack

- **Fastlane** — Match, gym, `upload_to_testflight`
- **GitHub Actions** — `macos-15`, Xcode latest-stable, Ruby + Bundler
- **Signing** — Match private repo + ASC API key (no Apple ID password in CI)
- **Local Xcode** — keep **Automatic** signing; CI overrides to Distribution for Release archive only
- **Local secrets** — project-root `.env` (see [SECRETS.md](./SECRETS.md#local-env-direnv--fastlane))

## TestFlight groups (convention)

Name groups clearly in App Store Connect; wire exact strings into Fastlane.

| Track | Typical ASC group(s) | Trigger |
| --- | --- | --- |
| Internal / develop | Internal / develop group | Push to `develop` (path-filtered) or manual deploy `internal` |
| Release / main | External / release group **+** internal group | Push to `main` (path-filtered) or manual deploy `external` |

## Workflows (recommended shape)

| Workflow | Trigger | Lane |
| --- | --- | --- |
| `testflight-develop.yml` | push `develop` + path filters | `beta_internal` |
| `testflight-main.yml` | push `main` + path filters | `beta_release` |
| `deploy-testflight.yml` | `workflow_dispatch` (`ref`, `track`, changelog) | `beta_internal` or `beta_release` |
| `bump-version.yml` | `workflow_dispatch` (branch, patch/minor/major/set) | `bump_marketing_version` |
| `_testflight-reusable.yml` | reusable | shared build/upload + Match SSH agent |

**Concurrency:** all upload workflows share `concurrency.group: testflight-upload`, `cancel-in-progress: false`.

**Path filters (auto only):** app sources, Xcode project, `fastlane/**`, `Gemfile`, `Gemfile.lock`, `Package.resolved` if used, workflow files. Manual deploy ignores path filters.

**Match auth in CI (recommended):** deploy key → secret `MATCH_SSH_PRIVATE_KEY` + `webfactory/ssh-agent` (see [SECRETS.md](./SECRETS.md)). Prefer SSH `MATCH_GIT_URL` (`git@github.com:org/certs-repo.git`).

## Fastlane lanes

| Lane | Behavior |
| --- | --- |
| `beta_internal` | Match → next build → archive → TF → internal group(s) |
| `beta_release` | Match → next build → archive → TF → external + internal group(s) |
| `bump_marketing_version` | `BUMP_MODE=patch\|minor\|major\|set`, optional `VERSION` for set |

Build number: `latest_testflight_build_number(version: current marketing) + 1` then `increment_build_number` — **not** committed.

## Operator runbook (1–6)

Use this after Fastlane + workflows exist in the app repo. Details: [SECRETS.md](./SECRETS.md).

1. **Confirm Match deploy key** — Match certificates repo → Settings → Deploy keys → public key present; **write** enabled for first Match init (read is enough for later CI-only clones if you never refresh certs from Actions).
2. **Create `MATCH_PASSWORD`** — strong passphrase; store in GitHub Actions **and** local `.env` (same value).
3. **Wire GitHub Actions secrets** on the app repo: `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_CONTENT`, `MATCH_PASSWORD`, `MATCH_GIT_URL`, `MATCH_SSH_PRIVATE_KEY` (deploy-key PEM). Prefer deploy key + `webfactory/ssh-agent` (not `MATCH_GIT_BASIC_AUTHORIZATION`). Fill local `.env` with the same ASC/Match values; use `GIT_SSH_COMMAND` pointing at the deploy-key **file path** (do not put the PEM in `.env`).
4. **First Match init (once)** — on an admin Mac:
   ```bash
   cd <ios-app-repo>
   direnv allow && direnv reload   # if using direnv
   bundle install
   bundle exec fastlane match appstore --readonly false
   ```
   Confirms encrypted Distribution cert + App Store profile are committed to the Match repo. Require `force_legacy_encryption(true)` in `Matchfile` (avoids OpenSSL AES-GCM encrypt failures on common macOS stacks).
5. **Land CI on GitHub** — commit/push the Fastlane + workflow branch; confirm Actions secrets are on the app repo.
6. **Smoke upload** — Actions → **Deploy TestFlight** → choose a ref + track `internal`. Confirm the build appears in the internal TestFlight group. Then rely on path-filtered auto uploads for `develop` / `main`.

## Setup sequence (new app)

1. Create private Match certificates repo (empty is fine).
2. Create ASC API key; create TestFlight groups.
3. Add GitHub Actions secrets ([SECRETS.md](./SECRETS.md)).
4. Add Fastlane (`Gemfile`, `Appfile`, `Matchfile`, `Fastfile`) + workflows; keep Automatic signing in Xcode.
5. Fill local `.env`; run first Match init (`match appstore --readonly false`).
6. Push app CI branch; run **Deploy TestFlight** (manual) once for internal track.
7. Confirm build appears in the internal group; then enable auto workflows.

## Adding another iOS app (same Apple team)

1. Copy Fastlane + workflow pattern from an existing app on this playbook.
2. Update `Appfile`, `Matchfile`, bundle ID, team ID, group names, path filters.
3. Reuse the same Match repo (add the new `app_identifier`) or follow team policy for a separate Match repo.
4. Wire secrets; first Match sync for the new bundle ID; manual deploy once.

## Out of scope (until a future milestone)

- App Store **Submit for Review** / release to App Store
- CI Slack/email notifications
- Auto marketing version bumps on merge

## Unit-test CI (optional companion)

Keep TestFlight CD separate. Add a **CI — unit tests** workflow on `push`/`pull_request` to `develop`/`main` that runs:

```bash
xcodebuild -scheme <Scheme> -configuration Debug \
  -destination 'platform=iOS Simulator,name=<iPhone>' \
  -only-testing:<UnitTestBundle> test
```

Do **not** block TestFlight on this unless you intentionally wire `workflow_run` / required checks. UI tests are optional and slower — start with unit tests only.

## Troubleshooting

**Full walkthrough (simple language):** [TROUBLESHOOTING-IOS-TESTFLIGHT.md](./TROUBLESHOOTING-IOS-TESTFLIGHT.md) — three passwords, PKCS12 / private-key failures, what we fixed, what to avoid, and a precaution checklist.

| Symptom | Check |
| --- | --- |
| Match clone fails in CI | `MATCH_SSH_PRIVATE_KEY` + ssh-agent; deploy key on Match repo; SSH `MATCH_GIT_URL` |
| Match clone fails locally | Prefer personal SSH host-alias URL **or** deploy-key path via `GIT_SSH_COMMAND` — do not mix host-alias URL with a deploy-key `GIT_SSH_COMMAND`. `direnv reload` after `.env` edits |
| Match hang on `git clone` (empty/`master`) | Seed Match repo with an initial commit on `main`; set `git_branch("main")` + `clone_branch_directly(true)` in Matchfile |
| `couldn't set additional authenticated data` / `Error encrypting …` | Set `force_legacy_encryption(true)` in Matchfile; confirm `MATCH_PASSWORD` has no stray whitespace; re-run |
| Max Distribution certificates / Match tries to create another cert | Portal already has a cert but Match storage never got the `.p12` (partial init). Export matching `.cer`+`.p12` from Keychain → `bundle exec fastlane match import --type appstore`. Do not keep creating certs |
| Match encrypts OK but `Couldn't commit or push` / `LARGE DIFF DETECTED` | A global `core.hooksPath` pre-commit is blocking intentional Match blob commits. Disable hooks for that machine or only for the Match repo (`git config core.hooksPath /dev/null`). See [`scripts/git-hooks/README.md`](../../scripts/git-hooks/README.md) |
| Duplicate build number | concurrency group; retry after prior upload finishes |
| Upload OK, testers see nothing | exact group name spelling in ASC |
| External testers blocked | Beta App Review for first external build of a version |
| Archive: No signing certificate / private key on CI | Call `setup_ci` before `match` on CI so Match imports into a temp keychain with a known password (not locked `login.keychain`) |
| Match installs cert but CI says no private key / `MAC verification failed during PKCS12 import` | Stock Match imports PKCS#12 with an **empty** passphrase (not `MATCH_PASSWORD`). If your `.p12` has a non-empty passphrase, add a post-`match` `import_certificate` with that passphrase into the `setup_ci` keychain. See [TROUBLESHOOTING-IOS-TESTFLIGHT.md](./TROUBLESHOOTING-IOS-TESTFLIGHT.md) |
| OpenSSL unlock FAIL with `RC2-40-CBC unsupported` | Use `openssl pkcs12 … -legacy` locally; not the same as a wrong password |
| OpenSSL empty-pass `.p12` still fails on CI | Apple `security import` often rejects OpenSSL empty-pass exports — prefer Keychain Access export + post-`match` import |
| Archive signing fails | Match readonly + `update_code_signing_settings` for Release only; do not force `CODE_SIGN_IDENTITY` via gym `xcargs` (breaks SPM packages) |
| `bundle` fails with `undefined method untaint` on CI | `Gemfile.lock` was generated with Bundler 1.x (system Ruby). Set `BUNDLED WITH` to Bundler 2.x (e.g. 2.5.23), pin `bundler:` in `ruby/setup-ruby`, keep Bundler 2.x + a Ruby that matches the lockfile |
| `CFPropertyList` requires ruby `< 3.2` on CI | Lockfile resolved under older Ruby. Use Ruby **3.1** in `ruby/setup-ruby` / `.ruby-version`, or regenerate `Gemfile.lock` on Ruby 3.2+ |
| Missing ASC vars in Fastlane | Root `.env` loaded (`Dotenv` in Fastfile and/or direnv). Standalone `fastlane match` expects `APP_STORE_CONNECT_API_KEY_*` (or Matchfile api_key) — `ASC_*` alone still prompts Apple ID/2FA for portal login |
| TestFlight “Missing Compliance” every build | Set `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` when only exempt encryption is used; optionally `uses_non_exempt_encryption: false` on `upload_to_testflight` |
| Unit tests fail `0.000s` with Clone 1/Clone 2 | Disable parallel testing on CI if tests share UserDefaults/singletons |
| Manual workflows missing from Actions sidebar | Workflow files must live on the **default branch** (often `main`) or have run at least once; `workflow_call` reusable files are not standalone |
| Success criteria for first Match init | Remote Match repo has encrypted `certs/distribution/*` **and** `profiles/appstore/*.mobileprovision`; log shows encrypt + `git push` + “All required keys, certificates and provisioning profiles are installed” |
