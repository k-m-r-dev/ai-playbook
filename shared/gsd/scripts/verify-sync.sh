#!/usr/bin/env bash
# Verify assembled skills match canonical SKILL.body.md sources.
# Also verifies personal hub integrity and platform overlay cleanliness.
set -euo pipefail

GSD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
PLAYBOOK_ROOT="$(cd "$GSD_ROOT/../.." && pwd)"
REPO="${1:-$(pwd)}"
FAIL=0
WARN=0

check_contains() {
  local file="$1" needle="$2"
  if [[ ! -f "$file" ]]; then
    echo "MISSING $file"
    FAIL=1
    return
  fi
  if ! grep -qF "$needle" "$file"; then
    echo "DRIFT $file (missing expected content: $needle)"
    FAIL=1
  fi
}

check_not_exists() {
  local path="$1" msg="$2"
  if [[ -e "$path" || -L "$path" ]]; then
    echo "STALE $path ($msg)"
    FAIL=1
  fi
}

check_symlink() {
  local link="$1" expected_target="$2"
  if [[ ! -L "$link" ]]; then
    if [[ -e "$link" ]]; then
      echo "WARN $link exists but is not a symlink (expected -> $expected_target)"
      WARN=1
    fi
    return
  fi
  local actual
  actual="$(readlink "$link")"
  if [[ "$actual" != "$expected_target" && "$actual" != *"$expected_target" ]]; then
    echo "DRIFT $link -> $actual (expected -> $expected_target)"
    FAIL=1
  fi
}

# --- Client project skill checks ---
if [[ -d "$REPO/.cursor/skills/do-next" ]]; then
  check_contains "$REPO/.cursor/skills/do-next/SKILL.md" "GSD bootstrap gate"
  check_contains "$REPO/.cursor/skills/do-next/SKILL.md" "Compat projection drift"
  check_contains "$REPO/.cursor/skills/do-next/SKILL.md" "gsd-reproject-compat.mjs"
fi

if [[ -d "$REPO/.cursor/skills/do-next-runner" ]]; then
  check_contains "$REPO/.cursor/skills/do-next-runner/SKILL.md" "Never"
  check_contains "$REPO/.cursor/skills/do-next-runner/SKILL.md" "Compat projection drift"
fi

if [[ -d "$REPO/.cursor/skills/gsd-plan-milestone" ]]; then
  check_contains "$REPO/.cursor/skills/gsd-plan-milestone/SKILL.md" "gsd_plan_milestone"
  check_contains "$REPO/.cursor/skills/gsd-plan-milestone/SKILL.md" "gsd-reproject-compat.mjs"
fi

if [[ -d "$REPO/.cursor/skills/gsd-advance-unit" ]]; then
  check_contains "$REPO/.cursor/skills/gsd-advance-unit/SKILL.md" "gsd_progress"
  check_contains "$REPO/.cursor/skills/gsd-advance-unit/SKILL.md" "Compat projection drift"
fi

# --- Copilot instruction checks ---
if [[ -f "$REPO/.github/instructions/do-next.instructions.md" ]]; then
  check_contains "$REPO/.github/instructions/do-next.instructions.md" "gsd-reproject-compat.mjs"
fi

# --- GSD runtime check ---
if [[ -d "$REPO/.gsd" ]]; then
  echo "OK .gsd/ present"
else
  echo "WARN .gsd/ missing (skills installed but runtime not bootstrapped)"
  WARN=1
fi

# --- Personal hub checks ---
HUB="$HOME/.agents/skills"
LOCKFILE="$HOME/.playbook-hub-lock.json"

if [[ -d "$HUB" ]]; then
  echo "OK Personal hub exists at $HUB"
  for skill in do-next do-next-runner gsd-plan-milestone gsd-advance-unit \
               ticket-to-plan verified-pr-review graphify-obsidian; do
    if [[ -f "$HUB/$skill/SKILL.md" ]]; then
      echo "OK hub/$skill"
    else
      echo "WARN hub/$skill/SKILL.md missing"
      WARN=1
    fi
  done

  # Check bridges
  for skill in do-next do-next-runner gsd-plan-milestone gsd-advance-unit \
               ticket-to-plan verified-pr-review graphify-obsidian; do
    check_symlink "$HOME/.cursor/skills/$skill" "$HUB/$skill"
    check_symlink "$HOME/.claude/skills/$skill" "$HUB/$skill"
  done

  # Check lockfile
  if [[ -f "$LOCKFILE" ]]; then
    echo "OK lockfile exists"
  else
    echo "WARN lockfile missing ($LOCKFILE) -- run install-personal-agents-hub.sh"
    WARN=1
  fi
else
  echo "INFO Personal hub not installed (optional -- run install-personal-agents-hub.sh)"
fi

# --- Platform overlay cleanliness (run from playbook root) ---
if [[ -d "$PLAYBOOK_ROOT/universal" && -f "$GSD_ROOT/personal-skills.manifest" ]]; then
  SOT_SKILLS=(do-next do-next-runner gsd-plan-milestone gsd-advance-unit \
              ticket-to-plan verified-pr-review graphify-obsidian)
  for plat in universal ios android flutter-riverpod flutter-bloc; do
    base="$PLAYBOOK_ROOT/$plat"
    [[ -d "$base" ]] || continue
    for skill in "${SOT_SKILLS[@]}"; do
      check_not_exists "$base/.cursor/skills/$skill" "SoT skill should not be in platform overlay"
      check_not_exists "$base/.claude/skills/$skill" "SoT skill should not be in platform overlay"
    done
    check_not_exists "$base/.cursor/agents/do-next-runner.md" "agent should not be in platform overlay"
    check_not_exists "$base/.claude/agents/do-next-runner.md" "agent should not be in platform overlay"
    for instr in do-next do-next-runner gsd-advance-unit gsd-plan-milestone; do
      check_not_exists "$base/.github/instructions/$instr.instructions.md" "SoT instruction should not be in platform overlay"
    done
  done
fi

# --- Summary ---
if [[ "$FAIL" != 0 ]]; then
  echo "verify-sync: FAIL"
  exit 1
elif [[ "$WARN" != 0 ]]; then
  echo "verify-sync: PASS (with warnings)"
  exit 0
else
  echo "verify-sync: PASS"
  exit 0
fi
