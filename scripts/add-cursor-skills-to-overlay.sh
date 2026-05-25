#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  add-cursor-skills-to-overlay.sh \
    --source-repo /path/to/ai-playbook \
    --client-repo /path/to/client-repo \
    --platform ios|android|flutter-riverpod|flutter-bloc \
    [--mode symlink|copy] \
    [--name ai-playbook]

Use when the client repo already has an overlay from install-client-ai-overlay.sh but
`.cursor/skills` was never installed (e.g. the overlay predates that mapping).

`--mode` should match how you installed the other overlay paths (default symlink).

Appends the overlay manifest and `/.cursor/skills` inside .git/info/exclude when missing.

Requires an existing manifest at <git-dir>/<name>/<platform>.manifest.tsv

Examples:
  bash scripts/add-cursor-skills-to-overlay.sh \
    --source-repo ~/Workspace/self/ai-playbook \
    --client-repo ~/Workspace/self/Furqan \
    --platform flutter-riverpod
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

SOURCE_DIR="$SOURCE_PLATFORM_DIR/.cursor/skills"
[[ -d "$SOURCE_DIR" ]] || die "Missing .cursor/skills in playbook: $SOURCE_DIR"

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

[[ -f "$MANIFEST_PATH" ]] || die "No overlay manifest at $MANIFEST_PATH — install the overlay first, or fix --name / --platform."

DEST_DIR="$CLIENT_REPO/.cursor/skills"

if [[ "$MODE" == "symlink" ]]; then
  if [[ -L "$DEST_DIR" ]]; then
    current="$(readlink "$DEST_DIR")"
    if [[ "$current" == "$SOURCE_DIR" ]]; then
      printf 'Already linked: %s -> %s\n' "$DEST_DIR" "$SOURCE_DIR"
      exit 0
    fi
    die ".cursor/skills exists but points elsewhere: $DEST_DIR -> $current (expected $SOURCE_DIR)"
  fi

  if [[ -e "$DEST_DIR" ]]; then
    die ".cursor/skills exists and is not a symlink: $DEST_DIR (remove or move it, then re-run)"
  fi

  mkdir -p "$CLIENT_REPO/.cursor"
  ln -s "$SOURCE_DIR" "$DEST_DIR"
else
  if [[ -L "$DEST_DIR" ]]; then
    current="$(readlink "$DEST_DIR")"
    if [[ "$current" == "$SOURCE_DIR" ]]; then
      printf 'Already linked: %s -> %s\n' "$DEST_DIR" "$SOURCE_DIR"
      exit 0
    fi
    die ".cursor/skills exists but points elsewhere: $DEST_DIR -> $current (expected $SOURCE_DIR)"
  fi

  if [[ -d "$DEST_DIR" ]]; then
    die ".cursor/skills directory already exists: $DEST_DIR"
  fi

  cp -R "$SOURCE_DIR" "$DEST_DIR"
fi

printf '%s\t%s\t%s\n' "$DEST_DIR" "$MODE" "$SOURCE_DIR" >> "$MANIFEST_PATH"

if grep -qx '/.cursor/skills' "$EXCLUDE_FILE" 2>/dev/null; then
  :
else
  [[ -f "$EXCLUDE_FILE" ]] || die "Missing $EXCLUDE_FILE"
  grep -qx "$BLOCK_END" "$EXCLUDE_FILE" || die "Exclude file must contain the overlay block ending with: $BLOCK_END — add /.cursor/skills manually inside that block."

  temp_exclude="$(mktemp)"
  awk -v end="$BLOCK_END" -v line="/.cursor/skills" '
    $0 == end && inserted == 0 { print line; inserted = 1 }
    { print }
  ' "$EXCLUDE_FILE" > "$temp_exclude"
  mv "$temp_exclude" "$EXCLUDE_FILE"
fi

printf 'Added .cursor/skills (%s)\n  %s\n  manifest: %s\n' "$MODE" "$DEST_DIR" "$MANIFEST_PATH"
