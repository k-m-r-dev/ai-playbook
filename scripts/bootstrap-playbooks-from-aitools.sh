#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bootstrap-playbooks-from-aitools.sh \
    --source-repo /path/to/repo-containing-aitools \
    --dest-repo /path/to/ai-playbook \
    [--platform ios|android|all] \
    [--force]

Behavior:
  - Copies source content from aitools/<platform> into <dest-repo>/<platform>.
  - Refuses to overwrite a non-empty destination unless --force is provided.
  - Preserves dot-directories like .claude, .cursor, and .github.

Examples:
  bash scripts/bootstrap-playbooks-from-aitools.sh \
    --source-repo ~/workspace/fn_react_native \
    --dest-repo ~/private/ai-playbook \
    --platform all

  bash scripts/bootstrap-playbooks-from-aitools.sh \
    --source-repo ~/workspace/fn_react_native \
    --dest-repo ~/private/ai-playbook \
    --platform ios \
    --force
EOF
}

die() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

real_dir() {
  local path="$1"
  (cd "$path" && pwd)
}

dir_has_contents() {
  local path="$1"
  [[ -d "$path" ]] && [[ -n "$(find "$path" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]
}

copy_dir_contents() {
  local source_dir="$1"
  local dest_dir="$2"

  mkdir -p "$dest_dir"

  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "$source_dir/" "$dest_dir/"
  else
    find "$dest_dir" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
    cp -R "$source_dir/." "$dest_dir/"
  fi
}

SOURCE_REPO=""
DEST_REPO=""
PLATFORM="all"
FORCE="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-repo)
      SOURCE_REPO="$2"
      shift 2
      ;;
    --dest-repo)
      DEST_REPO="$2"
      shift 2
      ;;
    --platform)
      PLATFORM="$2"
      shift 2
      ;;
    --force)
      FORCE="true"
      shift
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
[[ -n "$DEST_REPO" ]] || die "--dest-repo is required"
[[ "$PLATFORM" == "ios" || "$PLATFORM" == "android" || "$PLATFORM" == "all" ]] || die "--platform must be ios, android, or all"

[[ -d "$SOURCE_REPO" ]] || die "Source repository does not exist: $SOURCE_REPO"
[[ -d "$DEST_REPO" ]] || die "Destination repository does not exist: $DEST_REPO"

SOURCE_REPO="$(real_dir "$SOURCE_REPO")"
DEST_REPO="$(real_dir "$DEST_REPO")"

PLATFORMS=()
if [[ "$PLATFORM" == "all" ]]; then
  PLATFORMS=(ios android)
else
  PLATFORMS=("$PLATFORM")
fi

for current_platform in "${PLATFORMS[@]}"; do
  source_dir="$SOURCE_REPO/aitools/$current_platform"
  dest_dir="$DEST_REPO/$current_platform"

  [[ -d "$source_dir" ]] || die "Missing source directory: $source_dir"

  if dir_has_contents "$dest_dir" && [[ "$FORCE" != "true" ]]; then
    die "Destination already contains files: $dest_dir. Re-run with --force to replace them."
  fi

  copy_dir_contents "$source_dir" "$dest_dir"
  printf 'Bootstrapped %s playbooks from %s to %s\n' "$current_platform" "$source_dir" "$dest_dir"
done