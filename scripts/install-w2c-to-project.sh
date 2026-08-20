#!/usr/bin/env bash
# Install W2C skills + CLI into a client repo (Copilot instructions + .w2c ledger helpers).
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  install-w2c-to-project.sh --repo PATH [--source-repo PATH] [--mode symlink|copy] [--dry-run] [--force]

Installs:
  .github/instructions/work-to-chores.instructions.md
  .github/instructions/do-chores.instructions.md
  .w2c/scripts/ -> shared/w2c/scripts (default symlink mode)
  .w2c/templates/ -> shared/w2c/templates (default symlink mode)
  .gitignore entries for .w2c/scripts/, .w2c/templates/, and .w2c/runtime/

Copy mode copies .w2c/scripts/ and .w2c/templates/ into the client repo.
Existing real directories at .w2c/scripts or .w2c/templates require --force.
Does not overwrite existing DECISIONS.md or STATE.md.
Runs w2c init when STATE.md is missing.

Cursor/Claude skills still come from:
  bash scripts/install-personal-agents-hub.sh --force --skills work-to-chores,do-chores
EOF
}

die() { printf 'Error: %s\n' "$1" >&2; exit 1; }
info() { printf '[w2c-install] %s\n' "$1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYBOOK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO=""
MODE="symlink"
DRY_RUN=0
FORCE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="$2"; shift 2 ;;
    --source-repo) PLAYBOOK_ROOT="$(cd "$2" && pwd)"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --force) FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown argument: $1" ;;
  esac
done

[[ -n "$REPO" ]] || die "--repo is required"
REPO="$(cd "$REPO" && pwd)"
case "$MODE" in
  symlink|copy) ;;
  *) die "--mode must be symlink or copy" ;;
esac

W2C_ROOT="$PLAYBOOK_ROOT/shared/w2c"
[[ -d "$W2C_ROOT" ]] || die "shared/w2c not found in $PLAYBOOK_ROOT"
[[ -d "$W2C_ROOT/scripts" ]] || die "missing $W2C_ROOT/scripts"
[[ -d "$W2C_ROOT/templates" ]] || die "missing $W2C_ROOT/templates"

write_copilot() {
  local name="$1"
  local src_dir="$W2C_ROOT/skills/$name"
  local wrapper="$src_dir/SKILL.copilot.md"
  local body="$src_dir/SKILL.md"
  local dest="$REPO/.github/instructions/${name}.instructions.md"
  [[ -f "$body" ]] || die "missing $body"
  if [[ "$DRY_RUN" == 1 ]]; then
    info "WRITE $dest"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  if [[ -f "$wrapper" ]]; then
    cat "$wrapper" > "$dest"
    printf '\n' >> "$dest"
    cat "$body" >> "$dest"
  else
    printf -- '---\napplyTo: "**"\n---\n\n' > "$dest"
    cat "$body" >> "$dest"
  fi
  info "wrote $dest"
}

install_dir() {
  local name="$1"
  local src="$W2C_ROOT/$name"
  local dest="$REPO/.w2c/$name"

  if [[ "$DRY_RUN" == 1 ]]; then
    info "INSTALL $name ($MODE) -> $dest"
    return
  fi

  mkdir -p "$REPO/.w2c"

  if [[ -d "$dest" && ! -L "$dest" && "$FORCE" != 1 ]]; then
    die "$dest already exists as a real directory; use --force to replace it"
  fi
  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ "$FORCE" == 1 || -L "$dest" ]]; then
      rm -rf "$dest"
    else
      die "$dest already exists; use --force to replace it"
    fi
  fi

  case "$MODE" in
    symlink)
      ln -s "$src" "$dest"
      info "symlinked .w2c/$name"
      ;;
    copy)
      cp -R "$src" "$dest"
      if [[ "$name" == "scripts" ]]; then
        chmod +x "$dest/w2c.sh" "$dest/w2c-smoke.sh" "$dest/w2c.py" "$dest/w2c-smoke.py"
      fi
      info "copied .w2c/$name"
      ;;
  esac
}

ensure_gitignore() {
  local gi="$REPO/.gitignore"
  local markers=(".w2c/scripts/" ".w2c/templates/" ".w2c/runtime/")
  if [[ "$DRY_RUN" == 1 ]]; then
    info "ensure w2c entries in .gitignore"
    return
  fi

  local marker missing=()
  for marker in "${markers[@]}"; do
    if [[ -f "$gi" ]] && grep -Fqx "$marker" "$gi"; then
      continue
    fi
    missing+=("$marker")
  done
  [[ "${#missing[@]}" -gt 0 ]] || return

  {
    [[ -f "$gi" && -s "$gi" && "$(tail -c1 "$gi" 2>/dev/null || true)" != $'\n' ]] && printf '\n'
    printf '\n# w2c generated and playbook-linked files\n'
    printf '%s\n' "${missing[@]}"
  } >> "$gi"
  info "appended w2c entries to .gitignore"
}

init_ledger() {
  if [[ "$DRY_RUN" == 1 ]]; then
    info "w2c init"
    return
  fi

  mkdir -p "$REPO/.w2c"
  if [[ -f "$REPO/.w2c/STATE.md" ]]; then
    if [[ ! -f "$REPO/.w2c/DECISIONS.md" ]]; then
      cp "$W2C_ROOT/templates/DECISIONS.md" "$REPO/.w2c/DECISIONS.md"
      info "wrote missing DECISIONS.md"
    else
      info "leaving existing STATE.md / DECISIONS.md"
    fi
    return
  fi

  python3 "$REPO/.w2c/scripts/w2c.py" --root "$REPO" init
}

write_copilot work-to-chores
write_copilot do-chores
install_dir scripts
install_dir templates
ensure_gitignore
init_ledger
info "done ($REPO)"
