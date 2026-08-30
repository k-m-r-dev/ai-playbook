#!/usr/bin/env bash
set -euo pipefail

# Install Ruflo→Cursor hook adapter into ~/.cursor/hooks and optionally patch a client.
# SoT: ai-playbook/config/cursor-hooks/

usage() {
  cat <<'EOF'
Usage:
  install-ruflo-cursor-hooks.sh \
    [--source-repo /path/to/ai-playbook] \
    [--client-repo /path/to/client] \
    [--global-only] \
    [--mode copy|symlink] \
    [--dry-run]
    [--help]

Default --source-repo: parent of scripts/ (this playbook).
Default --mode: copy (home hooks keep working if the playbook path moves).
symlink mode: ~/.cursor/hooks/*.cjs -> playbook config/cursor-hooks/*.cjs

Without --client-repo and without --global-only, runs the fixer with --global-only.
EOF
}

die() {
  echo "error: $*" >&2
  exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
CLIENT_REPO=""
GLOBAL_ONLY=0
MODE="copy"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-repo)
      SOURCE_REPO="$(cd "${2:?}" && pwd)"
      shift 2
      ;;
    --client-repo)
      CLIENT_REPO="$(cd "${2:?}" && pwd)"
      shift 2
      ;;
    --global-only)
      GLOBAL_ONLY=1
      shift
      ;;
    --mode)
      MODE="${2:?}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1 (try --help)"
      ;;
  esac
done

[[ "$MODE" == "copy" || "$MODE" == "symlink" ]] || die "--mode must be copy or symlink"

SOT_DIR="$SOURCE_REPO/config/cursor-hooks"
ADAPTER_SRC="$SOT_DIR/ruflo-cursor-adapter.cjs"
FIXER_SRC="$SOT_DIR/fix-ruflo-cursor-hooks.cjs"
[[ -f "$ADAPTER_SRC" ]] || die "missing SoT file: $ADAPTER_SRC"
[[ -f "$FIXER_SRC" ]] || die "missing SoT file: $FIXER_SRC"

HOOKS_DIR="${HOME}/.cursor/hooks"
ADAPTER_DST="$HOOKS_DIR/ruflo-cursor-adapter.cjs"
FIXER_DST="$HOOKS_DIR/fix-ruflo-cursor-hooks.cjs"
WRAPPER="${HOME}/.local/bin/fix-ruflo-cursor-hooks"

echo "==> Ensuring $HOOKS_DIR"
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "dry-run: mkdir -p $HOOKS_DIR"
else
  mkdir -p "$HOOKS_DIR"
fi

install_one() {
  local src="$1" dst="$2"
  if [[ "$MODE" == "symlink" ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "dry-run: ln -sfn $src $dst"
    else
      ln -sfn "$src" "$dst"
    fi
  else
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "dry-run: cp -f $src $dst"
    else
      cp -f "$src" "$dst"
    fi
  fi
}

echo "==> Installing adapter + fixer ($MODE) into $HOOKS_DIR"
install_one "$ADAPTER_SRC" "$ADAPTER_DST"
install_one "$FIXER_SRC" "$FIXER_DST"

echo "==> Installing $WRAPPER"
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "dry-run: mkdir -p $(dirname "$WRAPPER")"
  echo "dry-run: write wrapper -> $WRAPPER"
else
  mkdir -p "$(dirname "$WRAPPER")"
  cat >"$WRAPPER" <<'WRAP'
#!/bin/sh
exec node "$HOME/.cursor/hooks/fix-ruflo-cursor-hooks.cjs" "$@"
WRAP
  chmod +x "$WRAPPER"
fi

FIXER_ARGS=()
if [[ "$DRY_RUN" -eq 1 ]]; then
  FIXER_ARGS+=(--dry-run)
fi
if [[ "$GLOBAL_ONLY" -eq 1 ]]; then
  FIXER_ARGS+=(--global-only)
elif [[ -n "$CLIENT_REPO" ]]; then
  FIXER_ARGS+=("$CLIENT_REPO")
else
  FIXER_ARGS+=(--global-only)
fi

echo "==> Running fixer: node $FIXER_DST ${FIXER_ARGS[*]:-}"
if [[ "$DRY_RUN" -eq 1 ]]; then
  if [[ -f "$FIXER_DST" ]]; then
    node "$FIXER_DST" "${FIXER_ARGS[@]}"
  else
    node "$FIXER_SRC" "${FIXER_ARGS[@]}"
  fi
else
  node "$FIXER_DST" "${FIXER_ARGS[@]}"
fi

cat <<EOF

Next steps:
  - Reload Cursor (or restart) if hooks were already loaded.
  - Per client after ruflo init: fix-ruflo-cursor-hooks /path/to/client
    or: bash scripts/repair-after-ruflo.sh --source-repo $SOURCE_REPO --client-repo /path/to/client
EOF
