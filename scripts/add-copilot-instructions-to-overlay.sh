#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  add-copilot-instructions-to-overlay.sh \
    --source-repo /path/to/ai-playbook \
    --client-repo /path/to/client-repo \
    --platform universal|ios|android|flutter-riverpod|flutter-bloc \
    [--mode symlink|copy] \
    [--name ai-playbook]

Use when the client repo already has an overlay but `.github/copilot-instructions.md`
was never installed (e.g. overlay predates the universal framework mapping).

Only installs if the source playbook contains `.github/copilot-instructions.md`
(present on universal; optional on other platforms).

`--mode` should match how you installed the other overlay paths (default symlink).

Requires an existing manifest at <git-dir>/<name>/<platform>.manifest.tsv

Example:
  bash scripts/add-copilot-instructions-to-overlay.sh \
    --source-repo ~/private/ai-playbook \
    --client-repo ~/projects/my-api \
    --platform universal
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
[[ "$PLATFORM" == "universal" || "$PLATFORM" == "ios" || "$PLATFORM" == "android" || "$PLATFORM" == "flutter-riverpod" || "$PLATFORM" == "flutter-bloc" ]] || die "--platform must be universal, ios, android, flutter-riverpod, or flutter-bloc"
[[ "$MODE" == "symlink" || "$MODE" == "copy" ]] || die "--mode must be symlink or copy"

[[ -d "$SOURCE_REPO" ]] || die "Source repository does not exist: $SOURCE_REPO"
[[ -d "$CLIENT_REPO" ]] || die "Client repository does not exist: $CLIENT_REPO"

SOURCE_REPO="$(real_dir "$SOURCE_REPO")"
CLIENT_REPO="$(real_dir "$CLIENT_REPO")"

SOURCE_PLATFORM_DIR="$SOURCE_REPO/$PLATFORM"
[[ -d "$SOURCE_PLATFORM_DIR" ]] || die "Could not find source playbook directory: $SOURCE_PLATFORM_DIR"

SOURCE_FILE="$SOURCE_PLATFORM_DIR/.github/copilot-instructions.md"
[[ -f "$SOURCE_FILE" ]] || die "Missing .github/copilot-instructions.md in playbook: $SOURCE_FILE (use universal platform)"

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

[[ -f "$MANIFEST_PATH" ]] || die "No overlay manifest at $MANIFEST_PATH — install the overlay first."

DEST_FILE="$CLIENT_REPO/.github/copilot-instructions.md"
mkdir -p "$(dirname "$DEST_FILE")"

if [[ "$MODE" == "symlink" ]]; then
  if [[ -L "$DEST_FILE" ]]; then
    current="$(readlink "$DEST_FILE")"
    if [[ "$current" == "$SOURCE_FILE" ]]; then
      printf 'Already linked: %s -> %s\n' "$DEST_FILE" "$SOURCE_FILE"
      exit 0
    fi
    die "copilot-instructions.md exists but points elsewhere: $DEST_FILE -> $current"
  fi
  if [[ -e "$DEST_FILE" ]]; then
    die "copilot-instructions.md exists and is not a symlink: $DEST_FILE"
  fi
  ln -s "$SOURCE_FILE" "$DEST_FILE"
else
  if [[ -f "$DEST_FILE" ]] && cmp -s "$SOURCE_FILE" "$DEST_FILE"; then
    printf 'Already copied (identical): %s\n' "$DEST_FILE"
    exit 0
  fi
  if [[ -e "$DEST_FILE" ]]; then
    die "copilot-instructions.md exists: $DEST_FILE"
  fi
  cp "$SOURCE_FILE" "$DEST_FILE"
fi

printf '%s\t%s\t%s\n' "$DEST_FILE" "$MODE" "$SOURCE_FILE" >> "$MANIFEST_PATH"

if ! grep -qx '/.github/copilot-instructions.md' "$EXCLUDE_FILE" 2>/dev/null; then
  [[ -f "$EXCLUDE_FILE" ]] || die "Missing $EXCLUDE_FILE"
  grep -qx "$BLOCK_END" "$EXCLUDE_FILE" || die "Exclude file must contain overlay block ending: $BLOCK_END"

  temp_exclude="$(mktemp)"
  awk -v end="$BLOCK_END" -v line="/.github/copilot-instructions.md" '
    $0 == end && inserted == 0 { print line; inserted = 1 }
    { print }
  ' "$EXCLUDE_FILE" > "$temp_exclude"
  mv "$temp_exclude" "$EXCLUDE_FILE"
fi

printf 'Added .github/copilot-instructions.md (%s)\n  %s\n  manifest: %s\n' "$MODE" "$DEST_FILE" "$MANIFEST_PATH"
