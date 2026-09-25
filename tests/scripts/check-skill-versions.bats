#!/usr/bin/env bats
# Version check for personal hub skills. No API key.
# Run: bats tests/scripts/check-skill-versions.bats

SCRIPT="$BATS_TEST_DIRNAME/../../scripts/install-personal-agents-hub.sh"
PLAYBOOK_DIR="$BATS_TEST_DIRNAME/../.."
SKILL_SRC="$PLAYBOOK_DIR/shared/gsd/skills/natural-scope"

setup() {
  HOME="$(mktemp -d)"
  export HOME
  mkdir -p "$HOME/.agents/skills" "$HOME/.cursor/skills" "$HOME/.claude/skills" "$HOME/.copilot/skills"
  cp -R "$SKILL_SRC" "$HOME/.agents/skills/natural-scope"
  ln -s "$HOME/.agents/skills/natural-scope" "$HOME/.cursor/skills/natural-scope"
  ln -s "$HOME/.agents/skills/natural-scope" "$HOME/.claude/skills/natural-scope"
  ln -s "$HOME/.agents/skills/natural-scope" "$HOME/.copilot/skills/natural-scope"
}

teardown() {
  rm -rf "$HOME"
}

@test "matching hub version and bridges pass" {
  run "$SCRIPT" --check-versions --skills natural-scope --no-agents
  [ "$status" -eq 0 ]
  [[ "$output" =~ "natural-scope source=1.0.0 hub=1.0.0 ok" ]]
}

@test "stale hub version fails" {
  python3 - "$HOME/.agents/skills/natural-scope/SKILL.md" <<'PY'
import pathlib, sys
path = pathlib.Path(sys.argv[1])
path.write_text(path.read_text().replace('version: "1.0.0"', 'version: "0.0.1"', 1))
PY
  run "$SCRIPT" --check-versions --skills natural-scope --no-agents
  [ "$status" -ne 0 ]
  [[ "$output" =~ "STALE" ]]
}

@test "real bridge directory fails" {
  rm "$HOME/.cursor/skills/natural-scope"
  mkdir "$HOME/.cursor/skills/natural-scope"
  run "$SCRIPT" --check-versions --skills natural-scope --no-agents
  [ "$status" -ne 0 ]
  [[ "$output" =~ "not a symlink" ]]
}
