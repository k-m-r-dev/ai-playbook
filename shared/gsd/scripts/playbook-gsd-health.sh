#!/usr/bin/env bash
# Bridge health for do-next family (playbook-gsd ↔ gsd-pi).
# SoT: shared/gsd/scripts/playbook-gsd-health.sh
# Bootstrap copies this to client .workflow/scripts/ (--with-do-next).
#
# Env (optional):
#   PLAYBOOK_ROOT  — ai-playbook checkout containing shared/gsd/mcp/gsd-external-executor
#   GSD_PI_ROOT    — @opengsd/gsd-pi install root
#   GSD_WORKFLOW_PROJECT_ROOT — project under test (defaults to client/repo root)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# .workflow/scripts → repo root is ../..
# shared/gsd/scripts → playbook root is ../../..
if [[ -f "$SCRIPT_DIR/../mcp/gsd-external-executor/scripts/health-check.mjs" ]]; then
  PLAYBOOK_DEFAULT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
  PROJECT_DEFAULT="$PLAYBOOK_DEFAULT"
elif [[ -d "$SCRIPT_DIR/../.." ]]; then
  PROJECT_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd)"
  PLAYBOOK_DEFAULT="$PROJECT_DEFAULT"
else
  PROJECT_DEFAULT="$(pwd)"
  PLAYBOOK_DEFAULT="$PROJECT_DEFAULT"
fi

PLAYBOOK_ROOT="${PLAYBOOK_ROOT:-$PLAYBOOK_DEFAULT}"
export GSD_WORKFLOW_PROJECT_ROOT="${GSD_WORKFLOW_PROJECT_ROOT:-$PROJECT_DEFAULT}"
export GSD_PI_ROOT="${GSD_PI_ROOT:-${HOME}/.npm-global/lib/node_modules/@opengsd/gsd-pi}"
export NODE_PATH="${NODE_PATH:-${GSD_PI_ROOT}/node_modules}"

HEALTH_MJS="$PLAYBOOK_ROOT/shared/gsd/mcp/gsd-external-executor/scripts/health-check.mjs"
if [[ ! -f "$HEALTH_MJS" ]]; then
  printf 'Error: health-check.mjs not found at %s\n' "$HEALTH_MJS" >&2
  printf 'Set PLAYBOOK_ROOT to your ai-playbook checkout.\n' >&2
  exit 2
fi

exec node "$HEALTH_MJS" "$GSD_WORKFLOW_PROJECT_ROOT"
