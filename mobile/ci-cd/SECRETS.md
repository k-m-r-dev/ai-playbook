# Secrets — names and how to obtain

Never commit secret **values**.

| Where | What |
| --- | --- |
| **GitHub Actions** | Repo (or org) → Settings → Secrets and variables → Actions |
| **Local admin Mac** | Gitignored project-root `.env` (same names; see [Local `.env`](#local-env-direnv--fastlane)) |

## iOS (TestFlight + Match)

| Name | Description |
| --- | --- |
| `ASC_KEY_ID` | App Store Connect API key id |
| `ASC_ISSUER_ID` | App Store Connect issuer UUID |
| `ASC_KEY_CONTENT` | Base64-encoded contents of the `.p8` API key file |
| `MATCH_PASSWORD` | Passphrase encrypting certificates in the Match git repo |
| `MATCH_GIT_URL` | SSH URL of the private Match certificates repo (`git@github.com:ORG/REPO.git`) |
| `MATCH_SSH_PRIVATE_KEY` | **CI only:** private key for a deploy key on the Match repo |
| `MATCH_GIT_BASIC_AUTHORIZATION` | **Optional alternative to deploy key:** Base64 of `x-access-token:<GITHUB_PAT>` for HTTPS clone |

**Recommended CI path:** deploy key + `MATCH_SSH_PRIVATE_KEY` + `webfactory/ssh-agent`. Do not set `MATCH_GIT_BASIC_AUTHORIZATION` when using the deploy-key path.

## GitHub token (bump workflow)

| Name | Description |
| --- | --- |
| `GITHUB_TOKEN` | Provided by Actions; needs `contents: write` on the bump workflow |

If branch protection blocks bot pushes, allow `github-actions[bot]` or use a documented PAT secret with bypass rules.

## Android (future)

| Name | Description |
| --- | --- |
| `PLAY_SERVICE_ACCOUNT_JSON` | Play Console API service account (base64) |
| `ANDROID_KEYSTORE_BASE64` | Release keystore |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_ALIAS` | Key alias |
| `ANDROID_KEY_PASSWORD` | Key password |

---

## Local `.env` (direnv + Fastlane)

Avoid `export …` every session. Store the **same names** as CI in a gitignored `.env`.

### Layout

```bash
# .envrc (direnv)
source_env_if_exists .envrc.local
dotenv_if_exists .env
```

```ruby
# fastlane/Fastfile (so Fastlane works even without direnv)
require "dotenv"
Dotenv.load(File.expand_path("../.env", __dir__))
```

Document placeholders in **`.env.sample`** (committed). Real values only in **`.env`** (gitignored).

### Suggested `.env.sample` keys (iOS)

```bash
# App Store Connect API
ASC_KEY_ID=
ASC_ISSUER_ID=
ASC_KEY_CONTENT=

# Match
MATCH_PASSWORD=
MATCH_GIT_URL=git@github.com:ORG/your-match-certificates.git

# Local SSH to Match repo — key PATH, not PEM contents
GIT_SSH_COMMAND=ssh -i ~/.ssh/id_ed25519_match_deploy -o IdentitiesOnly=yes
```

| Local | CI |
| --- | --- |
| `ASC_*`, `MATCH_PASSWORD`, `MATCH_GIT_URL` | Same secret names |
| `GIT_SSH_COMMAND` → path to deploy-key private file | `MATCH_SSH_PRIVATE_KEY` → PEM contents in Actions |

**Do not** put the deploy-key PEM in `.env`. Locally reference the file path via `GIT_SSH_COMMAND`.

### After editing `.env`

```bash
direnv allow    # once per clone/machine
direnv reload
bundle exec fastlane match appstore --readonly false
```

---

## How to obtain each secret

Do these once per Apple Developer team (iOS) or Play Console account (Android).

### 1. `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_CONTENT`

**Who:** App Store Connect **Admin** (or App Manager with API key permission).

1. [App Store Connect](https://appstoreconnect.apple.com) → **Users and Access** → **Integrations** → **App Store Connect API**.
2. Copy **Issuer ID** → `ASC_ISSUER_ID`.
3. **Generate API Key** (e.g. name `ci-testflight`, access **Admin**).
4. Copy **Key ID** → `ASC_KEY_ID`.
5. Download `.p8` once; encode:
   ```bash
   # macOS
   base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy
   # Linux
   base64 -w0 AuthKey_XXXXXXXXXX.p8
   ```
   → `ASC_KEY_CONTENT`.
6. Put the three values in GitHub Actions secrets **and** local `.env`.

### 2. `MATCH_PASSWORD`

Team-chosen passphrase (not from Apple).

1. Generate a strong random passphrase (password manager or `openssl rand -base64 32`). Prefer printable ASCII without leading/trailing whitespace.
2. Store as GitHub secret `MATCH_PASSWORD` and in local `.env`.
3. Share out-of-band with admins who run Match — same value for the life of that Match repo.
4. In `Matchfile`, set `force_legacy_encryption(true)` so Match avoids OpenSSL AES-GCM failures (`couldn't set additional authenticated data` / `Error encrypting … .cer`) on common macOS OpenSSL stacks. Keep the same setting for every machine and CI that encrypts or decrypts that Match repo.

### 3. `MATCH_GIT_URL`

1. Create (or reuse) a **private** git repo for Match storage (empty is fine for first init).
2. Use the SSH form: `git@github.com:ORG/REPO.git`.
3. Set in Matchfile default and/or GitHub secret + local `.env`.

### 4. Match repo access for CI — deploy key (recommended)

1. Generate a dedicated key pair (do not reuse your personal GitHub key):
   ```bash
   ssh-keygen -t ed25519 -C "ci-match-deploy" -f ~/.ssh/id_ed25519_match_deploy -N ""
   ```
2. Match certificates repo → Settings → **Deploy keys** → add the **`.pub`** key.
   - Enable **Allow write access** for the **first** Match init (Match commits encrypted files). After init, read-only is enough for CI if you never regenerate certs from Actions; keeping write is OK if CI may refresh profiles.
3. App repo → Actions secret **`MATCH_SSH_PRIVATE_KEY`** = full private key PEM (`BEGIN`/`END` lines).
4. Local `.env`: set `GIT_SSH_COMMAND` to use that private key **path** (see sample above).
5. Reusable workflow before Fastlane:
   ```yaml
   - name: Start SSH agent for Match
     uses: webfactory/ssh-agent@v0.9.0
     with:
       ssh-private-key: ${{ secrets.MATCH_SSH_PRIVATE_KEY }}

   - name: Trust GitHub host key
     run: |
       mkdir -p ~/.ssh
       ssh-keyscan -t ed25519,rsa github.com >> ~/.ssh/known_hosts
   ```
6. Do **not** set `MATCH_GIT_BASIC_AUTHORIZATION` when using this path.

### 5. `MATCH_GIT_BASIC_AUTHORIZATION` (optional HTTPS alternative)

Use only if you are not using a deploy key.

1. Fine-grained PAT with **Contents: Read** (and Write if Match must push from CI) on the Match repo only.
2. Encode:
   ```bash
   echo -n "x-access-token:YOUR_GITHUB_PAT" | base64 | pbcopy
   ```
3. Store as `MATCH_GIT_BASIC_AUTHORIZATION` on the **app** repo. Wire HTTPS URL rewrite in the workflow if Matchfile uses SSH URLs.

### 6. `GITHUB_TOKEN` (bump workflow)

Usually automatic. Grant `permissions: contents: write` on the bump workflow. See earlier table if branch protection blocks the bot.

### 7. Android secrets (when Play upload is implemented)

#### `PLAY_SERVICE_ACCOUNT_JSON`

1. Google Cloud → service account JSON key.
2. Play Console → invite that email with release permissions.
3. Base64-encode JSON → secret.

#### Keystore secrets

1. Create a release keystore once; back it up offline.
2. Store base64 keystore + passwords/alias as the four Android secrets in the table above.

---

## First Match init (once per Apple team / Match repo)

This is **step 4** of the [Operator runbook (1–6)](./IOS-TESTFLIGHT.md#operator-runbook-16).

Prerequisites: ASC values + `MATCH_PASSWORD` + deploy key on Match repo + local `.env` filled.

```bash
cd <ios-app-repo>
direnv allow && direnv reload   # or rely on Fastlane Dotenv.load of .env
bundle install
bundle exec fastlane match appstore --readonly false
```

This creates the encrypted Distribution certificate and App Store provisioning profile in the Match git repo and pushes them. Later CI runs use `match` with `readonly: true` (typical when `CI=true`).

If encrypt fails with `couldn't set additional authenticated data` / `Error encrypting …`, confirm `force_legacy_encryption(true)` is in `Matchfile`, then re-run. Cert/profile may already exist on the Apple portal from a partial run — Match should reuse them.

If Match created a Distribution cert on Apple but failed before the git push, the Match repo may be missing the `.p12`. Prefer `match import` with a matching Keychain-exported `.cer`/`.p12` over creating another cert (Apple enforces a low Distribution cert limit).

If git commit fails with a global `LARGE DIFF DETECTED` pre-commit hook while Match is pushing encrypted profiles, disable that hook (machine-wide or Match-repo-only). Backup/restore notes: [`scripts/git-hooks/README.md`](../../scripts/git-hooks/README.md).

---

## Wire secrets into GitHub (any app)

This is **step 3** (and the smoke check in **step 6**) of the [Operator runbook (1–6)](./IOS-TESTFLIGHT.md#operator-runbook-16).

1. App repo (or org) → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**.
2. Add: `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_CONTENT`, `MATCH_PASSWORD`, `MATCH_GIT_URL`, `MATCH_SSH_PRIVATE_KEY` (deploy-key path).
3. Run **Deploy TestFlight** (manual) once after Match init to confirm clone, signing, and upload.
