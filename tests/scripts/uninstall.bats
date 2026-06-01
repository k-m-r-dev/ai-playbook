#!/usr/bin/env bats
# Tests for scripts/uninstall-client-ai-overlay.sh
# Run with: bats tests/scripts/uninstall.bats

INSTALL="$BATS_TEST_DIRNAME/../../scripts/install-client-ai-overlay.sh"
UNINSTALL="$BATS_TEST_DIRNAME/../../scripts/uninstall-client-ai-overlay.sh"
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

_install() {
  local platform="${1:-universal}"
  local mode="${2:-symlink}"
  "$INSTALL" --source-repo "$PLAYBOOK_DIR" --client-repo "$CLIENT" \
    --platform "$platform" --mode "$mode"
}

_uninstall() {
  local platform="${1:-universal}"
  "$UNINSTALL" --client-repo "$CLIENT" --platform "$platform"
}

# ── argument validation ──────────────────────────────────────────────────────

@test "dies without --client-repo" {
  run "$UNINSTALL" --platform universal
  [ "$status" -ne 0 ]
  [[ "$output" =~ "--client-repo is required" ]]
}

@test "dies without --platform" {
  run "$UNINSTALL" --client-repo "$CLIENT"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "--platform must be" ]]
}

@test "dies when no manifest exists (overlay never installed)" {
  run _uninstall universal
  [ "$status" -ne 0 ]
  [[ "$output" =~ "No installed overlay found" ]]
}

@test "dies when client-repo is not a git repository" {
  NOTGIT=$(mktemp -d)
  run "$UNINSTALL" --client-repo "$NOTGIT" --platform universal
  [ "$status" -ne 0 ]
  [[ "$output" =~ "not a Git repository" ]]
  rm -rf "$NOTGIT"
}

# ── normal symlink uninstall ─────────────────────────────────────────────────

@test "removes managed symlinks" {
  _install universal symlink
  _uninstall universal
  [ ! -e "$CLIENT/AGENTS.md" ]
  [ ! -e "$CLIENT/CLAUDE.md" ]
}

@test "does not remove symlinks pointing to different source" {
  _install universal symlink
  FAKE_SRC=$(mktemp)
  ln -sf "$FAKE_SRC" /tmp/probe_agents_md_test 2>/dev/null || true
  # Manually point AGENTS.md symlink somewhere else, then uninstall should leave it
  rm "$CLIENT/AGENTS.md"
  ln -s /tmp/unrelated_file "$CLIENT/AGENTS.md"
  # uninstall should skip this — it doesn't match the manifest source
  _uninstall universal
  [ -L "$CLIENT/AGENTS.md" ]  # still present because we didn't manage it
  rm -f "$CLIENT/AGENTS.md" "$FAKE_SRC"
}

@test "removes manifest file after uninstall" {
  _install universal symlink
  _uninstall universal
  MANIFEST="$CLIENT/.git/ai-playbook/universal.manifest.tsv"
  [ ! -f "$MANIFEST" ]
}

@test "prunes empty parent directories after removing managed files" {
  _install universal symlink
  _uninstall universal
  # .github/agents and .github/instructions are managed; if both removed, .github should be pruned
  [ ! -d "$CLIENT/.github" ] || [ -n "$(ls -A "$CLIENT/.github" 2>/dev/null)" ]
}

# ── copy-mode uninstall ──────────────────────────────────────────────────────

@test "removes copied directory entries" {
  _install universal copy
  _uninstall universal
  [ ! -d "$CLIENT/.claude/helpers" ]
}

# ── retain mode (.workflow) ──────────────────────────────────────────────────

@test ".workflow directory is retained on uninstall (session state stays)" {
  _install universal symlink
  [ -d "$CLIENT/.workflow" ]
  _uninstall universal
  [ -d "$CLIENT/.workflow" ]
}

# ── gitignore / exclude cleanup ──────────────────────────────────────────────

@test "removes managed block from .git/info/exclude" {
  _install universal symlink
  _uninstall universal
  ! grep -q "# BEGIN ai-playbook:universal" "$CLIENT/.git/info/exclude"
}

@test "removes platform block from .gitignore" {
  _install universal symlink
  _uninstall universal
  ! grep -q "# BEGIN ai-playbook:universal" "$CLIENT/.gitignore"
}

@test "removes local-artifacts block from .gitignore when last platform uninstalled" {
  _install universal symlink
  _uninstall universal
  ! grep -q "# BEGIN ai-playbook:local-artifacts" "$CLIENT/.gitignore"
}

@test "preserves local-artifacts .gitignore block when other platforms still installed" {
  _install universal symlink
  _install ios    symlink
  _uninstall universal
  grep -q "# BEGIN ai-playbook:local-artifacts" "$CLIENT/.gitignore"
}

@test "preserves unrelated .gitignore content" {
  echo "dist/" > "$CLIENT/.gitignore"
  _install universal symlink
  _uninstall universal
  grep -q "dist/" "$CLIENT/.gitignore"
}

# ── roundtrip ────────────────────────────────────────────────────────────────

@test "reinstall succeeds after clean uninstall" {
  _install universal symlink
  _uninstall universal
  run _install universal symlink
  [ "$status" -eq 0 ]
}
