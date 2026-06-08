#!/usr/bin/env bash
# Bootstrap GSD workflow runtime into a client repo from ai-playbook/shared/gsd.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bootstrap-gsd-workflow.sh \
    --source-repo /path/to/ai-playbook \
    --client-repo /path/to/client \
    [--platform universal|ios|android|flutter-riverpod|flutter-bloc] \
    [--harness-context] [--init-gsd] [--with-do-next] [--patch-mcp] [--force] [--check]

Copies project-owned .gsd/workflow, idea packages, smoke script, DELIVERY-PROFILE template.
With --platform and --harness-context, copies platform-specific DELIVERY-PROFILE + platform.md
from shared/gsd/templates/platforms/<platform>/ (skip existing unless --force).
EOF
}

die() { printf 'Error: %s\n' "$1" >&2; exit 1; }

SOURCE_REPO=""
CLIENT_REPO=""
PLATFORM=""
INIT_GSD=0
WITH_DO_NEXT=0
PATCH_MCP=0
HARNESS_CONTEXT=0
FORCE=0
CHECK_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-repo) SOURCE_REPO="$2"; shift 2 ;;
    --client-repo) CLIENT_REPO="$2"; shift 2 ;;
    --platform) PLATFORM="$2"; shift 2 ;;
    --harness-context) HARNESS_CONTEXT=1; shift ;;
    --init-gsd) INIT_GSD=1; shift ;;
    --with-do-next) WITH_DO_NEXT=1; shift ;;
    --patch-mcp) PATCH_MCP=1; shift ;;
    --force) FORCE=1; shift ;;
    --check) CHECK_ONLY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown arg: $1" ;;
  esac
done

[[ -n "$SOURCE_REPO" ]] || die "--source-repo required"
[[ -n "$CLIENT_REPO" ]] || die "--client-repo required"
[[ -d "$SOURCE_REPO" ]] || die "source not found"
[[ -d "$CLIENT_REPO" ]] || die "client not found"

SOURCE_REPO="$(cd "$SOURCE_REPO" && pwd)"
CLIENT_REPO="$(cd "$CLIENT_REPO" && pwd)"
SHARED="$SOURCE_REPO/shared/gsd"
[[ -d "$SHARED" ]] || die "missing $SHARED"

status() { printf '[%s] %s\n' "$1" "$2"; }

HAS_GSD=0
[[ -d "$CLIENT_REPO/.gsd" ]] && HAS_GSD=1
HAS_WORKFLOW=0
[[ -d "$CLIENT_REPO/.gsd/workflow" ]] && HAS_WORKFLOW=1
HAS_MCP=0
[[ -f "$CLIENT_REPO/.mcp.json" ]] && grep -q 'gsd-workflow' "$CLIENT_REPO/.mcp.json" 2>/dev/null && HAS_MCP=1

if [[ "$HAS_GSD" == 0 ]]; then status "MISSING" ".gsd/ → use --init-gsd"
else status "OK" ".gsd/ exists"; fi
if [[ "$HAS_WORKFLOW" == 0 ]]; then status "MISSING" ".gsd/workflow/ → will copy"
else status "OK" ".gsd/workflow/"; fi
if [[ "$HAS_MCP" == 0 ]]; then status "MISSING" "gsd-workflow in .mcp.json → use --patch-mcp"
else status "OK" "gsd-workflow MCP"; fi

if [[ "$CHECK_ONLY" == 1 ]]; then
  [[ "$HAS_GSD" == 1 && "$HAS_WORKFLOW" == 1 ]] || exit 1
  exit 0
fi

copy_tree() {
  local src="$1" dest="$2"
  if [[ -e "$dest" && "$FORCE" != 1 ]]; then
    status "SKIP" "$dest (exists; use --force)"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  rm -rf "$dest"
  cp -R "$src" "$dest"
  status "COPY" "$dest"
}

mkdir -p "$CLIENT_REPO/.gsd"
copy_tree "$SHARED/workflow" "$CLIENT_REPO/.gsd/workflow"

if [[ ! -f "$CLIENT_REPO/.gsd/DELIVERY-PROFILE.md" || "$FORCE" == 1 ]]; then
  delivery_tpl="$SHARED/templates/DELIVERY-PROFILE.md"
  if [[ -n "$PLATFORM" && -f "$SHARED/templates/platforms/$PLATFORM/DELIVERY-PROFILE.md" ]]; then
    delivery_tpl="$SHARED/templates/platforms/$PLATFORM/DELIVERY-PROFILE.md"
  fi
  cp "$delivery_tpl" "$CLIENT_REPO/.gsd/DELIVERY-PROFILE.md"
  status "COPY" ".gsd/DELIVERY-PROFILE.md"
fi

if [[ ! -f "$CLIENT_REPO/.gsd/DECISIONS.md" ]]; then
  cp "$SHARED/templates/DECISIONS.md" "$CLIENT_REPO/.gsd/DECISIONS.md"
  status "COPY" ".gsd/DECISIONS.md"
fi

if [[ "$WITH_DO_NEXT" == 1 ]]; then
  copy_tree "$SHARED/idea/do-next" "$CLIENT_REPO/.gsd/idea/do-next"
  copy_tree "$SHARED/idea/do-next-runner" "$CLIENT_REPO/.gsd/idea/do-next-runner"
  mkdir -p "$CLIENT_REPO/.gsd/idea/do-next-runner/scripts"
  cp "$SHARED/idea/do-next-runner/scripts/verify-sync.sh" \
    "$CLIENT_REPO/.gsd/idea/do-next-runner/scripts/verify-sync.sh" 2>/dev/null \
    || cp "$SHARED/scripts/verify-sync.sh" \
      "$CLIENT_REPO/.gsd/idea/do-next-runner/scripts/verify-sync.sh"
  chmod +x "$CLIENT_REPO/.gsd/idea/do-next-runner/scripts/verify-sync.sh"
  status "COPY" ".gsd/idea/do-next-runner/scripts/verify-sync.sh"
fi

mkdir -p "$CLIENT_REPO/.workflow/scripts"
if [[ ! -f "$CLIENT_REPO/.workflow/scripts/gsd-smoke.sh" || "$FORCE" == 1 ]]; then
  cp "$SHARED/scripts/gsd-smoke.sh" "$CLIENT_REPO/.workflow/scripts/gsd-smoke.sh"
  cp "$SHARED/scripts/gsd-smoke.py" "$CLIENT_REPO/.workflow/scripts/gsd-smoke.py"
  chmod +x "$CLIENT_REPO/.workflow/scripts/gsd-smoke.sh"
  status "COPY" ".workflow/scripts/gsd-smoke.*"
fi

if [[ "$INIT_GSD" == 1 && ! -f "$CLIENT_REPO/.gsd/gsd.db" ]]; then
  if command -v gsd >/dev/null 2>&1; then
    (cd "$CLIENT_REPO" && gsd) || die "gsd init failed"
    status "INIT" ".gsd/gsd.db via gsd CLI"
  else
    die "gsd CLI not on PATH; npm install -g gsd-pi"
  fi
fi

if [[ "$PATCH_MCP" == 1 && -f "$SOURCE_REPO/config/mcp.template.json" ]]; then
  if [[ ! -f "$CLIENT_REPO/.mcp.json" ]]; then
    cp "$SOURCE_REPO/config/mcp.template.json" "$CLIENT_REPO/.mcp.json"
    status "COPY" ".mcp.json from template (edit GSD_WORKFLOW_PROJECT_ROOT)"
  else
    status "NOTE" "Merge gsd-workflow into .mcp.json manually if missing"
  fi
fi

mkdir -p "$CLIENT_REPO/.gsd/runtime/do-next-runner"

if [[ "$HARNESS_CONTEXT" == 1 ]]; then
  [[ -n "$PLATFORM" ]] || die "--harness-context requires --platform"
  HARNESS="$SHARED/scripts/harness-gsd-project-context.sh"
  [[ -x "$HARNESS" ]] || chmod +x "$HARNESS"
  harness_args=(--source-repo "$SOURCE_REPO" --client-repo "$CLIENT_REPO" --platform "$PLATFORM")
  [[ "$FORCE" == 1 ]] && harness_args+=(--force)
  bash "$HARNESS" "${harness_args[@]}"
fi

status "DONE" "bootstrap complete for $CLIENT_REPO"
printf '\nNext: customize .gsd/DELIVERY-PROFILE.md + platform.md, then $gsd-plan-milestone\n'
