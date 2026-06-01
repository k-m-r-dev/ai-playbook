#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  add-session-workflow-to-overlay.sh \
    --source-repo /path/to/ai-playbook \
    --client-repo /path/to/client-repo \
    --platform universal|ios|android|flutter-riverpod|flutter-bloc \
    [--mode symlink|copy] \
    [--name ai-playbook]

Use when the client repo already has an overlay from install-client-ai-overlay.sh but
session workflow files were never created (legacy overlay).

Installs `_SESSION_WORKFLOW.md` (symlink) and `SESSION_WORKFLOW.md` (wrapper copy).
For full legacy migration, prefer `migrate-overlay-wrappers.sh`.

Requires an existing manifest at <git-dir>/<name>/<platform>.manifest.tsv
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

NAME="ai-playbook"
MODE="symlink"
SOURCE_REPO=""
CLIENT_REPO=""
PLATFORM=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-repo) SOURCE_REPO="$2"; shift 2 ;;
    --client-repo) CLIENT_REPO="$2"; shift 2 ;;
    --platform) PLATFORM="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --name) NAME="$2"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) die "Unknown argument: $1" ;;
  esac
done

[[ -n "$SOURCE_REPO" && -n "$CLIENT_REPO" ]] || die "--source-repo and --client-repo are required"
[[ "$PLATFORM" == "universal" || "$PLATFORM" == "ios" || "$PLATFORM" == "android" || "$PLATFORM" == "flutter-riverpod" || "$PLATFORM" == "flutter-bloc" ]] || die "invalid --platform"
[[ "$MODE" == "symlink" || "$MODE" == "copy" ]] || die "--mode must be symlink or copy"

SOURCE_REPO="$(real_dir "$SOURCE_REPO")"
CLIENT_REPO="$(real_dir "$CLIENT_REPO")"
SOURCE_PLATFORM_DIR="$SOURCE_REPO/$PLATFORM"

SOURCE_TEMPLATE="$SOURCE_PLATFORM_DIR/_SESSION_WORKFLOW.md"
SOURCE_WRAPPER="$SOURCE_PLATFORM_DIR/SESSION_WORKFLOW.md"
[[ -f "$SOURCE_TEMPLATE" ]] || die "Missing _SESSION_WORKFLOW.md in playbook: $SOURCE_TEMPLATE"
[[ -f "$SOURCE_WRAPPER" ]] || die "Missing SESSION_WORKFLOW.md wrapper in playbook: $SOURCE_WRAPPER"

GIT_DIR_RAW="$(git -C "$CLIENT_REPO" rev-parse --git-dir 2>/dev/null)" || die "Not a git repo: $CLIENT_REPO"
if [[ "$GIT_DIR_RAW" = /* ]]; then
  GIT_DIR="$GIT_DIR_RAW"
else
  GIT_DIR="$(real_dir "$CLIENT_REPO/$GIT_DIR_RAW")"
fi

MANIFEST_PATH="$GIT_DIR/${NAME}/${PLATFORM}.manifest.tsv"
EXCLUDE_FILE="$GIT_DIR/info/exclude"
BLOCK_BEGIN="# BEGIN ${NAME}:${PLATFORM}"
BLOCK_END="# END ${NAME}:${PLATFORM}"
[[ -f "$MANIFEST_PATH" ]] || die "No overlay manifest — install overlay first."

DEST_TEMPLATE="$CLIENT_REPO/_SESSION_WORKFLOW.md"
DEST_WRAPPER="$CLIENT_REPO/SESSION_WORKFLOW.md"

if [[ ! -e "$DEST_TEMPLATE" ]]; then
  ln -s "$SOURCE_TEMPLATE" "$DEST_TEMPLATE"
  printf '%s\tsymlink\t%s\n' "$DEST_TEMPLATE" "$SOURCE_TEMPLATE" >> "$MANIFEST_PATH"
  printf 'Linked %s\n' "$DEST_TEMPLATE"
fi

if [[ ! -f "$DEST_WRAPPER" ]]; then
  cp "$SOURCE_WRAPPER" "$DEST_WRAPPER"
  printf '%s\tcopy\t%s\n' "$DEST_WRAPPER" "$SOURCE_WRAPPER" >> "$MANIFEST_PATH"
  printf 'Copied wrapper %s\n' "$DEST_WRAPPER"
fi

if ! grep -qx '/_SESSION_WORKFLOW.md' "$EXCLUDE_FILE" 2>/dev/null; then
  [[ -f "$EXCLUDE_FILE" ]] || die "Missing $EXCLUDE_FILE"
  grep -qx "$BLOCK_END" "$EXCLUDE_FILE" || die "Exclude block missing for overlay"
  temp_exclude="$(mktemp)"
  awk -v end="$BLOCK_END" -v line="/_SESSION_WORKFLOW.md" '
    $0 == end && inserted == 0 { print line; inserted = 1 }
    { print }
  ' "$EXCLUDE_FILE" > "$temp_exclude"
  mv "$temp_exclude" "$EXCLUDE_FILE"
fi

printf 'Session workflow files ready.\n  %s\n  %s\n' "$DEST_TEMPLATE" "$DEST_WRAPPER"
