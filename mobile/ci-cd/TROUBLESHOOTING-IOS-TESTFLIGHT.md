# iOS TestFlight CI — troubleshooting (simple guide)

What went wrong when first wiring **Fastlane Match + GitHub Actions → TestFlight**, how we fixed it, and how to avoid the same pain.

Keep this guide **product-agnostic**. Put app-specific IDs and secret *names* in the app repo; never put secret *values* here.

---

## Short version

| Layer | Password | Who uses it |
| --- | --- | --- |
| Match **git repo** encryption | `MATCH_PASSWORD` | Decrypts files cloned from the Match certificates repo |
| macOS **keychain** unlock | `MATCH_KEYCHAIN_PASSWORD` (CI) | Created by Fastlane `setup_ci` on GitHub runners — you usually do **not** set this by hand |
| Distribution **`.p12` file** | Set when you export the private key | Apple `security import` unlocks the private key |

**Most common CI failure we hit:** Match decrypts the repo with `MATCH_PASSWORD`, then imports the `.p12` with an **empty** passphrase. If your `.p12` was exported with any non-empty password (including `MATCH_PASSWORD`), CI installs only the public certificate → archive fails with “no private key”.

---

## Three passwords (do not mix them)

### 1. `MATCH_PASSWORD`

- Encrypts/decrypts the Match certificates **git** storage.
- Same value in GitHub Actions secrets **and** local `.env`.
- No trailing spaces or newlines in the GitHub secret.

### 2. Keychain password

- On CI, Fastlane `setup_ci` creates a temporary keychain (`fastlane_tmp_keychain`) with a known password.
- Call **`setup_ci` before `match`** when `CI=true`.
- A dialog asking for an **“apple” keychain** password on your Mac is unrelated to Match CI — cancel it unless you created that keychain on purpose.

### 3. `.p12` passphrase

- Chosen when you export the Distribution identity from Keychain (or create a `.p12` with OpenSSL).
- Fastlane Match’s installer imports PKCS#12 with **`certificate_password: ""`** (empty). It does **not** pass `MATCH_PASSWORD` into `security import`.

---

## What we saw (symptoms → meaning)

### A. `MAC verification failed during PKCS12 import (wrong password?)`

Then later:

`No "iOS Distribution" signing certificate … with a private key was found`

**Meaning:** Match decrypted storage OK, but `security import` could not unlock the private key. Only the `.cer` (public) was installed.

### B. Local `openssl … -passin env:MATCH_PASSWORD` says FAIL with `RC2-40-CBC … unsupported`

**Meaning:** Homebrew OpenSSL 3 needs `-legacy` for Apple Keychain `.p12` files. This is **not** the same as a wrong password.

```bash
openssl pkcs12 -in /path/to/cert.p12 -nokeys -passin env:MATCH_PASSWORD -out /dev/null -legacy \
  && echo "unlock: OK" || echo "unlock: FAIL"
```

### C. OpenSSL says empty unlock OK, but CI still fails PKCS12

**Meaning:** OpenSSL and Apple `security` disagree. An OpenSSL-made “empty password” `.p12` often still fails `security import` on CI. Do not trust OpenSSL alone — verify with:

```bash
security import /path/to/cert.p12 -k ~/Library/Keychains/login.keychain-db -P 'THE_PASS' -T /usr/bin/codesign
```

(Use a throwaway/temp keychain in scripts; avoid UI prompts when possible.)

### D. Match said import/push succeeded, but CI still fails

Confirm the Match repo actually got a **new commit** on `main` after your local `match import`. Re-running an old Actions job without a new Match commit (or without the Fastfile fix) will keep failing.

---

## How we fixed it (working pattern)

### Step 1 — CI keychain

In the Fastfile, when running on CI:

1. `setup_ci`
2. then `match(..., readonly: true, …)`

Without `setup_ci`, Match cannot reliably install the private key into a usable keychain on GitHub’s macOS runners.

### Step 2 — Store a real Keychain-exported `.p12` in Match

Prefer exporting from **Keychain Access** (Apple’s format), not inventing an empty-password `.p12` with OpenSSL.

Keep that `.p12` protected with a passphrase you control (often the same string as `MATCH_PASSWORD` for fewer secrets to remember — but remember: Match’s *built-in* import still uses empty unless you add a follow-up step).

Import into Match storage:

```bash
cd <ios-app-repo>
unset GIT_SSH_COMMAND   # if a sticky GIT_SSH_COMMAND breaks clone
direnv reload           # if you use direnv for .env
bundle exec fastlane match import --type appstore
# .cer + .p12 (+ optional existing .mobileprovision; skip if unchanged)
```

You do **not** need a new provisioning profile if you only change the `.p12` password for the **same** Distribution certificate.

### Step 3 — Re-import the private key after `match` (required with stock Match)

Because Match imports PKCS#12 with an empty passphrase, add a CI-only follow-up after `match`:

1. Clone the Match repo (SSH deploy key already on the runner).
2. Decrypt files with Match encryption (`MATCH_PASSWORD`, `force_legacy_encryption` if you use legacy).
3. Call Fastlane `import_certificate` with:
   - `certificate_password:` = the real `.p12` passphrase (e.g. `ENV["MATCH_PASSWORD"]`)
   - `keychain_name` / `keychain_password` from `setup_ci` (`MATCH_KEYCHAIN_NAME`, `MATCH_KEYCHAIN_PASSWORD`)

Expect Match to still **log** a PKCS12 warning (empty import). The follow-up step should print `1 identity imported`, then archive/upload succeeds.

### Step 4 — Matchfile hardening

In `Matchfile`:

- `git_branch("main")`
- `clone_branch_directly(true)`
- `force_legacy_encryption(true)` — avoids OpenSSL AES-GCM encrypt failures on common Mac setups

### Step 5 — Ruby / Bundler on CI

- Use Ruby **3.1.x** if gems like `CFPropertyList` require `ruby < 3.2`.
- Use Bundler **2.5.x** (not system Bundler 1.17). Align `Gemfile.lock` `BUNDLED WITH` and `ruby/setup-ruby` `bundler:`.

### Step 6 — Match git auth

- CI: passphrase-less deploy key → `MATCH_SSH_PRIVATE_KEY` + `webfactory/ssh-agent`.
- Local: prefer a personal SSH host alias **or** `GIT_SSH_COMMAND` → key **path**. Never put the private key PEM in `.env`.

### Step 7 — Export compliance (TestFlight “Missing Compliance”)

If the app only uses exempt encryption (HTTPS / Apple system crypto):

- Set `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` (Debug + Release), and/or
- Pass `uses_non_exempt_encryption: false` to `upload_to_testflight`.

That avoids clicking **Manage** on every build. Do **not** claim “no encryption” if you ship non-exempt crypto.

---

## What to avoid

1. **Assuming `MATCH_PASSWORD` unlocks the `.p12` inside Match’s default import** — it only decrypts git storage; stock Match imports PKCS#12 with an empty passphrase.
2. **Re-importing the same bad `.p12`** — if the passphrase is wrong for Apple `security`, importing again does nothing useful.
3. **OpenSSL “empty password” `.p12` as a “fix”** — often fails `security import` on CI even when `openssl … -passin pass:` looks OK.
4. **Creating another Distribution certificate** when the team is at the portal limit — use `match import` with the existing `.cer` + `.p12`.
5. **Skipping `setup_ci` on GitHub Actions** — private key won’t land in a usable keychain.
6. **Mixing SSH host-alias Match URLs with a deploy-key `GIT_SSH_COMMAND`** — clones fail or hang; pick one auth style.
7. **Global git hooks blocking Match commits** of encrypted blobs — disable hooks for Match repo commits when needed.
8. **Running unit tests in parallel** if tests share `UserDefaults` / singletons — disable parallel testing on CI or isolate stores in tests.

---

## Precautions (checklist before the next Match / TF change)

### Before first Match init or `match import`

- [ ] `MATCH_PASSWORD` set identically in Actions and local `.env` (no whitespace surprises).
- [ ] Match repo has `main` with an initial commit; Matchfile uses `git_branch("main")` + `clone_branch_directly(true)` + `force_legacy_encryption(true)`.
- [ ] You know whether the `.p12` passphrase is empty or not — verify with `security import`, not only OpenSSL.
- [ ] If using a non-empty `.p12` passphrase, plan the **post-`match` `import_certificate`** step in the Fastfile (or store keys the way Match’s generator does).

### After every `match import`

- [ ] New commit appeared on the Match repo remote (`git log` / GitHub).
- [ ] Local decrypt round-trip works with `MATCH_PASSWORD`.
- [ ] Re-run TestFlight (or path-filtered develop push) **after** Match + Fastfile fixes are on the remote the CI uses.

### On every CI TestFlight workflow

- [ ] `setup_ci` before `match` when `CI=true`.
- [ ] SSH agent has the Match deploy key before Fastlane runs.
- [ ] ASC API key secrets present (`ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_CONTENT`).
- [ ] Workflows that should appear in the Actions sidebar also exist on the **default branch** (often `main`) — files only on `develop` may stay hidden until merged or run once.

### Local verification commands (safe patterns)

```bash
# 1) Unlock check (OpenSSL 3 needs -legacy for Apple p12)
openssl pkcs12 -in /path/to/dist.p12 -nokeys -passin env:MATCH_PASSWORD -out /dev/null -legacy

# 2) Confirm Match remote moved
cd <match-certificates-repo> && git fetch && git log -1 --oneline origin/main
```

---

## Companion: unit-test CI flakiness

### Malloc crash (`pointer being freed was not allocated`) mid XCTest

**Symptom:** CI kills the test host during `EditProfileViewModelTests` / `GuestUserViewModelTests` (often right after creating a ViewModel). Same address can appear across restarts. Local often passes.

**Cause:** The unit-test host is the real app process. If `@main` boots `RootView()` (live Factory graph + tabs) while XCTest also creates `@MainActor` `ObservableObject`s, CI (Xcode 26 / fresh simulator) can crash. Local timing often hides it.

**Fix:** When `XCTestConfigurationFilePath` is set, show `EmptyView()` instead of the live shell (see app `UnitTestRuntime`). Keep UI tests unaffected — `XCUIApplication` launches without that env var.

**Also:** Prefer injecting test doubles (e.g. `NeverSubscribedGate`) instead of `Container.shared` defaults inside unit tests.

### Parallel XCTest clones (`Clone 1` / `Clone 2`, `0.000s` failures)



If unit tests fail with `failed (0.000 seconds)` and no assert text, and logs show `Clone 1` / `Clone 2` of the same simulator:

- Tests likely share `UserDefaults` or singletons across parallel workers.
- On CI, prefer:

```bash
xcodebuild … -only-testing:<UnitTestBundle> \
  -parallel-testing-enabled NO \
  -maximum-parallel-testing-workers 1 \
  test
```

Upload the `.xcresult` on failure for diagnosis. Keep TestFlight CD separate unless you intentionally gate on unit tests.

---

## Related docs

- [IOS-TESTFLIGHT.md](./IOS-TESTFLIGHT.md) — setup, lanes, operator runbook  
- [SECRETS.md](./SECRETS.md) — secret names and local `.env`  
- [GITFLOW.md](./GITFLOW.md) — develop / main / hotfix  
