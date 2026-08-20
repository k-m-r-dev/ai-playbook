#!/usr/bin/env bats
# Tests for GSD workflow skill sync across platform templates + bootstrap reproject script.
# Run with: bats tests/scripts/gsd-skill-sync.bats
#
# Requires: bats-core

PLAYBOOK_DIR="$BATS_TEST_DIRNAME/../.."
SKILLS=(do-next do-next-runner gsd-advance-unit gsd-plan-milestone)
OVERLAYS=(ios android flutter-riverpod flutter-bloc)

setup() {
  CLIENT=""
}

teardown() {
  if [[ -n "${CLIENT:-}" && -d "$CLIENT" ]]; then
    rm -rf "$CLIENT"
  fi
}

@test "shared bodies include compat projection / reproject content" {
  run grep -q "Compat projection drift" "$PLAYBOOK_DIR/shared/gsd/idea/do-next/templates/SKILL.body.md"
  [ "$status" -eq 0 ]
  run grep -q "gsd-reproject-compat.mjs" "$PLAYBOOK_DIR/shared/gsd/idea/do-next/templates/SKILL.body.md"
  [ "$status" -eq 0 ]
  run grep -q "Compat projection drift" "$PLAYBOOK_DIR/shared/gsd/idea/do-next-runner/templates/SKILL.body.md"
  [ "$status" -eq 0 ]
  run grep -q "Compat projection drift" "$PLAYBOOK_DIR/shared/gsd/skills/gsd-advance-unit/SKILL.body.md"
  [ "$status" -eq 0 ]
  run grep -q "gsd-reproject-compat.mjs" "$PLAYBOOK_DIR/shared/gsd/skills/gsd-plan-milestone/SKILL.body.md"
  [ "$status" -eq 0 ]
}

@test "do-next-runner cursor wrapper has closed YAML frontmatter" {
  run tail -n 1 "$PLAYBOOK_DIR/shared/gsd/idea/do-next-runner/templates/SKILL.cursor.md"
  [ "$status" -eq 0 ]
  [[ "$output" == "---" ]]
}

@test "overlays do not ship GSD Cursor skills" {
  for overlay in universal "${OVERLAYS[@]}"; do
    for skill in "${SKILLS[@]}"; do
      [ ! -e "$PLAYBOOK_DIR/$overlay/.cursor/skills/$skill" ]
    done
  done
}

@test "overlays do not ship GSD Copilot instructions" {
  for overlay in universal "${OVERLAYS[@]}"; do
    for skill in "${SKILLS[@]}"; do
      [ ! -e "$PLAYBOOK_DIR/$overlay/.github/instructions/$skill.instructions.md" ]
    done
  done
}

@test "overlays do not ship GSD Claude skills" {
  for overlay in universal "${OVERLAYS[@]}"; do
    for skill in "${SKILLS[@]}"; do
      [ ! -e "$PLAYBOOK_DIR/$overlay/.claude/skills/$skill" ]
    done
  done
}

@test "verify-sync passes on universal overlay" {
  run bash "$PLAYBOOK_DIR/shared/gsd/scripts/verify-sync.sh" "$PLAYBOOK_DIR/universal"
  [ "$status" -eq 0 ]
  [[ "$output" == *"verify-sync: PASS"* ]]
}

@test "bootstrap copies gsd-reproject-compat.mjs into .workflow/scripts" {
  CLIENT=$(mktemp -d)

  run bash "$PLAYBOOK_DIR/scripts/bootstrap-gsd-workflow.sh" \
    --source-repo "$PLAYBOOK_DIR" \
    --client-repo "$CLIENT"
  [ "$status" -eq 0 ]
  [ -f "$CLIENT/.workflow/scripts/gsd-reproject-compat.mjs" ]
  [ -f "$CLIENT/.workflow/scripts/gsd-smoke.sh" ]
}
