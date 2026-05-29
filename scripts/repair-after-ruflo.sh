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
    [--name ai-playbook]

Restores hardened hook helpers after `ruflo init` (or similar) overwrites
the client's `.claude/helpers`. Always applies **symlink** mode so playbook
content stays in your private source repo (not copied into the client tree).

Requires an existing overlay install (see install-client-ai-overlay.sh).

Delegates to patch-hook-safety-overlay.sh --mode symlink.
EOF
}

die() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH_SCRIPT="$SCRIPT_DIR/patch-hook-safety-overlay.sh"
[[ -x "$PATCH_SCRIPT" ]] || [[ -f "$PATCH_SCRIPT" ]] || die "Missing patch script: $PATCH_SCRIPT"

SOURCE_REPO=""
CLIENT_REPO=""
PLATFORM=""
ALL_INSTALLED="false"
NAME=""
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

exec bash "$PATCH_SCRIPT" "${FORWARD[@]}" --mode symlink
