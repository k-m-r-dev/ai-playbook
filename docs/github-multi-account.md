# GitHub multi-account setup (work + personal)

Playbook reference for developers who use **two or more GitHub accounts** on one machine (typical: work `kmrfn` + personal `k-m-r-dev`). Validated on the **bitoron** workspace (`~/Workspace/self/bitoron`).

Agents and `gh` do **not** auto-pick an account from `git remote` or commit identity. You must wire identity (git), transport (SSH), and API (`gh`) separately.

## Three layers (all independent)

| Layer | What it controls | Typical work setup | Typical personal setup |
| --- | --- | --- | --- |
| **Git commit identity** | `user.name`, `user.email`, GPG signing | `~/.gitconfig` default | `~/.gitconfig-personal` via `includeIf` |
| **Git transport (SSH)** | Which key talks to GitHub | `Host fn.github.com` → work key | `Host bitoron-tech.github.com` → personal key |
| **GitHub CLI (`gh`)** | PRs, issues, API | active account or per-repo token | `GH_TOKEN` from `gh auth token -u …` |

Missing any layer causes silent wrong-account bugs (e.g. SSH push works but `gh pr create` hits the wrong org).

---

## Approach A — Global `gh` wrapper (shell-wide)

Map **SSH host in `git remote`** → **gh username**, wrap `gh` in `~/.zshrc`:

```bash
_gh_user_for_repo() {
  local remote="${1:-$(git remote get-url origin 2>/dev/null)}"
  [[ -z "$remote" ]] && return 1
  case "$remote" in
    git@bitoron-tech.github.com:*|git@mahmudur85.github.com:*|git@OpenW2C.github.com:*)
      echo "k-m-r-dev" ;;
    git@fn.github.com:*)
      echo "kmrfn" ;;
    *github.com:bitoron-tech/*|*github.com:OpenW2C/*)
      echo "k-m-r-dev" ;;
    *) return 1 ;;
  esac
}

gh() {
  local user token
  if user=$(_gh_user_for_repo); then
    token=$(command gh auth token -u "$user" 2>/dev/null) || {
      echo "gh: no token for $user — run: gh auth login" >&2
      return 1
    }
    GH_TOKEN="$token" command gh "$@"
  else
    command gh "$@"
  fi
}
```

**Pros:** Works in every repo without per-project files; mirrors SSH host aliases.  
**Cons:** Global shell change; Cursor agents only see it if their shell loads `~/.zshrc`; mapping table lives in dotfiles, not the repo.

**When to use:** You want one machine-wide rule and rarely add new orgs.

---

## Approach B — Per-repo `direnv` + `.envrc` / `.envrc.local` `[recommended for playbook clients]`

Set `GH_TOKEN` from the gh keychain (no secret on disk). Two layouts are valid:

**Greenfield** — playbook block in `.envrc`:

```bash
# BEGIN ai-playbook:gh-account
# gh CLI account for this repo (no secret stored; token read from gh keychain).
export GH_TOKEN="$(gh auth token -u k-m-r-dev)"
# END ai-playbook:gh-account
```

**Existing client direnv** `[preferred when .envrc already loads dotenv / other hooks]` — keep project `.envrc`, put the token in gitignored `.envrc.local`:

```bash
# .envrc
source_env_if_exists .envrc.local
dotenv_if_exists .env
```

```bash
# .envrc.local (machine-local; gitignore it)
# BEGIN ai-playbook:gh-account
export GH_TOKEN="$(gh auth token -u kmrfn)"
# END ai-playbook:gh-account
```

`configure-client-git-account.sh --check` accepts either layout. On write, if `.envrc` already exists without the playbook marker, the script writes `.envrc.local` and adds `source_env_if_exists .envrc.local` — it does **not** overwrite client direnv.

Then once per repo:

```bash
direnv allow
```

**Pros:** Account choice is per-repo; Cursor/agents inherit `GH_TOKEN` when direnv is active; no global wrapper; coexists with existing `.envrc`.  
**Cons:** Requires [direnv](https://direnv.net/); each client needs allow + (for local layout) `.envrc.local` gitignored.

**When to use:** Client projects under ai-playbook + W2C/GSD where agents run `gh` for PRs/issues. **bitoron uses this.**

Playbook installs via:

```bash
bash scripts/configure-client-git-account.sh \
  --client-repo /path/to/client \
  --gh-user k-m-r-dev
```

Or during `configure-client-project` / the **configure-client-project** skill interview.

---

## Approach C — Manual `gh auth switch`

```bash
gh auth login -h github.com   # once per account
gh auth switch -u kmrfn       # or k-m-r-dev
gh auth status
```

**Pros:** No wrapper, no `.envrc`.  
**Cons:** Switches the **global** active account; other terminals and agents race; easy to forget before `gh pr create`.

**When to use:** Quick one-off commands only—not recommended for agent-driven workflows.

---

## Git commit identity — split gitconfig (`includeIf`)

Keep work as the default; overlay personal identity by directory.

`~/.gitconfig` (work default + includes):

```gitconfig
[user]
    name = kmrfn
    email = mahmudur.rahman@fieldnation.com
    signingkey = <work-gpg-key>

[includeIf "gitdir:~/Workspace/self/"]
    path = ~/.gitconfig-personal
```

`~/.gitconfig-personal`:

```gitconfig
[user]
    name = k-m-r-dev
    email = mahmudur85@gmail.com
    signingkey = <personal-gpg-key>

[github]
    user = k-m-r-dev
```

Verify inside a client repo:

```bash
git config user.name user.email
git config --list --show-origin | grep user
```

**Note:** `includeIf "gitdir:~/Workspace/self/"` applies to **all** repos under that tree. Keep work clones outside that path, or use a narrower `gitdir:` (e.g. `~/Workspace/self/bitoron/`).

---

## SSH host aliases + URL rewrites

`~/.ssh/config` — one `Host` per org/account, each with its own key:

```sshconfig
Host fn.github.com
  HostName github.com
  IdentityFile ~/.ssh/id_ed25519_fn

Host bitoron-tech.github.com
  HostName github.com
  PreferredAuthentications publickey
  IdentityFile ~/.ssh/id_ed25519_mahmudur85
```

`~/.gitconfig` — rewrite canonical GitHub URLs to the alias (so remotes can stay org-prefixed):

```gitconfig
[url "git@fn.github.com:fieldnation"]
    insteadOf = git@github.com:fieldnation

[url "git@bitoron-tech.github.com:bitoron-tech"]
    insteadOf = git@github.com:bitoron-tech
```

Remotes then look like:

```text
git@bitoron-tech.github.com:bitoron-tech/bitoron-workspace.git
```

Plain `git@github.com:…` still works via `insteadOf` rewrite.

---

## One-time gh login (both accounts)

```bash
gh auth login -h github.com -p ssh -s repo,read:org,workflow
# repeat for second account when prompted
gh auth status
```

No re-login until a token expires. Per-repo `.envrc` reads tokens via `gh auth token -u <user>`.

---

## Cursor / agent implications

| Mechanism | Agents see correct `gh` account? |
| --- | --- |
| `.envrc` + direnv allowed | Yes (when IDE loads direnv) |
| Global `gh` wrapper in zshrc | Only if agent shell is login/interactive |
| `gh auth switch` before task | Fragile — easy to drift |
| `GH_TOKEN` exported in command | Yes for that invocation |

For W2C milestone PR flows, prefer **Approach B** so the repo documents which account agents must use.

---

## Optional machine registry

For richer discovery during `configure-client-check`, copy:

```bash
cp config/git-accounts.example.toml ~/.config/ai-playbook/git-accounts.toml
```

Edit labels, `gh_user`, and `ssh_hosts`. The check script uses this to recommend an account from `git remote get-url origin`. Without it, only `gh auth status` account list is shown.

---

## Checklist for a new client repo

1. Confirm SSH host alias exists for the repo org (or add one).
2. Confirm `url.insteadOf` rewrite if using canonical `github.com` URLs.
3. Confirm `includeIf` covers the repo path (commit identity).
4. Run `configure-client-project` (or skill) → pick **gh account** → writes `.envrc`.
5. `direnv allow` in the client repo.
6. Sanity check: `gh repo view <org>/<repo>` from client root.

---

## bitoron reference (worked example)

- **Org:** `bitoron-tech` — personal account `k-m-r-dev`
- **Remote host:** `bitoron-tech.github.com`
- **`.envrc`:** `GH_TOKEN="$(gh auth token -u k-m-r-dev)"`
- **Work account `kmrfn`:** inactive in this workspace; used under `fn.github.com` elsewhere
- **AGENTS.md** records: use `.envrc`, not `.env`, for gh tokens

---

## Related playbook surfaces

- `scripts/configure-client-git-account.sh` — write/check `.envrc`
- `scripts/configure-client-check.sh` — reports `[OK|MISSING] gh account (.envrc)`
- `scripts/configure-client-project.sh` — `--gh-user` flag
- Skill **configure-client-project** — interview question for gh account on init / when missing
