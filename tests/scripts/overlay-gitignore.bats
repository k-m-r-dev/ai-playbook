#!/usr/bin/env bats
# Tests for scripts/lib/overlay-gitignore.sh
# Run with: bats tests/scripts/overlay-gitignore.bats

LIB="$BATS_TEST_DIRNAME/../../scripts/lib/overlay-gitignore.sh"
PLAYBOOK_DIR="$BATS_TEST_DIRNAME/../.."

# Helper that sources the lib and a stub for remove_block/append_block
_source_lib() {
  # remove_block and append_block are defined in the callers (install/uninstall),
  # so we provide lightweight stubs here.
  remove_block() {
    local file="$1" begin="$2" end="$3"
    local tmp; tmp="$(mktemp)"
    awk -v b="$begin" -v e="$end" '
      $0==b{skip=1;next} $0==e{skip=0;next} !skip{print}
    ' "$file" > "$tmp"
    mv "$tmp" "$file"
  }
  append_block() {
    local file="$1" begin="$2" end="$3"; shift 3
    { printf '%s\n' "$begin"; printf '%s\n' "$@"; printf '%s\n' "$end"; } >> "$file"
  }
  # shellcheck source=../../scripts/lib/overlay-gitignore.sh
  source "$LIB"
}

setup() {
  WORK=$(mktemp -d)
  _source_lib
}

teardown() {
  rm -rf "$WORK"
}

# ── sentinel generators ──────────────────────────────────────────────────────

@test "overlay_gitignore_artifacts_begin returns expected sentinel" {
  result="$(overlay_gitignore_artifacts_begin "ai-playbook")"
  [ "$result" = "# BEGIN ai-playbook:local-artifacts" ]
}

@test "overlay_gitignore_artifacts_end returns expected sentinel" {
  result="$(overlay_gitignore_artifacts_end "ai-playbook")"
  [ "$result" = "# END ai-playbook:local-artifacts" ]
}

@test "overlay_gitignore_platform_begin includes platform name" {
  result="$(overlay_gitignore_platform_begin "ai-playbook" "ios")"
  [ "$result" = "# BEGIN ai-playbook:ios" ]
}

@test "overlay_gitignore_platform_end includes platform name" {
  result="$(overlay_gitignore_platform_end "ai-playbook" "flutter-bloc")"
  [ "$result" = "# END ai-playbook:flutter-bloc" ]
}

# ── overlay_gitignore_read_patterns ──────────────────────────────────────────

@test "read_patterns strips comment lines" {
  printf '# comment\n/dist\n' > "$WORK/patterns.txt"
  result="$(overlay_gitignore_read_patterns "$WORK/patterns.txt")"
  [ "$result" = "/dist" ]
}

@test "read_patterns strips blank lines" {
  printf '/build\n\n/tmp\n' > "$WORK/patterns.txt"
  result="$(overlay_gitignore_read_patterns "$WORK/patterns.txt")"
  [ "$result" = $'/build\n/tmp' ]
}

@test "read_patterns returns failure when file is missing" {
  run overlay_gitignore_read_patterns /nonexistent/file.txt
  [ "$status" -ne 0 ]
}

@test "read_patterns returns empty output for file with only comments" {
  printf '# line 1\n# line 2\n' > "$WORK/patterns.txt"
  result="$(overlay_gitignore_read_patterns "$WORK/patterns.txt")"
  [ -z "$result" ]
}

# ── overlay_gitignore_ensure_file ────────────────────────────────────────────

@test "ensure_file creates .gitignore when absent" {
  [ ! -f "$WORK/.gitignore" ]
  overlay_gitignore_ensure_file "$WORK"
  [ -f "$WORK/.gitignore" ]
}

@test "ensure_file is idempotent when .gitignore exists" {
  echo "*.log" > "$WORK/.gitignore"
  overlay_gitignore_ensure_file "$WORK"
  grep -q "*.log" "$WORK/.gitignore"
}

# ── overlay_gitignore_apply_artifacts ────────────────────────────────────────

@test "apply_artifacts returns failure when artifacts file is missing" {
  run overlay_gitignore_apply_artifacts "$WORK" "ai-playbook" /nonexistent
  [ "$status" -ne 0 ]
}

@test "apply_artifacts writes patterns from artifacts file to .gitignore" {
  printf '/graphify-out\n/.claude-flow\n' > "$PLAYBOOK_DIR/config/client-ai-gitignore-artifacts.txt"
  overlay_gitignore_apply_artifacts "$WORK" "ai-playbook" "$PLAYBOOK_DIR"
  grep -q "# BEGIN ai-playbook:local-artifacts" "$WORK/.gitignore"
}

@test "apply_artifacts is idempotent (no duplicate blocks)" {
  overlay_gitignore_apply_artifacts "$WORK" "ai-playbook" "$PLAYBOOK_DIR"
  overlay_gitignore_apply_artifacts "$WORK" "ai-playbook" "$PLAYBOOK_DIR"
  count="$(grep -c "# BEGIN ai-playbook:local-artifacts" "$WORK/.gitignore")"
  [ "$count" -eq 1 ]
}

@test "apply_artifacts returns success without writing when patterns empty" {
  printf '# only comments\n' > "$WORK/empty-artifacts.txt"
  # Temporarily swap artifacts file
  cp "$PLAYBOOK_DIR/config/client-ai-gitignore-artifacts.txt" "$WORK/orig.txt"
  run bash -c "
    source '$LIB'
    remove_block() { :; }; append_block() { :; }
    overlay_gitignore_artifacts_file() { printf '%s' '$WORK/empty-artifacts.txt'; }
    overlay_gitignore_apply_artifacts '$WORK' 'ai-playbook' '$PLAYBOOK_DIR'
  "
  [ "$status" -eq 0 ]
}

# ── overlay_gitignore_apply_platform ─────────────────────────────────────────

@test "apply_platform writes overlay entries block to .gitignore" {
  overlay_gitignore_apply_platform "$WORK" "ai-playbook" "universal"
  grep -q "# BEGIN ai-playbook:universal" "$WORK/.gitignore"
  grep -q "/_AGENTS.md" "$WORK/.gitignore"
}

@test "apply_platform is idempotent" {
  overlay_gitignore_apply_platform "$WORK" "ai-playbook" "universal"
  overlay_gitignore_apply_platform "$WORK" "ai-playbook" "universal"
  count="$(grep -c "# BEGIN ai-playbook:universal" "$WORK/.gitignore")"
  [ "$count" -eq 1 ]
}

@test "apply_platform uses correct sentinel for flutter-riverpod" {
  overlay_gitignore_apply_platform "$WORK" "ai-playbook" "flutter-riverpod"
  grep -q "# BEGIN ai-playbook:flutter-riverpod" "$WORK/.gitignore"
}

# ── overlay_gitignore_remove_platform ────────────────────────────────────────

@test "remove_platform deletes the platform block" {
  overlay_gitignore_apply_platform "$WORK" "ai-playbook" "ios"
  overlay_gitignore_remove_platform "$WORK" "ai-playbook" "ios"
  ! grep -q "# BEGIN ai-playbook:ios" "$WORK/.gitignore"
}

@test "remove_platform is a no-op when .gitignore absent" {
  run overlay_gitignore_remove_platform "$WORK" "ai-playbook" "ios"
  [ "$status" -eq 0 ]
}

@test "remove_platform leaves other platform blocks intact" {
  overlay_gitignore_apply_platform "$WORK" "ai-playbook" "universal"
  overlay_gitignore_apply_platform "$WORK" "ai-playbook" "ios"
  overlay_gitignore_remove_platform "$WORK" "ai-playbook" "ios"
  grep -q "# BEGIN ai-playbook:universal" "$WORK/.gitignore"
}

# ── overlay_gitignore_remove_artifacts_if_unused ─────────────────────────────

@test "remove_artifacts_if_unused removes artifacts block when no manifests remain" {
  overlay_gitignore_apply_artifacts "$WORK" "ai-playbook" "$PLAYBOOK_DIR"
  STATE="$WORK/state"
  mkdir -p "$STATE"
  overlay_gitignore_remove_artifacts_if_unused "$WORK" "ai-playbook" "$WORK"
  ! grep -q "# BEGIN ai-playbook:local-artifacts" "$WORK/.gitignore"
}

@test "remove_artifacts_if_unused preserves artifacts block when manifests remain" {
  overlay_gitignore_apply_artifacts "$WORK" "ai-playbook" "$PLAYBOOK_DIR"
  STATE="$WORK/ai-playbook"
  mkdir -p "$STATE"
  touch "$STATE/universal.manifest.tsv"
  overlay_gitignore_remove_artifacts_if_unused "$WORK" "ai-playbook" "$WORK"
  grep -q "# BEGIN ai-playbook:local-artifacts" "$WORK/.gitignore"
}
