#!/usr/bin/env bats
# Tests for scripts/install-client-ai-overlay.sh
# Run with: bats tests/scripts/install.bats
#
# Requires: bats-core, git

SCRIPT="$BATS_TEST_DIRNAME/../../scripts/install-client-ai-overlay.sh"
PLAYBOOK_DIR="$BATS_TEST_DIRNAME/../.."

setup() {
  CLIENT=$(mktemp -d)
  git -C "$CLIENT" init -q
  git -C "$CLIENT" commit --allow-empty -q -m "init"
  mkdir -p "$CLIENT/.git/info"
  touch "$CLIENT/.git/info/exclude"
}

teardown() {
  rm -rf "$CLIENT"
}

# ── argument validation ──────────────────────────────────────────────────────

@test "dies without --source-repo" {
  run "$SCRIPT" --client-repo "$CLIENT" --platform universal
  [ "$status" -ne 0 ]
  [[ "$output" =~ "--source-repo is required" ]]
}

@test "dies without --client-repo" {
  run "$SCRIPT" --source-repo "$PLAYBOOK_DIR" --platform universal
  [ "$status" -ne 0 ]
  [[ "$output" =~ "--client-repo is required" ]]
}

@test "dies without --platform" {
  run "$SCRIPT" --source-repo "$PLAYBOOK_DIR" --client-repo "$CLIENT"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "--platform must be" ]]
}

@test "dies on unknown --platform value" {
  run "$SCRIPT" --source-repo "$PLAYBOOK_DIR" --client-repo "$CLIENT" --platform web
  [ "$status" -ne 0 ]
  [[ "$output" =~ "--platform must be" ]]
}

@test "dies on unknown --mode value" {
  run "$SCRIPT" --source-repo "$PLAYBOOK_DIR" --client-repo "$CLIENT" --platform universal --mode hardlink
  [ "$status" -ne 0 ]
  [[ "$output" =~ "--mode must be" ]]
}

@test "dies when source-repo does not exist" {
  run "$SCRIPT" --source-repo /nonexistent --client-repo "$CLIENT" --platform universal
  [ "$status" -ne 0 ]
  [[ "$output" =~ "Source repository does not exist" ]]
}

@test "dies when client-repo is not a git repository" {
  NOTGIT=$(mktemp -d)
  run "$SCRIPT" --source-repo "$PLAYBOOK_DIR" --client-repo "$NOTGIT" --platform universal
  [ "$status" -ne 0 ]
  [[ "$output" =~ "not a Git repository" ]]
  rm -rf "$NOTGIT"
}

@test "dies when called a second time for same platform (already installed)" {
  "$SCRIPT" --source-repo "$PLAYBOOK_DIR" --client-repo "$CLIENT" --platform universal
  run "$SCRIPT" --source-repo "$PLAYBOOK_DIR" --client-repo "$CLIENT" --platform universal
  [ "$status" -ne 0 ]
  [[ "$output" =~ "already installed" ]]
}

# ── symlink mode (default) ───────────────────────────────────────────────────

@test "symlink mode: _AGENTS.md symlink created in client repo" {
  "$SCRIPT" --source-repo "$PLAYBOOK_DIR" --client-repo "$CLIENT" --platform universal
  [ -L "$CLIENT/_AGENTS.md" ]
}

@test "symlink mode: _AGENTS.md target resolves to playbook template" {
  "$SCRIPT" --source-repo "$PLAYBOOK_DIR" --client-repo "$CLIENT" --platform universal
  target="$(readlink "$CLIENT/_AGENTS.md")"
  [[ "$target" == *"/universal/_AGENTS.md" ]]
}

@test "symlink mode: AGENTS.md wrapper is a regular file (copy)" {
  "$SCRIPT" --source-repo "$PLAYBOOK_DIR" --client-repo "$CLIENT" --platform universal
  [ -f "$CLIENT/AGENTS.md" ]
  [ ! -L "$CLIENT/AGENTS.md" ]
  head -1 "$CLIENT/AGENTS.md" | grep -q '@_AGENTS.md'
}

@test "symlink mode: manifest written under .git" {
  "$SCRIPT" --source-repo "$PLAYBOOK_DIR" --client-repo "$CLIENT" --platform universal
  MANIFEST="$CLIENT/.git/ai-playbook/universal.manifest.tsv"
  [ -f "$MANIFEST" ]
}

@test "symlink mode: manifest records install mode as symlink" {
  "$SCRIPT" --source-repo "$PLAYBOOK_DIR" --client-repo "$CLIENT" --platform universal
  MANIFEST="$CLIENT/.git/ai-playbook/universal.manifest.tsv"
  grep -q $'\tsymlink\t' "$MANIFEST"
}

# ── copy mode ────────────────────────────────────────────────────────────────

@test "copy mode: _AGENTS.md is still symlinked when mode is copy" {
  "$SCRIPT" --source-repo "$PLAYBOOK_DIR" --client-repo "$CLIENT" --platform universal --mode copy
  [ -L "$CLIENT/_AGENTS.md" ]
  [ -f "$CLIENT/AGENTS.md" ]
  [ ! -L "$CLIENT/AGENTS.md" ]
}

@test "copy mode: manifest records install mode as copy" {
  "$SCRIPT" --source-repo "$PLAYBOOK_DIR" --client-repo "$CLIENT" --platform universal --mode copy
  MANIFEST="$CLIENT/.git/ai-playbook/universal.manifest.tsv"
  grep -q $'\tcopy\t' "$MANIFEST"
}

# ── .workflow always copied ──────────────────────────────────────────────────

@test ".workflow is always installed as a copy even in symlink mode" {
  "$SCRIPT" --source-repo "$PLAYBOOK_DIR" --client-repo "$CLIENT" --platform universal
  [ -d "$CLIENT/.workflow" ]
  [ ! -L "$CLIENT/.workflow" ]
}

@test "existing .workflow directory is retained on reinstall after partial uninstall" {
  mkdir -p "$CLIENT/.workflow"
  touch "$CLIENT/.workflow/local.log"
  # Manually bootstrap a stripped manifest so installer sees no prior state
  # but .workflow dir exists — installer should retain, not die
  run "$SCRIPT" --source-repo "$PLAYBOOK_DIR" --client-repo "$CLIENT" --platform universal
  [ -f "$CLIENT/.workflow/local.log" ]
}

# ── gitignore / exclude updates ──────────────────────────────────────────────

@test "installs managed block in .git/info/exclude" {
  "$SCRIPT" --source-repo "$PLAYBOOK_DIR" --client-repo "$CLIENT" --platform universal
  grep -q "# BEGIN ai-playbook:universal" "$CLIENT/.git/info/exclude"
  grep -q "# END ai-playbook:universal"   "$CLIENT/.git/info/exclude"
}

@test "creates client .gitignore when absent" {
  [ ! -f "$CLIENT/.gitignore" ]
  "$SCRIPT" --source-repo "$PLAYBOOK_DIR" --client-repo "$CLIENT" --platform universal
  [ -f "$CLIENT/.gitignore" ]
}

@test "appends local-artifacts block to .gitignore" {
  "$SCRIPT" --source-repo "$PLAYBOOK_DIR" --client-repo "$CLIENT" --platform universal
  grep -q "# BEGIN ai-playbook:local-artifacts" "$CLIENT/.gitignore"
}

@test "appends platform overlay block to .gitignore" {
  "$SCRIPT" --source-repo "$PLAYBOOK_DIR" --client-repo "$CLIENT" --platform universal
  grep -q "# BEGIN ai-playbook:universal" "$CLIENT/.gitignore"
}

@test "existing .gitignore content is preserved after install" {
  echo "node_modules/" > "$CLIENT/.gitignore"
  "$SCRIPT" --source-repo "$PLAYBOOK_DIR" --client-repo "$CLIENT" --platform universal
  grep -q "node_modules/" "$CLIENT/.gitignore"
}

# ── conflict detection ───────────────────────────────────────────────────────

@test "dies when unmanaged file exists at target path" {
  echo "existing content" > "$CLIENT/AGENTS.md"
  run "$SCRIPT" --source-repo "$PLAYBOOK_DIR" --client-repo "$CLIENT" --platform universal
  [ "$status" -ne 0 ]
  [[ "$output" =~ "not managed by this installer" ]]
}

@test "skips source files that do not exist in playbook" {
  # Providing a platform that might be missing optional files — should not fail
  run "$SCRIPT" --source-repo "$PLAYBOOK_DIR" --client-repo "$CLIENT" --platform ios
  [ "$status" -eq 0 ]
}
