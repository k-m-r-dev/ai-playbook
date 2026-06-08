#!/usr/bin/env bash
# Build GSD-family skills into every ai-playbook platform overlay directory.
set -euo pipefail

PLAYBOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="$PLAYBOOK/shared/gsd/scripts/install-workflow-tools.sh"

PLATFORMS=(universal ios android flutter-riverpod flutter-bloc)

for p in "${PLATFORMS[@]}"; do
  base="$PLAYBOOK/$p"
  [[ -d "$base" ]] || continue
  echo "=== Sync $p ==="
  bash "$INSTALLER" --project --cursor --claude --copilot --repo "$base" --copy
done

echo "sync-gsd-skills-to-overlays.sh complete."
