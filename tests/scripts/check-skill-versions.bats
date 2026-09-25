#!/usr/bin/env bats
# Version check for personal hub skills. No API key.
# Run: bats tests/scripts/check-skill-versions.bats

SCRIPT="$BATS_TEST_DIRNAME/../../scripts/install-personal-agents-hub.sh"
PLAYBOOK_DIR="$BATS_TEST_DIRNAME/../.."

setup() {
  HOME="$(mktemp -d)"
  export HOME
  mkdir -p "$HOME/.agents/skills" "$HOME/.cursor/skills" "$HOME/.claude/skills" "$HOME/.copilot/skills"
  _install_skill natural-scope
  _install_skill technical-scope
}

teardown() {
  rm -rf "$HOME"
}

_install_skill() {
  local skill="$1"
  cp -R "$PLAYBOOK_DIR/shared/gsd/skills/$skill" "$HOME/.agents/skills/$skill"
  ln -s "$HOME/.agents/skills/$skill" "$HOME/.cursor/skills/$skill"
  ln -s "$HOME/.agents/skills/$skill" "$HOME/.claude/skills/$skill"
  ln -s "$HOME/.agents/skills/$skill" "$HOME/.copilot/skills/$skill"
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

@test "technical-scope matching hub version and bridges pass" {
  run "$SCRIPT" --check-versions --skills technical-scope --no-agents
  [ "$status" -eq 0 ]
  [[ "$output" =~ "technical-scope source=1.0.0 hub=1.0.0 ok" ]]
}

@test "technical-scope stale hub version fails" {
  python3 - "$HOME/.agents/skills/technical-scope/SKILL.md" <<'PY'
import pathlib, sys
path = pathlib.Path(sys.argv[1])
path.write_text(path.read_text().replace('version: "1.0.0"', 'version: "0.0.1"', 1))
PY
  run "$SCRIPT" --check-versions --skills technical-scope --no-agents
  [ "$status" -ne 0 ]
  [[ "$output" =~ "STALE" ]]
}

@test "technical-scope real bridge directory fails" {
  rm "$HOME/.cursor/skills/technical-scope"
  mkdir "$HOME/.cursor/skills/technical-scope"
  run "$SCRIPT" --check-versions --skills technical-scope --no-agents
  [ "$status" -ne 0 ]
  [[ "$output" =~ "not a symlink" ]]
}
