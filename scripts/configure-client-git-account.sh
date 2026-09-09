#!/usr/bin/env bash
# Write or verify per-repo direnv GH_TOKEN for gh CLI account selection (multi-account GitHub).
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  configure-client-git-account.sh \
    --client-repo PATH \
    [--gh-user USERNAME] \
    [--check] [--dry-run] [--force]

Writes GH_TOKEN from gh keychain (no secret stored):
  - Greenfield (no .envrc): writes playbook block into .envrc
  - Existing .envrc (client direnv): writes block into .envrc.local and
    ensures .envrc has source_env_if_exists .envrc.local
  - --force: replace .envrc contents with the playbook block only
    (destructive — prefer .envrc.local when .envrc already exists)

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
GH_TOKEN_RE='GH_TOKEN=.*gh auth token'
SOURCE_LOCAL_RE='source_env(_if_exists)?[[:space:]]+\.envrc\.local'

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

file_has_gh_token() {
  local f="$1"
  [[ -f "$f" ]] || return 1
  grep -qE "$GH_TOKEN_RE" "$f" 2>/dev/null
}

envrc_sources_local() {
  local envrc="$CLIENT_REPO/.envrc"
  [[ -f "$envrc" ]] || return 1
  grep -qE "$SOURCE_LOCAL_RE" "$envrc" 2>/dev/null
}

# Where GH_TOKEN is (or will be) declared for check messaging.
gh_token_file() {
  if [[ -f "$CLIENT_REPO/.envrc" ]] && file_has_gh_token "$CLIENT_REPO/.envrc"; then
    printf '%s' "$CLIENT_REPO/.envrc"
    return 0
  fi
  if envrc_sources_local && file_has_gh_token "$CLIENT_REPO/.envrc.local"; then
    printf '%s' "$CLIENT_REPO/.envrc.local"
    return 0
  fi
  return 1
}

envrc_configured() {
  gh_token_file >/dev/null
}

envrc_gh_user() {
  local f user=""
  f="$(gh_token_file)" || return 1
  user="$(sed -n 's/.*gh auth token -u \([^)]*\).*/\1/p' "$f" | head -1)"
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

ensure_envrc_sources_local() {
  local envrc="$CLIENT_REPO/.envrc"
  if [[ ! -f "$envrc" ]]; then
    printf 'source_env_if_exists .envrc.local\n' > "$envrc"
    return 0
  fi
  if ! grep -qE "$SOURCE_LOCAL_RE" "$envrc"; then
    printf '\nsource_env_if_exists .envrc.local\n' >> "$envrc"
  fi
}

# Write/replace the marked playbook block in $1; preserve other lines.
write_marked_block() {
  local target="$1" user="$2" tmp
  tmp="$(mktemp)"
  if [[ -f "$target" ]] && grep -qF "$BEGIN_MARKER" "$target"; then
    awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" '
      $0 == begin { skip=1; next }
      $0 == end { skip=0; next }
      skip != 1 { print }
    ' "$target" > "$tmp"
    # Drop bare legacy GH_TOKEN lines outside the markers (upgrade path).
    grep -vE "^[[:space:]]*export[[:space:]]+$GH_TOKEN_RE" "$tmp" > "${tmp}.2" || true
    mv "${tmp}.2" "$tmp"
    render_envrc "$user" >> "$tmp"
    mv "$tmp" "$target"
  elif [[ -f "$target" ]]; then
    # Keep non-token lines; drop bare GH_TOKEN exports; append marked block.
    grep -vE "^[[:space:]]*export[[:space:]]+$GH_TOKEN_RE" "$target" > "$tmp" || true
    # Avoid trailing blank spam: ensure single newline before block when file had content.
    if [[ -s "$tmp" ]] && [[ -n "$(tr -d '[:space:]' < "$tmp")" ]]; then
      printf '\n' >> "$tmp"
    fi
    render_envrc "$user" >> "$tmp"
    mv "$tmp" "$target"
  else
    render_envrc "$user" > "$target"
    rm -f "$tmp"
  fi
}

# Prefer .envrc.local when a client-owned .envrc already exists (unless --force).
prefer_envrc_local() {
  [[ "$FORCE" == 1 ]] && return 1
  [[ -f "$CLIENT_REPO/.envrc" ]] || return 1
  # Already on local pattern, or .envrc has no playbook marker (client direnv).
  envrc_sources_local && return 0
  ! grep -qF "$BEGIN_MARKER" "$CLIENT_REPO/.envrc" 2>/dev/null
}

write_envrc() {
  local user="$1" dest
  if prefer_envrc_local; then
    ensure_envrc_sources_local
    dest="$CLIENT_REPO/.envrc.local"
    write_marked_block "$dest" "$user"
    info "wrote $dest for gh user $user (sourced from .envrc)"
  else
    dest="$CLIENT_REPO/.envrc"
    write_marked_block "$dest" "$user"
    info "wrote $dest for gh user $user"
  fi
}

# ── Check mode ───────────────────────────────────────────────────────────────
if [[ "$CHECK" == 1 || ( -z "$GH_USER" && "$DRY_RUN" != 1 ) ]]; then
  if envrc_configured; then
    user="$(envrc_gh_user || true)"
    loc="$(gh_token_file)"
    loc_base="$(basename "$loc")"
    status "OK" "gh account ($loc_base${user:+ user=$user})"
  elif [[ -f "$CLIENT_REPO/.envrc.local" ]] && file_has_gh_token "$CLIENT_REPO/.envrc.local" && ! envrc_sources_local; then
    status "MISSING" "gh account (.envrc.local has GH_TOKEN but .envrc does not source_env_if_exists .envrc.local)"
  elif [[ -f "$CLIENT_REPO/.envrc" ]]; then
    status "MISSING" "gh account (.envrc present but no playbook GH_TOKEN in .envrc or sourced .envrc.local)"
  else
    status "MISSING" "gh account (.envrc / .envrc.local — direnv GH_TOKEN for gh CLI)"
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

if [[ "$DRY_RUN" == 1 ]]; then
  if prefer_envrc_local; then
    info "dry-run would write .envrc.local for gh user $GH_USER (and ensure .envrc sources it)"
  else
    info "dry-run would write .envrc for gh user $GH_USER"
  fi
  render_envrc "$GH_USER"
  exit 0
fi

write_envrc "$GH_USER"
info "run: cd $CLIENT_REPO && direnv allow"
info "tip: gitignore .envrc.local when it holds machine-local account wiring"
