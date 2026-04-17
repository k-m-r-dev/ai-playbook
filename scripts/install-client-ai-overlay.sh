#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  install-client-ai-overlay.sh \
    --source-repo /path/to/ai-playbook \
    --client-repo /path/to/client-repo \
    --platform ios|android|flutter-riverpod|flutter-bloc \
    [--mode symlink|copy] \
    [--name ai-playbook]

Behavior:
  - Installs AI overlay files into a local client checkout only.
  - Stores install state under the client repository's .git directory.
  - Adds managed paths to .git/info/exclude.
  - Refuses to overwrite existing unmanaged files or directories.

Notes:
  - The source repository must store playbooks under <repo>/<platform>.
  - Default mode is symlink.
  - `.workflow/` is always installed with **copy** mode so session logs stay project-owned.
    `SESSION_WORKFLOW.md` uses the same **--mode** as other root files (default **symlink**, like `AGENTS.md`).
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

ensure_parent_dir() {
  local target="$1"
  mkdir -p "$(dirname "$target")"
}

is_managed_symlink() {
  local target="$1"
  local source="$2"
  [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]
}

NAME="ai-playbook"
MODE="symlink"
SOURCE_REPO=""
CLIENT_REPO=""
PLATFORM=""

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
    --mode)
      MODE="$2"
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

[[ -n "$SOURCE_REPO" ]] || die "--source-repo is required"
[[ -n "$CLIENT_REPO" ]] || die "--client-repo is required"
[[ "$PLATFORM" == "ios" || "$PLATFORM" == "android" || "$PLATFORM" == "flutter-riverpod" || "$PLATFORM" == "flutter-bloc" ]] || die "--platform must be ios, android, flutter-riverpod, or flutter-bloc"
[[ "$MODE" == "symlink" || "$MODE" == "copy" ]] || die "--mode must be symlink or copy"

[[ -d "$SOURCE_REPO" ]] || die "Source repository does not exist: $SOURCE_REPO"
[[ -d "$CLIENT_REPO" ]] || die "Client repository does not exist: $CLIENT_REPO"

SOURCE_REPO="$(real_dir "$SOURCE_REPO")"
CLIENT_REPO="$(real_dir "$CLIENT_REPO")"

SOURCE_PLATFORM_DIR="$SOURCE_REPO/$PLATFORM"
[[ -d "$SOURCE_PLATFORM_DIR" ]] || die "Could not find source playbook directory: $SOURCE_PLATFORM_DIR"

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

[[ ! -e "$MANIFEST_PATH" ]] || die "An overlay for '$PLATFORM' is already installed for this client repo. Uninstall it first."

MAPPINGS=(
  "AGENTS.md|AGENTS.md"
  "CLAUDE.md|CLAUDE.md"
  "ARCHITECTURE.md|ARCHITECTURE.md"
  "skills-lock.json|skills-lock.json"
  ".claude/skills|.claude/skills"
  ".cursor/rules|.cursor/rules"
  ".github/agents|.github/agents"
  ".github/instructions|.github/instructions"
  ".workflow|.workflow"
  "SESSION_WORKFLOW.md|SESSION_WORKFLOW.md"
)

effective_install_mode() {
  local source_rel="$1"
  if [[ "$source_rel" == ".workflow" ]]; then
    printf '%s' "copy"
  else
    printf '%s' "$MODE"
  fi
}

for mapping in "${MAPPINGS[@]}"; do
  IFS='|' read -r source_rel dest_rel <<< "$mapping"
  source_path="$SOURCE_PLATFORM_DIR/$source_rel"
  dest_path="$CLIENT_REPO/$dest_rel"

  [[ -e "$source_path" ]] || continue

  if is_managed_symlink "$dest_path" "$source_path"; then
    continue
  fi

  if [[ -e "$dest_path" || -L "$dest_path" ]]; then
    die "Target already exists and is not managed by this installer: $dest_rel"
  fi
done

mkdir -p "$STATE_DIR"
touch "$MANIFEST_PATH"
touch "$EXCLUDE_FILE"

for mapping in "${MAPPINGS[@]}"; do
  IFS='|' read -r source_rel dest_rel <<< "$mapping"
  source_path="$SOURCE_PLATFORM_DIR/$source_rel"
  dest_path="$CLIENT_REPO/$dest_rel"

  [[ -e "$source_path" ]] || continue

  ensure_parent_dir "$dest_path"

  install_mode=""
  install_mode="$(effective_install_mode "$source_rel")"

  if [[ "$install_mode" == "symlink" ]]; then
    ln -s "$source_path" "$dest_path"
  else
    cp -R "$source_path" "$dest_path"
  fi

  printf '%s\t%s\t%s\n' "$dest_path" "$install_mode" "$source_path" >> "$MANIFEST_PATH"
done

remove_block "$EXCLUDE_FILE" "$BLOCK_BEGIN" "$BLOCK_END"
append_block \
  "$EXCLUDE_FILE" \
  "$BLOCK_BEGIN" \
  "$BLOCK_END" \
  "/AGENTS.md" \
  "/CLAUDE.md" \
  "/ARCHITECTURE.md" \
  "/skills-lock.json" \
  "/.claude/skills" \
  "/.cursor/rules" \
  "/.github/agents" \
  "/.github/instructions" \
  "/.workflow" \
  "/SESSION_WORKFLOW.md"

printf 'Installed %s overlay into %s using %s mode.\n' "$PLATFORM" "$CLIENT_REPO" "$MODE"
printf 'Managed state stored at %s\n' "$MANIFEST_PATH"