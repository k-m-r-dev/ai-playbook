#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  patch-hook-safety-overlay.sh \
    --source-repo /path/to/ai-playbook \
    --client-repo /path/to/client-repo \
    [--platform universal|ios|android|flutter-riverpod|flutter-bloc] \
    [--all-installed] \
    [--mode symlink|copy] \
    [--name ai-playbook]

Patches already-installed overlays with hardened Claude hook helpers:
  - .claude/helpers/hook-handler.cjs

Notes:
  - Requires existing overlay manifest at <git-dir>/<name>/<platform>.manifest.tsv
  - If --platform is omitted with --all-installed, all installed platforms are patched.
  - If --mode is omitted, mode is inferred from existing manifest entries.
  - Refuses to overwrite unmanaged paths.
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
MODE=""
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
[[ -z "$MODE" || "$MODE" == "symlink" || "$MODE" == "copy" ]] || die "--mode must be symlink or copy"
if [[ "$ALL_INSTALLED" == "false" ]]; then
  [[ -n "$PLATFORM" ]] || die "Pass --platform or use --all-installed"
fi

[[ -d "$SOURCE_REPO" ]] || die "Source repository does not exist: $SOURCE_REPO"
[[ -d "$CLIENT_REPO" ]] || die "Client repository does not exist: $CLIENT_REPO"

SOURCE_REPO="$(real_dir "$SOURCE_REPO")"
CLIENT_REPO="$(real_dir "$CLIENT_REPO")"

GIT_DIR_RAW="$(git -C "$CLIENT_REPO" rev-parse --git-dir 2>/dev/null)" || die "Client path is not a Git repository: $CLIENT_REPO"
if [[ "$GIT_DIR_RAW" = /* ]]; then
  GIT_DIR="$GIT_DIR_RAW"
else
  GIT_DIR="$(real_dir "$CLIENT_REPO/$GIT_DIR_RAW")"
fi

STATE_DIR="$GIT_DIR/${NAME}"
DEST_DIR="$CLIENT_REPO/.claude/helpers"

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

patch_platform() {
  local platform="$1"
  local source_platform_dir="$SOURCE_REPO/$platform"
  [[ -d "$source_platform_dir" ]] || die "Could not find source playbook directory: $source_platform_dir"

  local source_dir="$source_platform_dir/.claude/helpers"
  [[ -d "$source_dir" ]] || die "Missing .claude/helpers in playbook: $source_dir"

  local manifest_path="$STATE_DIR/${platform}.manifest.tsv"
  [[ -f "$manifest_path" ]] || die "No overlay manifest at $manifest_path — install overlay first."

  local block_end="# END ${NAME}:${platform}"
  local exclude_file="$GIT_DIR/info/exclude"
  local mode="$MODE"
  if [[ -z "$mode" ]]; then
    mode="$(awk -F'\t' '$2=="symlink" || $2=="copy" { print $2; exit }' "$manifest_path")"
    [[ -n "$mode" ]] || mode="symlink"
  fi

  local existing_manifest_line existing_mode existing_source
  existing_manifest_line="$(awk -F'\t' -v dest="$DEST_DIR" '$1==dest { print $0; exit }' "$manifest_path")"
  if [[ -n "$existing_manifest_line" ]]; then
    existing_mode="$(printf '%s' "$existing_manifest_line" | awk -F'\t' '{print $2}')"
    existing_source="$(printf '%s' "$existing_manifest_line" | awk -F'\t' '{print $3}')"
  else
    existing_mode=""
    existing_source=""
  fi

  if [[ "$mode" == "symlink" ]]; then
    if [[ -L "$DEST_DIR" ]]; then
      current="$(readlink "$DEST_DIR")"
      if [[ -n "$existing_source" && "$current" != "$existing_source" ]]; then
        die ".claude/helpers is managed but points elsewhere: $DEST_DIR -> $current"
      fi
      rm "$DEST_DIR"
    elif [[ -e "$DEST_DIR" ]]; then
      if [[ "$existing_mode" != "copy" ]]; then
        die ".claude/helpers exists and appears unmanaged: $DEST_DIR"
      fi
      rm -rf "$DEST_DIR"
    fi
    ln -s "$source_dir" "$DEST_DIR"
  else
    if [[ -L "$DEST_DIR" ]]; then
      if [[ "$existing_mode" != "symlink" ]]; then
        die ".claude/helpers symlink appears unmanaged: $DEST_DIR"
      fi
      rm "$DEST_DIR"
    elif [[ -e "$DEST_DIR" && "$existing_mode" != "copy" ]]; then
      die ".claude/helpers exists and appears unmanaged: $DEST_DIR"
    fi
    rm -rf "$DEST_DIR"
    mkdir -p "$(dirname "$DEST_DIR")"
    cp -R "$source_dir" "$DEST_DIR"
  fi

  temp_manifest="$(mktemp)"
  awk -F'\t' -v OFS='\t' -v dest="$DEST_DIR" -v mode="$mode" -v source="$source_dir" '
    $1 == dest { print dest, mode, source; replaced = 1; next }
    { print }
    END { if (!replaced) print dest, mode, source }
  ' "$manifest_path" > "$temp_manifest"
  mv "$temp_manifest" "$manifest_path"

  if ! grep -qx '/.claude/helpers' "$exclude_file" 2>/dev/null; then
    [[ -f "$exclude_file" ]] || die "Missing $exclude_file"
    grep -qx "$block_end" "$exclude_file" || die "Exclude file must contain overlay block ending: $block_end"
    temp_exclude="$(mktemp)"
    awk -v end="$block_end" -v line="/.claude/helpers" '
      $0 == end && inserted == 0 { print line; inserted = 1 }
      { print }
    ' "$exclude_file" > "$temp_exclude"
    mv "$temp_exclude" "$exclude_file"
  fi

  printf 'Patched hook safety overlay [%s] (%s)\n  %s -> %s\n  manifest: %s\n' "$platform" "$mode" "$source_dir" "$DEST_DIR" "$manifest_path"
}

if [[ -n "$PLATFORM" ]]; then
  case "$PLATFORM" in
    universal|ios|android|flutter-riverpod|flutter-bloc) ;;
    *) die "--platform must be universal, ios, android, flutter-riverpod, or flutter-bloc" ;;
  esac
fi

while IFS= read -r p; do
  patch_platform "$p"
done < <(resolve_platforms)
