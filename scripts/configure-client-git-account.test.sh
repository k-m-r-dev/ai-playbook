#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$ROOT/scripts/configure-client-git-account.sh"
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "$1"; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
git -C "$TMP" init -q
git -C "$TMP" config user.email test@example.com

out="$(bash "$SCRIPT" --client-repo "$TMP" --check 2>&1)"
echo "$out" | grep -q '\[MISSING\] gh account' || fail "expected MISSING"
pass "check MISSING"

if command -v gh >/dev/null 2>&1; then
  GH_USER="$(gh auth status -h github.com 2>&1 | sed -n 's/.* account \([^ (]*\).*/\1/p' | head -1 || true)"
  if [[ -n "$GH_USER" ]]; then
    bash "$SCRIPT" --client-repo "$TMP" --gh-user "$GH_USER" >/dev/null
    grep -q 'BEGIN ai-playbook:gh-account' "$TMP/.envrc" || fail "missing marker"
    out="$(bash "$SCRIPT" --client-repo "$TMP" --check 2>&1)"
    echo "$out" | grep -q '\[OK\] gh account' || fail "expected OK"
    pass "write and OK check for $GH_USER"
  else
    pass "write skipped (no gh login)"
  fi
else
  pass "write skipped (no gh)"
fi
