#!/usr/bin/env bash
# Verify assembled skills match canonical SKILL.body.md sources.
set -euo pipefail

REPO="${1:-$(pwd)}"
FAIL=0

check_contains() {
  local file="$1" needle="$2"
  if [[ ! -f "$file" ]]; then
    echo "MISSING $file"
    FAIL=1
    return
  fi
  if ! grep -qF "$needle" "$file"; then
    echo "DRIFT $file (missing expected content)"
    FAIL=1
  fi
}

check_contains "$REPO/.cursor/skills/do-next/SKILL.md" "GSD bootstrap gate"
check_contains "$REPO/.cursor/skills/do-next-runner/SKILL.md" "Never"
check_contains "$REPO/.cursor/skills/gsd-plan-milestone/SKILL.md" "gsd_plan_milestone"
check_contains "$REPO/.cursor/skills/gsd-advance-unit/SKILL.md" "gsd_progress"

if [[ -d "$REPO/.gsd" ]]; then
  echo "OK .gsd/ present"
else
  echo "WARN .gsd/ missing (skills installed but runtime not bootstrapped)"
fi

[[ "$FAIL" == 0 ]] && echo "verify-sync: PASS" || { echo "verify-sync: FAIL"; exit 1; }
