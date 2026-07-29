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

@test "platform Cursor skills match universal for the four GSD skills" {
  for overlay in "${OVERLAYS[@]}"; do
    for skill in "${SKILLS[@]}"; do
      run diff -q \
        "$PLAYBOOK_DIR/universal/.cursor/skills/$skill/SKILL.md" \
        "$PLAYBOOK_DIR/$overlay/.cursor/skills/$skill/SKILL.md"
      [ "$status" -eq 0 ]
    done
  done
}

@test "platform Copilot instructions match universal for the four GSD skills" {
  for overlay in "${OVERLAYS[@]}"; do
    for skill in "${SKILLS[@]}"; do
      run diff -q \
        "$PLAYBOOK_DIR/universal/.github/instructions/$skill.instructions.md" \
        "$PLAYBOOK_DIR/$overlay/.github/instructions/$skill.instructions.md"
      [ "$status" -eq 0 ]
    done
  done
}

@test "Claude skill dirs remain symlinks to Cursor on all overlays" {
  for overlay in universal "${OVERLAYS[@]}"; do
    for skill in "${SKILLS[@]}"; do
      path="$PLAYBOOK_DIR/$overlay/.claude/skills/$skill"
      [ -L "$path" ]
      target="$(readlink "$path")"
      [[ "$target" == "../../.cursor/skills/$skill" ]]
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
