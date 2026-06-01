#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  migrate-overlay-wrappers.sh \
    --source-repo /path/to/ai-playbook \
    --client-repo /path/to/client-repo \
    --platform universal|ios|android|flutter-riverpod|flutter-bloc \
    [--name ai-playbook]

Migrates legacy overlay installs (symlinked AGENTS.md, CLAUDE.md, etc.) to the
wrapper model:
  - Playbook templates symlinked as _AGENTS.md, _CLAUDE.md, _ARCHITECTURE.md, _SESSION_WORKFLOW.md
  - Committed wrappers copied from platform templates when missing

Idempotent — safe to re-run.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/overlay-wrappers.sh
source "$SCRIPT_DIR/lib/overlay-wrappers.sh"
# shellcheck source=lib/overlay-gitignore.sh
source "$SCRIPT_DIR/lib/overlay-gitignore.sh"

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

extract_section() {
  local file="$1"
  local heading="$2"
  awk -v h="$heading" '
    $0 == h { capture = 1; print; next }
    capture && /^## / { exit }
    capture { print }
  ' "$file"
}

read_manifest_source() {
  local manifest="$1"
  local dest_rel="$2"
  awk -F'\t' -v dest="$dest_rel" '$1 ~ "/" dest "$" { print $3; exit }' "$manifest"
}

NAME="ai-playbook"
SOURCE_REPO=""
CLIENT_REPO=""
PLATFORM=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-repo) SOURCE_REPO="$2"; shift 2 ;;
    --client-repo) CLIENT_REPO="$2"; shift 2 ;;
    --platform) PLATFORM="$2"; shift 2 ;;
    --name) NAME="$2"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) die "Unknown argument: $1" ;;
  esac
done

[[ -n "$SOURCE_REPO" && -n "$CLIENT_REPO" ]] || die "--source-repo and --client-repo are required"
[[ "$PLATFORM" == "universal" || "$PLATFORM" == "ios" || "$PLATFORM" == "android" || "$PLATFORM" == "flutter-riverpod" || "$PLATFORM" == "flutter-bloc" ]] || die "invalid --platform"

SOURCE_REPO="$(real_dir "$SOURCE_REPO")"
CLIENT_REPO="$(real_dir "$CLIENT_REPO")"
SOURCE_PLATFORM_DIR="$SOURCE_REPO/$PLATFORM"
[[ -d "$SOURCE_PLATFORM_DIR" ]] || die "Missing platform dir: $SOURCE_PLATFORM_DIR"

GIT_DIR_RAW="$(git -C "$CLIENT_REPO" rev-parse --git-dir 2>/dev/null)" || die "Not a git repo: $CLIENT_REPO"
if [[ "$GIT_DIR_RAW" = /* ]]; then
  GIT_DIR="$GIT_DIR_RAW"
else
  GIT_DIR="$(real_dir "$CLIENT_REPO/$GIT_DIR_RAW")"
fi

MANIFEST_PATH="$GIT_DIR/${NAME}/${PLATFORM}.manifest.tsv"
[[ -f "$MANIFEST_PATH" ]] || die "No overlay manifest — install overlay first: $MANIFEST_PATH"

migrate_pair() {
  local legacy="$1"
  local template="$2"
  local wrapper="$3"

  local legacy_path="$CLIENT_REPO/$legacy"
  local template_path="$CLIENT_REPO/$template"
  local wrapper_path="$CLIENT_REPO/$wrapper"
  local source_template="$SOURCE_PLATFORM_DIR/$template"
  local source_wrapper="$SOURCE_PLATFORM_DIR/$wrapper"

  [[ -f "$source_template" ]] || die "Missing playbook template: $source_template"
  [[ -f "$source_wrapper" ]] || die "Missing playbook wrapper: $source_wrapper"

  if [[ -L "$legacy_path" && ! -e "$template_path" ]]; then
    ln -s "$source_template" "$template_path"
    printf '%s\t%s\t%s\n' "$template_path" "symlink" "$source_template" >> "$MANIFEST_PATH"
    rm "$legacy_path"
    printf 'Renamed symlink %s -> %s\n' "$legacy" "$template"
  elif [[ -L "$legacy_path" && -e "$template_path" ]]; then
    rm -f "$legacy_path"
    printf 'Removed legacy symlink %s (template already present)\n' "$legacy"
  fi

  if [[ ! -f "$wrapper_path" ]]; then
    cp "$source_wrapper" "$wrapper_path"
    printf '%s\tcopy\t%s\n' "$wrapper_path" "$source_wrapper" >> "$MANIFEST_PATH"
    printf 'Seeded wrapper %s\n' "$wrapper"
  fi
}

migrate_pair "AGENTS.md" "_AGENTS.md" "AGENTS.md"
migrate_pair "CLAUDE.md" "_CLAUDE.md" "CLAUDE.md"
migrate_pair "ARCHITECTURE.md" "_ARCHITECTURE.md" "ARCHITECTURE.md"
migrate_pair "SESSION_WORKFLOW.md" "_SESSION_WORKFLOW.md" "SESSION_WORKFLOW.md"

# Merge learned sections from legacy symlink content if wrapper is still empty
agents_wrapper="$CLIENT_REPO/AGENTS.md"
if [[ -f "$agents_wrapper" ]]; then
  legacy_source=""
  legacy_source="$(read_manifest_source "$MANIFEST_PATH" "AGENTS.md" || true)"
  if [[ -n "$legacy_source" && -f "$legacy_source" ]]; then
    prefs="$(extract_section "$legacy_source" "## Learned User Preferences" || true)"
    facts="$(extract_section "$legacy_source" "## Learned Workspace Facts" || true)"
    if [[ -n "$prefs" || -n "$facts" ]]; then
      tmp="$(mktemp)"
      {
        printf '@_AGENTS.md\n\n'
        if [[ -n "$prefs" ]]; then
          printf '%s\n' "$prefs"
          printf '\n'
        else
          printf '## Learned User Preferences\n\n'
        fi
        if [[ -n "$facts" ]]; then
          printf '%s\n' "$facts"
        else
          printf '## Learned Workspace Facts\n\n'
        fi
      } > "$tmp"
      if ! grep -q '^- ' "$agents_wrapper" 2>/dev/null; then
        mv "$tmp" "$agents_wrapper"
        printf 'Merged learned sections into %s\n' "$agents_wrapper"
      else
        rm -f "$tmp"
      fi
    fi
  fi
fi

EXCLUDE_FILE="$GIT_DIR/info/exclude"
BLOCK_BEGIN="# BEGIN ${NAME}:${PLATFORM}"
BLOCK_END="# END ${NAME}:${PLATFORM}"
remove_block "$EXCLUDE_FILE" "$BLOCK_BEGIN" "$BLOCK_END"
exclude_entries=()
while IFS= read -r line; do
  [[ -n "$line" ]] && exclude_entries+=("$line")
done < <(overlay_gitignore_info_exclude_template_entries)
append_block "$EXCLUDE_FILE" "$BLOCK_BEGIN" "$BLOCK_END" "${exclude_entries[@]}"

overlay_gitignore_apply_platform "$CLIENT_REPO" "$NAME" "$PLATFORM"

printf 'Migration complete for %s in %s\n' "$PLATFORM" "$CLIENT_REPO"
