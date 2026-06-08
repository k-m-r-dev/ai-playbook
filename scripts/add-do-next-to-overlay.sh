#!/usr/bin/env bash
# Add do-next GSD skills to an existing ai-playbook overlay client.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_REPO=""
CLIENT_REPO=""
PLATFORM=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-repo) SOURCE_REPO="$2"; shift 2 ;;
    --client-repo) CLIENT_REPO="$2"; shift 2 ;;
    --platform) PLATFORM="$2"; shift 2 ;;
    *) printf 'Unknown: %s\n' "$1" >&2; exit 1 ;;
  esac
done

[[ -n "$SOURCE_REPO" && -n "$CLIENT_REPO" ]] || {
  echo "Usage: add-do-next-to-overlay.sh --source-repo ... --client-repo ... [--platform ios]" >&2
  exit 1
}

PLATFORM="${PLATFORM:-universal}"

bash "$SOURCE_REPO/scripts/bootstrap-gsd-workflow.sh" \
  --source-repo "$SOURCE_REPO" \
  --client-repo "$CLIENT_REPO" \
  --platform "$PLATFORM" \
  --init-gsd --with-do-next --patch-mcp

bash "$SOURCE_REPO/shared/gsd/scripts/install-workflow-tools.sh" \
  --project --cursor --claude --copilot \
  --repo "$CLIENT_REPO" \
  --platform "$PLATFORM" \
  --tools "do-next,do-next-runner,gsd-plan-milestone,gsd-advance-unit"

echo "add-do-next-to-overlay.sh complete."
