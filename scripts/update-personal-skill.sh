#!/usr/bin/env bash
# update-personal-skill.sh — Update a single personal skill from playbook sources.
# Thin wrapper around install-personal-agents-hub.sh --skills <name> --force
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER="$SCRIPT_DIR/install-personal-agents-hub.sh"

usage() {
  cat <<'EOF'
Usage: update-personal-skill.sh <skill-name> [options]

Update a single skill in the personal agents hub.
Passes through to install-personal-agents-hub.sh --skills <name> --force.

Options:
  --dry-run         Print actions without executing
  --assemble        Use assemble mode instead of flat
  --no-agents       Skip agent file updates
  -h|--help         Show this help

Examples:
  update-personal-skill.sh ticket-to-plan
  update-personal-skill.sh do-next-runner --assemble
  update-personal-skill.sh graphify-obsidian --dry-run
EOF
}

[[ $# -lt 1 ]] && { usage; exit 1; }

SKILL="$1"
shift

case "$SKILL" in
  -h|--help) usage; exit 0 ;;
esac

[[ -x "$INSTALLER" || -f "$INSTALLER" ]] || {
  printf 'Error: installer not found: %s\n' "$INSTALLER" >&2
  exit 1
}

exec bash "$INSTALLER" --skills "$SKILL" --force "$@"
