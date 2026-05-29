#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CANONICAL="$ROOT_DIR/.claude/helpers/hook-handler.cjs"
PLATFORMS=(universal ios android flutter-bloc flutter-riverpod)

die() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

assert_json_decision() {
  local command="$1"
  local output
  output="$(node "$CANONICAL" "$command" 2>/dev/null || true)"
  [[ "$output" == *'"decision":"approve"'* || "$output" == *'"decision":"block"'* ]] \
    || die "Hook command '$command' did not return a valid decision JSON payload"
}

printf 'Verifying hook-handler sync...\n'
[[ -f "$CANONICAL" ]] || die "Missing canonical hook handler: $CANONICAL"

for platform in "${PLATFORMS[@]}"; do
  target="$ROOT_DIR/$platform/.claude/helpers/hook-handler.cjs"
  [[ -f "$target" ]] || die "Missing $platform hook handler: $target"
  cmp -s "$CANONICAL" "$target" || die "Drift detected in $target"
done
printf '  OK: all platform copies are in sync.\n'

printf 'Verifying hook decision contract...\n'
assert_json_decision pre-edit
assert_json_decision post-edit
assert_json_decision session-restore
assert_json_decision session-end
printf '  OK: core commands emit valid decision JSON.\n'

printf 'Verifying timeout fail-open behavior...\n'
SECONDS=0
timeout_output="$(node "$CANONICAL" self-test-timeout 2>/dev/null || true)"
elapsed="$SECONDS"
[[ "$timeout_output" == *'"decision":"approve"'* ]] \
  || die "Timeout self-test did not fail-open with approve decision"
[[ "$elapsed" -le 5 ]] || die "Timeout self-test exceeded expected duration (${elapsed}s)"
printf '  OK: timeout path fail-open verified in %ss.\n' "$elapsed"

printf 'Hook safety verification passed.\n'
