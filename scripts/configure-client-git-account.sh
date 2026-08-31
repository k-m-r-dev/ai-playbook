#!/usr/bin/env bash
# Write or verify per-repo .envrc for gh CLI account selection (multi-account GitHub).
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  configure-client-git-account.sh \
    --client-repo PATH \
    [--gh-user USERNAME] \
    [--check] [--dry-run] [--force]

Writes .envrc with GH_TOKEN from gh keychain (no secret stored).
Without --gh-user: --check only (or dry-run prints would-write).

Requires: gh CLI logged in for the chosen user.
See docs/github-multi-account.md for full multi-account setup.
EOF
}

die() { printf 'Error: %s\n' "$1" >&2; exit 1; }
info() { printf '[git-account] %s\n' "$1"; }
status() { printf '[%s] %s\n' "$1" "$2"; }

CLIENT_REPO=""
GH_USER=""
CHECK=0
DRY_RUN=0
FORCE=0

BEGIN_MARKER='# BEGIN ai-playbook:gh-account'
END_MARKER='# END ai-playbook:gh-account'

while [[ $# -gt 0 ]]; do
  case "$1" in
    --client-repo) CLIENT_REPO="$2"; shift 2 ;;
    --gh-user) GH_USER="$2"; shift 2 ;;
    --check) CHECK=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --force) FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown arg: $1" ;;
  esac
done

[[ -n "$CLIENT_REPO" ]] || die "--client-repo required"
[[ -d "$CLIENT_REPO" ]] || die "client not found: $CLIENT_REPO"
CLIENT_REPO="$(cd "$CLIENT_REPO" && pwd)"

git_account_registry() {
  local registry="${AI_PLAYBOOK_GIT_ACCOUNTS:-$HOME/.config/ai-playbook/git-accounts.toml}"
  printf '%s' "$registry"
}

parse_remote_ssh_host() {
  local remote="$1" host=""
  if [[ "$remote" =~ ^git@([^:]+): ]]; then
    host="${BASH_REMATCH[1]}"
  elif [[ "$remote" =~ github\.com[:/]([^/]+)/ ]]; then
    host="github.com"
  fi
  printf '%s' "$host"
}

gh_user_for_ssh_host() {
  local host="$1" registry line gh_user=""
  registry="$(git_account_registry)"
  [[ -f "$registry" ]] || return 1
  while IFS= read -r line; do
    case "$line" in
      gh_user\ =\ *) gh_user="${line#gh_user = }"; gh_user="${gh_user//\"/}" ;;
      ssh_hosts\ =\ *)
        local hosts="${line#ssh_hosts = }"
        hosts="${hosts//[\[\]\"]/}"
        IFS=',' read -ra parts <<< "$hosts"
        for h in "${parts[@]}"; do
          h="${h// /}"
          if [[ "$h" == "$host" ]]; then
            [[ -n "$gh_user" ]] && printf '%s' "$gh_user" && return 0
          fi
        done
        ;;
    esac
  done < "$registry"
  return 1
}

list_gh_accounts() {
  if ! command -v gh >/dev/null 2>&1; then
    return 1
  fi
  gh auth status -h github.com 2>&1 | sed -n 's/.* account \([^ (]*\).*/\1/p' | sort -u
}

envrc_configured() {
  local envrc="$CLIENT_REPO/.envrc"
  [[ -f "$envrc" ]] || return 1
  grep -qF "$BEGIN_MARKER" "$envrc" 2>/dev/null || return 1
  grep -qF 'GH_TOKEN="$(gh auth token' "$envrc" 2>/dev/null || return 1
}

envrc_gh_user() {
  local envrc="$CLIENT_REPO/.envrc" user=""
  [[ -f "$envrc" ]] || return 1
  user="$(sed -n 's/.*gh auth token -u \([^)]*\).*/\1/p' "$envrc" | head -1)"
  [[ -n "$user" ]] || return 1
  printf '%s' "$user"
}

render_envrc() {
  local user="$1"
  cat <<EOF
$BEGIN_MARKER
# gh CLI account for this repo (no secret stored; token read from gh keychain).
export GH_TOKEN="\$(gh auth token -u $user)"
$END_MARKER
EOF
}

write_envrc() {
  local user="$1" envrc="$CLIENT_REPO/.envrc" tmp
  tmp="$(mktemp)"
  if [[ -f "$envrc" ]] && grep -qF "$BEGIN_MARKER" "$envrc"; then
    awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" '
      $0 == begin { skip=1; next }
      $0 == end { skip=0; next }
      skip != 1 { print }
    ' "$envrc" > "$tmp"
    render_envrc "$user" >> "$tmp"
    mv "$tmp" "$envrc"
  elif [[ -f "$envrc" && "$FORCE" != 1 ]]; then
    rm -f "$tmp"
    die ".envrc exists without playbook marker — use --force or edit manually"
  else
    render_envrc "$user" > "$envrc"
    rm -f "$tmp"
  fi
}

# ── Check mode ───────────────────────────────────────────────────────────────
if [[ "$CHECK" == 1 || ( -z "$GH_USER" && "$DRY_RUN" != 1 ) ]]; then
  if envrc_configured; then
    user="$(envrc_gh_user || true)"
    status "OK" "gh account (.envrc${user:+ user=$user})"
  elif [[ -f "$CLIENT_REPO/.envrc" ]]; then
    status "MISSING" "gh account (.envrc present but no playbook GH_TOKEN block)"
  else
    status "MISSING" "gh account (.envrc — direnv GH_TOKEN for gh CLI)"
  fi

  if command -v gh >/dev/null 2>&1; then
    accounts="$(list_gh_accounts || true)"
    if [[ -n "$accounts" ]]; then
      status "DISCOVER" "gh logged-in accounts: $(echo "$accounts" | tr '\n' ' ' | sed 's/ $//')"
    fi
  else
    status "DISCOVER" "gh CLI not on PATH"
  fi

  remote="$(git -C "$CLIENT_REPO" remote get-url origin 2>/dev/null || true)"
  if [[ -n "$remote" ]]; then
    host="$(parse_remote_ssh_host "$remote")"
    status "DISCOVER" "git remote origin: $remote"
    [[ -n "$host" && "$host" != "github.com" ]] && status "DISCOVER" "ssh host alias: $host"
    suggested="$(gh_user_for_ssh_host "$host" 2>/dev/null || true)"
    [[ -n "$suggested" ]] && status "DISCOVER" "suggested gh user: $suggested (git-accounts.toml)"
  fi
  exit 0
fi

# ── Write mode ───────────────────────────────────────────────────────────────
[[ -n "$GH_USER" ]] || die "--gh-user required unless --check"

if ! command -v gh >/dev/null 2>&1; then
  die "gh CLI not on PATH — install https://cli.github.com/"
fi

if ! gh auth token -u "$GH_USER" >/dev/null 2>&1; then
  die "gh is not logged in for user $GH_USER — run: gh auth login -h github.com"
fi

if [[ -f "$CLIENT_REPO/.envrc" ]] && ! grep -qF "$BEGIN_MARKER" "$CLIENT_REPO/.envrc" 2>/dev/null && [[ "$FORCE" != 1 ]]; then
  die ".envrc exists without playbook marker — use --force"
fi

if [[ "$DRY_RUN" == 1 ]]; then
  info "dry-run would write .envrc for gh user $GH_USER"
  render_envrc "$GH_USER"
  exit 0
fi

write_envrc "$GH_USER"
info "wrote $CLIENT_REPO/.envrc for gh user $GH_USER"
info "run: cd $CLIENT_REPO && direnv allow"
