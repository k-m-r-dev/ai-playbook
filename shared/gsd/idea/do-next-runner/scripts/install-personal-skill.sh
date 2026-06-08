#!/usr/bin/env bash
# Install do-next-runner skill to ~/.cursor/skills/ for cross-project reuse.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IDEA_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE="$IDEA_DIR/templates/SKILL.md"
TARGET_DIR="${HOME}/.cursor/skills/do-next-runner"
TARGET_FILE="$TARGET_DIR/SKILL.md"

if [[ ! -f "$TEMPLATE" ]]; then
  echo "ERROR: template not found: $TEMPLATE" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"
cp "$TEMPLATE" "$TARGET_FILE"

echo "Installed do-next-runner skill:"
echo "  $TARGET_FILE"
echo ""
echo "Per-project: also copy templates/agent.md to .cursor/agents/do-next-runner.md"
echo "Scripts stay in repo: .gsd/idea/do-next-runner/scripts/"
