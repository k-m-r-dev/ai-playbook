#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  patch-client-ai-gitignore.sh \
    --source-repo /path/to/ai-playbook \
    --client-repo /path/to/client-repo \
    [--platform universal|ios|android|flutter-riverpod|flutter-bloc] \
    [--all-installed] \
    [--name ai-playbook]

Adds or refreshes managed .gitignore blocks on an already-installed client overlay:
  - local AI runtime artifacts (graphify-out/, memory DBs, .claude-flow/, etc.)
  - overlay paths for each installed platform (AGENTS.md, .claude/helpers, …)

Requires existing manifest(s) from install-client-ai-overlay.sh.
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/overlay-gitignore.sh
source "$SCRIPT_DIR/lib/overlay-gitignore.sh"

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

append_block() {
  local file="$1"
  local begin="$2"
  local end="$3"
  shift 3

  {
    printf '%s\n' "$begin"
    for entry in "$@"; do
      printf '%s\n' "$entry"
    done
    printf '%s\n' "$end"
  } >> "$file"
}

NAME="ai-playbook"
SOURCE_REPO=""
CLIENT_REPO=""
PLATFORM=""
ALL_INSTALLED="false"
VALID_PLATFORMS=(universal ios android flutter-riverpod flutter-bloc)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-repo)
      SOURCE_REPO="$2"
      shift 2
      ;;
    --client-repo)
      CLIENT_REPO="$2"
      shift 2
      ;;
    --platform)
      PLATFORM="$2"
      shift 2
      ;;
    --all-installed)
      ALL_INSTALLED="true"
      shift 1
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

[[ -n "$SOURCE_REPO" ]] || die "--source-repo is required"
[[ -n "$CLIENT_REPO" ]] || die "--client-repo is required"
if [[ "$ALL_INSTALLED" == "false" ]]; then
  [[ -n "$PLATFORM" ]] || die "Pass --platform or use --all-installed"
fi

SOURCE_REPO="$(real_dir "$SOURCE_REPO")"
CLIENT_REPO="$(real_dir "$CLIENT_REPO")"

GIT_DIR_RAW="$(git -C "$CLIENT_REPO" rev-parse --git-dir 2>/dev/null)" || die "Client path is not a Git repository: $CLIENT_REPO"
if [[ "$GIT_DIR_RAW" = /* ]]; then
  GIT_DIR="$GIT_DIR_RAW"
else
  GIT_DIR="$(real_dir "$CLIENT_REPO/$GIT_DIR_RAW")"
fi

STATE_DIR="$GIT_DIR/${NAME}"

overlay_gitignore_apply_artifacts "$CLIENT_REPO" "$NAME" "$SOURCE_REPO" \
  || die "Missing $(overlay_gitignore_artifacts_file "$SOURCE_REPO")"

resolve_platforms() {
  if [[ -n "$PLATFORM" ]]; then
    printf '%s\n' "$PLATFORM"
    return
  fi
  [[ -d "$STATE_DIR" ]] || die "No overlay state dir at $STATE_DIR"
  local found="false"
  for p in "${VALID_PLATFORMS[@]}"; do
    if [[ -f "$STATE_DIR/${p}.manifest.tsv" ]]; then
      printf '%s\n' "$p"
      found="true"
    fi
  done
  [[ "$found" == "true" ]] || die "No installed platform manifests found in $STATE_DIR"
}

while IFS= read -r platform; do
  [[ -f "$STATE_DIR/${platform}.manifest.tsv" ]] \
    || die "No overlay manifest for '$platform' — install overlay first."
  overlay_gitignore_apply_platform "$CLIENT_REPO" "$NAME" "$platform"
  printf 'Updated .gitignore overlay block for platform %s\n' "$platform"
done < <(resolve_platforms)

printf 'Updated .gitignore local-artifacts block in %s\n' "$CLIENT_REPO"
