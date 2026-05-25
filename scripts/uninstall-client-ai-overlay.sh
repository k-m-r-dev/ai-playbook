#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  uninstall-client-ai-overlay.sh \
    --client-repo /path/to/client-repo \
    --platform ios|android|flutter-riverpod|flutter-bloc \
    [--name ai-playbook]

Behavior:
  - Removes only files previously installed by the matching installer.
  - Removes the managed block from .git/info/exclude.
  - Leaves unrelated client files untouched.
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

remove_block() {
  local file="$1"
  local begin="$2"
  local end="$3"
  local temp_file
  temp_file="$(mktemp)"
  awk -v begin="$begin" -v end="$end" '
    $0 == begin { skip = 1; next }
    $0 == end { skip = 0; next }
    skip != 1 { print }
  ' "$file" > "$temp_file"
  mv "$temp_file" "$file"
}

prune_empty_parents() {
  local path="$1"
  local stop_at="$2"
  local current
  current="$(dirname "$path")"

  while [[ "$current" != "$stop_at" && "$current" == "$stop_at"/* ]]; do
    rmdir "$current" 2>/dev/null || break
    current="$(dirname "$current")"
  done
}

NAME="ai-playbook"
CLIENT_REPO=""
PLATFORM=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --client-repo)
      CLIENT_REPO="$2"
      shift 2
      ;;
    --platform)
      PLATFORM="$2"
      shift 2
      ;;
    --name)
      NAME="$2"
      shift 2
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

[[ -n "$CLIENT_REPO" ]] || die "--client-repo is required"
[[ "$PLATFORM" == "ios" || "$PLATFORM" == "android" || "$PLATFORM" == "flutter-riverpod" || "$PLATFORM" == "flutter-bloc" ]] || die "--platform must be ios, android, flutter-riverpod, or flutter-bloc"
[[ -d "$CLIENT_REPO" ]] || die "Client repository does not exist: $CLIENT_REPO"

CLIENT_REPO="$(real_dir "$CLIENT_REPO")"

GIT_DIR_RAW="$(git -C "$CLIENT_REPO" rev-parse --git-dir 2>/dev/null)" || die "Client path is not a Git repository: $CLIENT_REPO"
if [[ "$GIT_DIR_RAW" = /* ]]; then
  GIT_DIR="$GIT_DIR_RAW"
else
  GIT_DIR="$(real_dir "$CLIENT_REPO/$GIT_DIR_RAW")"
fi

STATE_DIR="$GIT_DIR/${NAME}"
MANIFEST_PATH="$STATE_DIR/${PLATFORM}.manifest.tsv"
EXCLUDE_FILE="$GIT_DIR/info/exclude"
BLOCK_BEGIN="# BEGIN ${NAME}:${PLATFORM}"
BLOCK_END="# END ${NAME}:${PLATFORM}"

[[ -f "$MANIFEST_PATH" ]] || die "No installed overlay found for '$PLATFORM' in this client repo."

while IFS=$'\t' read -r dest_path mode source_path; do
  [[ -n "$dest_path" ]] || continue

  if [[ "$mode" == "retain" ]]; then
    continue
  fi

  if [[ -L "$dest_path" ]]; then
    if [[ "$(readlink "$dest_path")" == "$source_path" ]]; then
      rm "$dest_path"
    fi
  elif [[ -e "$dest_path" ]]; then
    rm -rf "$dest_path"
  fi

  prune_empty_parents "$dest_path" "$CLIENT_REPO"
done < "$MANIFEST_PATH"

if [[ -f "$EXCLUDE_FILE" ]]; then
  remove_block "$EXCLUDE_FILE" "$BLOCK_BEGIN" "$BLOCK_END"
fi

rm -f "$MANIFEST_PATH"
rmdir "$STATE_DIR" 2>/dev/null || true

printf 'Removed %s overlay from %s\n' "$PLATFORM" "$CLIENT_REPO"