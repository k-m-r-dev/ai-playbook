#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  install-client-ai-overlay.sh \
    --source-repo /path/to/ai-playbook \
    --client-repo /path/to/client-repo \
    --platform universal|ios|android|flutter-riverpod|flutter-bloc \
    [--mode symlink|copy] \
    [--name ai-playbook]

Behavior:
  - Installs AI overlay files into a local client checkout only.
  - Stores install state under the client repository's .git directory.
  - Adds managed paths to .git/info/exclude.
  - Appends managed blocks to the client .gitignore (runtime artifacts + overlay paths).
  - Refuses to overwrite existing unmanaged files or directories.

Notes:
  - The source repository must store playbooks under <repo>/<platform>.
  - Use **--platform universal** for backend, frontend, desktop, infra, or generic repos.
  - Use ios|android|flutter-* for native/mobile-specific playbooks.
  - Default mode is symlink for playbook templates (`_*` root files).
  - Committed wrappers (`AGENTS.md`, `CLAUDE.md`, `ARCHITECTURE.md`, `SESSION_WORKFLOW.md`) are always **copy** mode.
  - `.workflow/` is always installed with **copy** mode so session logs stay project-owned.
  - universal also installs `.github/copilot-instructions.md` (skipped if absent on other platforms).
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/overlay-wrappers.sh
source "$SCRIPT_DIR/lib/overlay-wrappers.sh"

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

# `.workflow/` is always copied and is project-owned session state. Keep an
# existing directory when reinstalling after a partial uninstall.
is_retained_project_workflow() {
  local dest_rel="$1"
  local dest_path="$2"
  [[ "$dest_rel" == ".workflow" ]] && [[ -d "$dest_path" ]]
}

NAME="ai-playbook"
MODE="symlink"
SOURCE_REPO=""
CLIENT_REPO=""
PLATFORM=""
REQUIRE_GSD=1

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
    --no-require-gsd)
      REQUIRE_GSD=0
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
[[ -n "$CLIENT_REPO" ]] || die "--client-repo is required"
[[ "$PLATFORM" == "universal" || "$PLATFORM" == "ios" || "$PLATFORM" == "android" || "$PLATFORM" == "flutter-riverpod" || "$PLATFORM" == "flutter-bloc" ]] || die "--platform must be universal, ios, android, flutter-riverpod, or flutter-bloc"
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
  "_AGENTS.md|_AGENTS.md"
  "AGENTS.md|AGENTS.md"
  "_CLAUDE.md|_CLAUDE.md"
  "CLAUDE.md|CLAUDE.md"
  "_ARCHITECTURE.md|_ARCHITECTURE.md"
  "ARCHITECTURE.md|ARCHITECTURE.md"
  "_SESSION_WORKFLOW.md|_SESSION_WORKFLOW.md"
  "SESSION_WORKFLOW.md|SESSION_WORKFLOW.md"
  "skills-lock.json|skills-lock.json"
  ".claude/helpers|.claude/helpers"
  ".claude/skills|.claude/skills"
  ".cursor/rules|.cursor/rules"
  ".cursor/skills|.cursor/skills"
  ".cursor/agents|.cursor/agents"
  ".claude/agents|.claude/agents"
  ".github/agents|.github/agents"
  ".github/instructions|.github/instructions"
  ".github/copilot-instructions.md|.github/copilot-instructions.md"
  ".workflow|.workflow"
)

effective_install_mode() {
  overlay_effective_install_mode "$1" "$MODE"
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
    if is_retained_project_workflow "$dest_rel" "$dest_path"; then
      continue
    fi
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

  if is_retained_project_workflow "$dest_rel" "$dest_path"; then
    printf '%s\tretain\t%s\n' "$dest_path" "$source_path" >> "$MANIFEST_PATH"
    continue
  fi

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
remove_block "$EXCLUDE_FILE" "$BLOCK_BEGIN" "$BLOCK_END"
{
  exclude_entries=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && exclude_entries+=("$line")
  done < <(overlay_gitignore_info_exclude_template_entries)
  append_block "$EXCLUDE_FILE" "$BLOCK_BEGIN" "$BLOCK_END" "${exclude_entries[@]}"
}

# shellcheck source=lib/overlay-gitignore.sh
source "$SCRIPT_DIR/lib/overlay-gitignore.sh"

overlay_gitignore_apply_artifacts "$CLIENT_REPO" "$NAME" "$SOURCE_REPO" \
  || die "Missing config/client-ai-gitignore-artifacts.txt in source repo"
overlay_gitignore_apply_platform "$CLIENT_REPO" "$NAME" "$PLATFORM"

printf 'Installed %s overlay into %s using %s mode.\n' "$PLATFORM" "$CLIENT_REPO" "$MODE"
printf 'Managed state stored at %s\n' "$MANIFEST_PATH"
printf 'Updated %s/.gitignore (local-artifacts + overlay:%s blocks)\n' "$CLIENT_REPO" "$PLATFORM"

if [[ "$REQUIRE_GSD" == 1 && ! -d "$CLIENT_REPO/.gsd" ]]; then
  printf '\n[WARN] .gsd/ not found in %s\n' "$CLIENT_REPO" >&2
  printf '       GSD skills (gsd-plan-milestone, gsd-advance-unit, do-next, do-next-runner)\n' >&2
  printf '       will NOT work until you bootstrap GSD:\n\n' >&2
  printf '       bootstrap-gsd-workflow.sh \\\n' >&2
  printf '         --source-repo %s \\\n' "$SOURCE_REPO" >&2
  printf '         --client-repo %s \\\n' "$CLIENT_REPO" >&2
  printf '         --init-gsd --patch-mcp --with-do-next\n\n' >&2
fi