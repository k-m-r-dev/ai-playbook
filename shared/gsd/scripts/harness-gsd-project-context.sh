#!/usr/bin/env bash
# Copy platform-specific DELIVERY-PROFILE + skill platform.md into a client repo.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  harness-gsd-project-context.sh \
    --source-repo /path/to/ai-playbook \
    --client-repo /path/to/client \
    --platform universal|ios|android|flutter-riverpod|flutter-bloc \
    [--project-style auto|php|node|react-native-mono|python|generic] \
    [--force] [--dry-run]

Copies harness templates from shared/gsd/templates/platforms/<platform>/ into:
  - .gsd/DELIVERY-PROFILE.md (skip if exists unless --force)
  - .cursor/skills/{do-next,gsd-advance-unit}/platform.md
  - .cursor/skills/gsd-plan-milestone/platform.md (from platform.gsd-plan-milestone.md when present)

Falls back to overlay skill platform.md when harness pack is missing a file.
EOF
}

die() { printf 'Error: %s\n' "$1" >&2; exit 1; }

SOURCE_REPO=""
CLIENT_REPO=""
PLATFORM=""
PROJECT_STYLE="auto"
FORCE=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-repo) SOURCE_REPO="$2"; shift 2 ;;
    --client-repo) CLIENT_REPO="$2"; shift 2 ;;
    --platform) PLATFORM="$2"; shift 2 ;;
    --project-style) PROJECT_STYLE="$2"; shift 2 ;;
    --force) FORCE=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown arg: $1" ;;
  esac
done

[[ -n "$SOURCE_REPO" && -n "$CLIENT_REPO" && -n "$PLATFORM" ]] || {
  usage >&2; exit 1
}

SOURCE_REPO="$(cd "$SOURCE_REPO" && pwd)"
CLIENT_REPO="$(cd "$CLIENT_REPO" && pwd)"
SHARED="$SOURCE_REPO/shared/gsd"
PACK="$SHARED/templates/platforms/$PLATFORM"
OVERLAY="$SOURCE_REPO/$PLATFORM"

[[ -d "$PACK" || -d "$OVERLAY" ]] || die "no harness pack or overlay for platform: $PLATFORM"

status() { printf '[%s] %s\n' "$1" "$2"; }

detect_universal_project_style() {
  local repo="$1"

  if [[ -f "$repo/composer.json" ]]; then
    printf '%s\n' "php"
    return
  fi

  if [[ -f "$repo/pyproject.toml" || -f "$repo/requirements.txt" || -f "$repo/setup.py" ]]; then
    printf '%s\n' "python"
    return
  fi

  if [[ -f "$repo/package.json" || -f "$repo/pnpm-workspace.yaml" || -f "$repo/yarn.lock" ]]; then
    if rg -q --glob '**/package.json' '"react-native"|"expo"' "$repo" 2>/dev/null; then
      printf '%s\n' "react-native-mono"
      return
    fi
    printf '%s\n' "node"
    return
  fi

  printf '%s\n' "generic"
}

style_pack_path() {
  local platform="$1"
  local style="$2"

  if [[ "$platform" != "universal" ]]; then
    printf '%s\n' "$SHARED/templates/platforms/$platform"
    return
  fi

  if [[ "$style" == "auto" ]]; then
    style="$(detect_universal_project_style "$CLIENT_REPO")"
  fi

  local candidate="$SHARED/templates/platforms/universal/$style"
  if [[ -d "$candidate" ]]; then
    printf '%s\n' "$candidate"
  else
    printf '%s\n' "$SHARED/templates/platforms/universal"
  fi
}

copy_if() {
  local src="$1" dest="$2"
  [[ -f "$src" ]] || return 0
  if [[ -f "$dest" && "$FORCE" != 1 ]]; then
    status "SKIP" "$dest (exists; use --force)"
    return 0
  fi
  if [[ "$DRY_RUN" == 1 ]]; then
    echo "COPY $dest <- $src"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  status "COPY" "$dest"
}

resolve_src() {
  local name="$1"
  if [[ -f "$PACK/$name" ]]; then
    printf '%s\n' "$PACK/$name"
    return
  fi
  if [[ -f "$OVERLAY/.cursor/skills/do-next/$name" ]]; then
    printf '%s\n' "$OVERLAY/.cursor/skills/do-next/$name"
  fi
}

PACK="$(style_pack_path "$PLATFORM" "$PROJECT_STYLE")"
status "AUTO" "template pack: ${PACK#$SOURCE_REPO/}"

mkdir -p "$CLIENT_REPO/.gsd" "$CLIENT_REPO/.cursor/skills"

# DELIVERY-PROFILE
delivery_src="$PACK/DELIVERY-PROFILE.md"
[[ -f "$delivery_src" ]] || delivery_src="$SHARED/templates/DELIVERY-PROFILE.md"
copy_if "$delivery_src" "$CLIENT_REPO/.gsd/DELIVERY-PROFILE.md"

# platform.md for do-next + gsd-advance-unit
platform_src=""
if [[ -f "$PACK/platform.md" ]]; then
  platform_src="$PACK/platform.md"
elif [[ -f "$OVERLAY/.cursor/skills/do-next/platform.md" ]]; then
  platform_src="$OVERLAY/.cursor/skills/do-next/platform.md"
fi
if [[ -n "$platform_src" ]]; then
  copy_if "$platform_src" "$CLIENT_REPO/.cursor/skills/do-next/platform.md"
  copy_if "$platform_src" "$CLIENT_REPO/.cursor/skills/gsd-advance-unit/platform.md"
fi

# gsd-plan-milestone (may differ)
plan_src=""
if [[ -f "$PACK/platform.gsd-plan-milestone.md" ]]; then
  plan_src="$PACK/platform.gsd-plan-milestone.md"
elif [[ -f "$OVERLAY/.cursor/skills/gsd-plan-milestone/platform.md" ]]; then
  plan_src="$OVERLAY/.cursor/skills/gsd-plan-milestone/platform.md"
elif [[ -n "$platform_src" ]]; then
  plan_src="$platform_src"
fi
if [[ -n "$plan_src" ]]; then
  copy_if "$plan_src" "$CLIENT_REPO/.cursor/skills/gsd-plan-milestone/platform.md"
fi

status "DONE" "harness complete for $PLATFORM → $CLIENT_REPO"
printf '\nCustomize .gsd/DELIVERY-PROFILE.md and .cursor/skills/*/platform.md for this client.\n'
