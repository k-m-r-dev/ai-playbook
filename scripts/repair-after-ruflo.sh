#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  repair-after-ruflo.sh \
    --source-repo /path/to/ai-playbook \
    --client-repo /path/to/client-repo \
    [--platform universal|ios|android|flutter-riverpod|flutter-bloc] \
    [--all-installed] \
    [--name ai-playbook] \
    [--skip-cursor-hooks]

Restores hardened hook helpers after `ruflo init` (or similar) overwrites
the client's `.claude/helpers`. Always applies **symlink** mode so playbook
content stays in your private source repo (not copied into the client tree).

Also installs Cursor-safe Ruflo hooks from config/cursor-hooks/ into
~/.cursor/hooks and rewrites the client's .claude/settings.json to use the
adapter (unless --skip-cursor-hooks).

Requires an existing overlay install (see install-client-ai-overlay.sh).

Delegates helpers restore to patch-hook-safety-overlay.sh --mode symlink.
EOF
}

die() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH_SCRIPT="$SCRIPT_DIR/patch-hook-safety-overlay.sh"
INSTALL_CURSOR_HOOKS="$SCRIPT_DIR/install-ruflo-cursor-hooks.sh"
[[ -x "$PATCH_SCRIPT" ]] || [[ -f "$PATCH_SCRIPT" ]] || die "Missing patch script: $PATCH_SCRIPT"
[[ -f "$INSTALL_CURSOR_HOOKS" ]] || die "Missing install script: $INSTALL_CURSOR_HOOKS"

SOURCE_REPO=""
CLIENT_REPO=""
PLATFORM=""
ALL_INSTALLED="false"
NAME=""
SKIP_CURSOR_HOOKS="false"
FORWARD=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-repo)
      SOURCE_REPO="$2"
      FORWARD+=(--source-repo "$2")
      shift 2
      ;;
    --client-repo)
      CLIENT_REPO="$2"
      FORWARD+=(--client-repo "$2")
      shift 2
      ;;
    --platform)
      PLATFORM="$2"
      FORWARD+=(--platform "$2")
      shift 2
      ;;
    --all-installed)
      ALL_INSTALLED="true"
      FORWARD+=(--all-installed)
      shift 1
      ;;
    --name)
      NAME="$2"
      FORWARD+=(--name "$2")
      shift 2
      ;;
    --skip-cursor-hooks)
      SKIP_CURSOR_HOOKS="true"
      shift 1
      ;;
    --mode)
      die "repair-after-ruflo always uses --mode symlink (omit --mode)"
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

[[ -n "$SOURCE_REPO" ]] || die "--source-repo is required"
[[ -n "$CLIENT_REPO" ]] || die "--client-repo is required"

if [[ "$ALL_INSTALLED" == "false" && -z "$PLATFORM" ]]; then
  FORWARD+=(--all-installed)
fi

bash "$PATCH_SCRIPT" "${FORWARD[@]}" --mode symlink

if [[ "$SKIP_CURSOR_HOOKS" == "true" ]]; then
  printf 'Skipped Cursor Ruflo hooks install (--skip-cursor-hooks).\n'
else
  bash "$INSTALL_CURSOR_HOOKS" \
    --source-repo "$SOURCE_REPO" \
    --client-repo "$CLIENT_REPO"
fi

printf 'Repair complete: helpers restored'
if [[ "$SKIP_CURSOR_HOOKS" == "true" ]]; then
  printf ' (cursor hooks skipped)\n'
else
  printf ' + Cursor Ruflo hooks installed/patched\n'
fi
