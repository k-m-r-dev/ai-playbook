#!/usr/bin/env bash
# Install W2C skills + CLI into a client repo (Copilot instructions + .w2c/scripts).
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  install-w2c-to-project.sh --repo PATH [--source-repo PATH] [--dry-run]

Copies:
  .github/instructions/work-to-chores.instructions.md
  .github/instructions/do-chores.instructions.md
  .w2c/scripts/ (w2c.py, w2c.sh, w2c-smoke.py, w2c-smoke.sh)
  .gitignore entry for .w2c/runtime/

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
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="$2"; shift 2 ;;
    --source-repo) PLAYBOOK_ROOT="$(cd "$2" && pwd)"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown argument: $1" ;;
  esac
done

[[ -n "$REPO" ]] || die "--repo is required"
REPO="$(cd "$REPO" && pwd)"
W2C_ROOT="$PLAYBOOK_ROOT/shared/w2c"
[[ -d "$W2C_ROOT" ]] || die "shared/w2c not found in $PLAYBOOK_ROOT"

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

copy_scripts() {
  local dest="$REPO/.w2c/scripts"
  if [[ "$DRY_RUN" == 1 ]]; then
    info "COPY scripts -> $dest"
    return
  fi
  mkdir -p "$dest"
  cp "$W2C_ROOT/scripts/w2c.py" "$dest/"
  cp "$W2C_ROOT/scripts/w2c.sh" "$dest/"
  cp "$W2C_ROOT/scripts/w2c-smoke.py" "$dest/"
  cp "$W2C_ROOT/scripts/w2c-smoke.sh" "$dest/"
  chmod +x "$dest/w2c.sh" "$dest/w2c-smoke.sh" "$dest/w2c.py" "$dest/w2c-smoke.py"
  info "copied .w2c/scripts"
}

ensure_gitignore() {
  local gi="$REPO/.gitignore"
  local marker=".w2c/runtime/"
  if [[ "$DRY_RUN" == 1 ]]; then
    info "ensure $marker in .gitignore"
    return
  fi
  if [[ -f "$gi" ]] && grep -Fqx "$marker" "$gi"; then
    return
  fi
  if [[ -f "$gi" ]] && grep -Fq "$marker" "$gi"; then
    return
  fi
  {
    [[ -f "$gi" && -s "$gi" && "$(tail -c1 "$gi" 2>/dev/null || true)" != $'\n' ]] && printf '\n'
    printf '\n# w2c runtime\n%s\n' "$marker"
  } >> "$gi"
  info "appended $marker to .gitignore"
}

init_ledger() {
  if [[ -f "$REPO/.w2c/STATE.md" || -f "$REPO/.w2c/DECISIONS.md" ]]; then
    info "leaving existing STATE.md / DECISIONS.md"
    return
  fi
  if [[ "$DRY_RUN" == 1 ]]; then
    info "w2c init"
    return
  fi
  python3 "$REPO/.w2c/scripts/w2c.py" --root "$REPO" init
}

write_copilot work-to-chores
write_copilot do-chores
copy_scripts
ensure_gitignore
init_ledger
info "done ($REPO)"
