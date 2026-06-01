#!/usr/bin/env bats
# Tests for scripts/verify-hook-safety.sh
# Run with: bats tests/scripts/verify-hook-safety.bats

SCRIPT="$BATS_TEST_DIRNAME/../../scripts/verify-hook-safety.sh"
CANONICAL="$BATS_TEST_DIRNAME/../../.claude/helpers/hook-handler.cjs"
PLATFORMS=(universal ios android flutter-bloc flutter-riverpod)

# ── canonical file presence ──────────────────────────────────────────────────

@test "canonical hook-handler.cjs exists" {
  [ -f "$CANONICAL" ]
}

# ── all platform copies in sync ──────────────────────────────────────────────

@test "all platform hook-handler.cjs copies are byte-identical to canonical" {
  for platform in "${PLATFORMS[@]}"; do
    target="$BATS_TEST_DIRNAME/../../$platform/.claude/helpers/hook-handler.cjs"
    run cmp -s "$CANONICAL" "$target"
    [ "$status" -eq 0 ]
  done
}

# ── script passes on clean repo ──────────────────────────────────────────────

@test "verify-hook-safety.sh exits 0 on a clean repo" {
  run "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "verify-hook-safety.sh reports sync OK" {
  run "$SCRIPT"
  [[ "$output" =~ "OK: all platform copies are in sync" ]]
}

@test "verify-hook-safety.sh reports decision contract OK" {
  run "$SCRIPT"
  [[ "$output" =~ "OK: core commands emit valid decision JSON" ]]
}

@test "verify-hook-safety.sh reports timeout verification OK" {
  run "$SCRIPT"
  [[ "$output" =~ "OK: timeout path fail-open verified" ]]
}

# ── drift detection ──────────────────────────────────────────────────────────

@test "script fails when a platform copy is modified" {
  WORK=$(mktemp -d)
  cp -R "$BATS_TEST_DIRNAME/../.." "$WORK/repo"
  # Tamper with one platform copy
  echo "// drift" >> "$WORK/repo/ios/.claude/helpers/hook-handler.cjs"
  run "$WORK/repo/scripts/verify-hook-safety.sh"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "Drift detected" ]]
  rm -rf "$WORK"
}

@test "script fails when a platform copy is missing" {
  WORK=$(mktemp -d)
  cp -R "$BATS_TEST_DIRNAME/../.." "$WORK/repo"
  rm "$WORK/repo/android/.claude/helpers/hook-handler.cjs"
  run "$WORK/repo/scripts/verify-hook-safety.sh"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "Missing" ]]
  rm -rf "$WORK"
}

# ── timeout behavior ─────────────────────────────────────────────────────────

@test "self-test-timeout completes within 5 seconds" {
  start="$SECONDS"
  run node "$CANONICAL" self-test-timeout
  elapsed=$(( SECONDS - start ))
  [ "$elapsed" -le 5 ]
}

@test "self-test-timeout returns approve decision" {
  run node "$CANONICAL" self-test-timeout
  [[ "$output" == *'"decision":"approve"'* ]]
}
