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

# Existing client direnv + .envrc.local (fieldnation-style) must count as OK.
mkdir -p "$TMP/existing"
git -C "$TMP/existing" init -q
cat > "$TMP/existing/.envrc" <<'EOF'
# client direnv
source_env_if_exists .envrc.local
dotenv_if_exists .env
EOF
printf 'export GH_TOKEN="$(gh auth token -u kmrfn)"\n' > "$TMP/existing/.envrc.local"
out="$(bash "$SCRIPT" --client-repo "$TMP/existing" --check 2>&1)"
echo "$out" | grep -q '\[OK\] gh account (.envrc.local user=kmrfn)' || fail "expected OK for .envrc.local pattern: $out"
pass "check OK for sourced .envrc.local"

# .envrc.local alone without source line is MISSING.
mkdir -p "$TMP/orphan"
git -C "$TMP/orphan" init -q
printf 'export GH_TOKEN="$(gh auth token -u kmrfn)"\n' > "$TMP/orphan/.envrc.local"
printf 'dotenv_if_exists .env\n' > "$TMP/orphan/.envrc"
out="$(bash "$SCRIPT" --client-repo "$TMP/orphan" --check 2>&1)"
echo "$out" | grep -q '\[MISSING\] gh account' || fail "expected MISSING when .envrc does not source local"
pass "check MISSING when local not sourced"

if command -v gh >/dev/null 2>&1; then
  GH_USER="$(gh auth status -h github.com 2>&1 | sed -n 's/.* account \([^ (]*\).*/\1/p' | head -1 || true)"
  if [[ -n "$GH_USER" ]]; then
    bash "$SCRIPT" --client-repo "$TMP" --gh-user "$GH_USER" >/dev/null
    grep -q 'BEGIN ai-playbook:gh-account' "$TMP/.envrc" || fail "missing marker"
    out="$(bash "$SCRIPT" --client-repo "$TMP" --check 2>&1)"
    echo "$out" | grep -q '\[OK\] gh account' || fail "expected OK"
    pass "write and OK check for $GH_USER (greenfield .envrc)"

    # Existing .envrc without markers → write .envrc.local, preserve client .envrc
    mkdir -p "$TMP/merge"
    git -C "$TMP/merge" init -q
    cat > "$TMP/merge/.envrc" <<'EOF'
# keep me
dotenv_if_exists .env
EOF
    bash "$SCRIPT" --client-repo "$TMP/merge" --gh-user "$GH_USER" >/dev/null
    grep -q 'dotenv_if_exists .env' "$TMP/merge/.envrc" || fail "client .envrc should be preserved"
    grep -q 'source_env_if_exists .envrc.local' "$TMP/merge/.envrc" || fail "should add source_env_if_exists"
    grep -q 'BEGIN ai-playbook:gh-account' "$TMP/merge/.envrc.local" || fail "block should land in .envrc.local"
    grep -q "gh auth token -u $GH_USER" "$TMP/merge/.envrc.local" || fail "local missing user"
    ! grep -q 'BEGIN ai-playbook:gh-account' "$TMP/merge/.envrc" || fail "should not put markers in existing .envrc"
    out="$(bash "$SCRIPT" --client-repo "$TMP/merge" --check 2>&1)"
    echo "$out" | grep -q '\[OK\] gh account (.envrc.local' || fail "expected OK via .envrc.local: $out"
    pass "write prefers .envrc.local when .envrc exists"
  else
    pass "write skipped (no gh login)"
  fi
else
  pass "write skipped (no gh)"
fi
