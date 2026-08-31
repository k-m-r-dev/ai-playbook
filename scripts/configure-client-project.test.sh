#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHECK="$ROOT/scripts/configure-client-check.sh"
ORCH="$ROOT/scripts/configure-client-project.sh"
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "$1"; }

TMP="$(mktemp -d)"
TMP2=""
SCRIPTS_SRC=""
FIX=""
W2C_FIX=""
W2C_TRACK=""
W2C_TEST_HOME="$(mktemp -d)"
export W2C_CONFIG="$W2C_TEST_HOME/config.toml"
export W2C_DATA_HOME="$W2C_TEST_HOME/data"
cleanup() { rm -rf "$TMP" "$TMP2" "$SCRIPTS_SRC" "$FIX" "$W2C_FIX" "$W2C_TRACK" "$W2C_TEST_HOME"; }
trap cleanup EXIT
git -C "$TMP" init -q
git -C "$TMP" config user.email test@example.com
git -C "$TMP" config user.name test

CHECK_PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin"
out="$(PATH="$CHECK_PATH" bash "$CHECK" --source-repo "$ROOT" --client-repo "$TMP" || true)"
echo "$out" | grep -q '\[DISCOVER\] default engine: w2c' || fail "expected default engine w2c"
echo "$out" | grep -q '\[MISSING\] w2c CLI on PATH' || fail "expected missing w2c CLI"
echo "$out" | grep -q '\[MISSING\] .w2c/STATE.md' || fail "expected missing STATE.md"
echo "$out" | grep -q '\[MISSING\] .github/instructions/work-to-chores.instructions.md' || fail "expected missing w2c copilot"
echo "$out" | grep -q '\[MISSING\] gh account' || fail "expected missing gh account"
pass "check reports w2c gaps and default w2c"

mkdir -p "$TMP/.gsd"
out="$(bash "$CHECK" --source-repo "$ROOT" --client-repo "$TMP" || true)"
echo "$out" | grep -q '\[DISCOVER\] default engine: gsd' || fail "expected default engine gsd"
pass "check reports default gsd when .gsd exists"

TMP2="$(mktemp -d)"
git -C "$TMP2" init -q
git -C "$TMP2" config user.email test@example.com
git -C "$TMP2" config user.name test
mkdir -p "$TMP2/.w2c"
echo '# state' > "$TMP2/.w2c/STATE.md"
out="$(PATH="$CHECK_PATH" bash "$CHECK" --source-repo "$ROOT" --client-repo "$TMP2" || true)"
echo "$out" | grep -q '\[OK\] .w2c/STATE.md' || fail "expected OK STATE.md"
pass "check detects STATE.md ledger"

for f in flutter-riverpod/_AGENTS.md flutter-bloc/_AGENTS.md ios/_AGENTS.md android/_AGENTS.md universal/_AGENTS.md; do
  if grep -E 'gsd-plan-milestone|do-next-runner|GSD prerequisite|openGSD|\bGSD\b|GSD-Pi|\.gsd/' "$ROOT/$f"; then
    fail "GSD still in $f"
  fi
done
pass "_AGENTS.md packs have no GSD workflow rows"

for skill in do-next do-next-runner gsd-advance-unit gsd-plan-milestone; do
  for overlay in universal ios android flutter-riverpod flutter-bloc; do
    [[ ! -e "$ROOT/$overlay/.cursor/skills/$skill" ]] || fail "GSD skill still in $overlay/.cursor/skills/$skill"
  done
  if grep -q "\"$skill\"" "$ROOT/universal/skills-lock.json"; then
    fail "GSD skill $skill still in universal/skills-lock.json"
  fi
done
pass "overlay cursor skills and universal lock have no GSD entries"

for f in flutter-riverpod/_CLAUDE.md flutter-bloc/_CLAUDE.md ios/_CLAUDE.md android/_CLAUDE.md universal/_CLAUDE.md; do
  if grep -E '## graphify|openGSD|gsd-workflow MCP' "$ROOT/$f"; then
    fail "engine required in $f"
  fi
done
if grep -E 'Furqan|LIBRARY_MANIFEST|gsd-pi-cursor|openGSD' "$ROOT/flutter-riverpod/AGENTS.md"; then
  fail "contaminated flutter-riverpod/AGENTS.md"
fi
for f in flutter-riverpod/CLAUDE.md flutter-bloc/CLAUDE.md ios/CLAUDE.md android/CLAUDE.md universal/CLAUDE.md; do
  if grep -E 'GSD-Pi|openGSD|graphify-out|ruflo' "$ROOT/$f"; then
    fail "engine ledger still in $f"
  fi
done
pass "overlay wrappers and _CLAUDE.md are engine-agnostic"

if bash "$ORCH" --source-repo "$ROOT" --client-repo "$TMP" --platform universal --engine nope 2>/dev/null; then
  fail "invalid engine should exit 1"
fi
pass "invalid engine exits 1"

if bash "$ORCH" --source-repo "$ROOT" --client-repo "$TMP" --platform universal --engine w2c --init-gsd 2>/dev/null; then
  fail "w2c+init-gsd should exit 1"
fi
pass "w2c rejects GSD flags"

before="$(find "$TMP" -type f | wc -l | tr -d ' ')"
dry="$(bash "$ORCH" --source-repo "$ROOT" --client-repo "$TMP" --platform universal --engine w2c --dry-run 2>&1)"
after="$(find "$TMP" -type f | wc -l | tr -d ' ')"
[[ "$before" == "$after" ]] || fail "dry-run wrote files"
[[ ! -d "$TMP/.w2c" ]] || fail "dry-run created .w2c"
echo "$dry" | grep -q -- '--no-require-gsd' || fail "w2c dry-run missing --no-require-gsd"
pass "dry-run w2c writes nothing"

bash "$ORCH" --source-repo "$ROOT" --client-repo "$TMP" --platform universal --engine none --check >/dev/null
[[ ! -f "$TMP/_AGENTS.md" ]] || fail "--check installed overlay"
pass "--check is read-only"

FIX="$(mktemp -d)"
git -C "$FIX" init -q
git -C "$FIX" config user.email test@example.com
git -C "$FIX" config user.name test
bash "$ORCH" --source-repo "$ROOT" --client-repo "$FIX" --platform universal --engine none >/dev/null
grep -q 'BEGIN PLAYBOOK:PLANNING-ENGINE' "$FIX/AGENTS.md" || fail "missing planning marker"
grep -q 'No GSD and no W2C' "$FIX/AGENTS.md" || fail "none engine retained text missing"
grep -q 'Do not scaffold' "$FIX/AGENTS.md" || fail "none engine text missing"
[[ ! -d "$FIX/.gsd" ]] || fail "none created .gsd"
[[ ! -d "$FIX/.w2c" ]] || fail "none created .w2c"
c1="$(grep -c 'BEGIN PLAYBOOK:PLANNING-ENGINE' "$FIX/AGENTS.md")"
bash "$ORCH" --source-repo "$ROOT" --client-repo "$FIX" --platform universal --engine none >/dev/null
grep -q 'No GSD and no W2C' "$FIX/AGENTS.md" || fail "none engine retained text missing after rerun"
c2="$(grep -c 'BEGIN PLAYBOOK:PLANNING-ENGINE' "$FIX/AGENTS.md")"
[[ "$c1" == 1 && "$c2" == 1 ]] || fail "planning marker not idempotent"
pass "engine none overlay + idempotent wrapper"

W2C_REPO="$(cd "$ROOT/../w2c" && pwd)"
[[ -f "$W2C_REPO/src/w2c/cli.py" ]] || fail "sibling w2c checkout required at $ROOT/../w2c"
W2C_BIN="$W2C_TEST_HOME/bin"
mkdir -p "$W2C_BIN"
cat > "$W2C_BIN/w2c" <<EOF
#!/usr/bin/env bash
export PYTHONPATH="$W2C_REPO/src"
exec python3 -m w2c "\$@"
EOF
chmod +x "$W2C_BIN/w2c"
export PATH="$W2C_BIN:$PATH"
command -v w2c >/dev/null || fail "w2c shim not on PATH"

W2C_FIX="$(mktemp -d)"
git -C "$W2C_FIX" init -q
git -C "$W2C_FIX" config user.email test@example.com
git -C "$W2C_FIX" config user.name test
w2c_out="$(bash "$ORCH" --source-repo "$ROOT" --client-repo "$W2C_FIX" --platform universal --engine w2c 2>&1)"
echo "$w2c_out" | grep -q 'bootstrap GSD' && fail "w2c overlay warned to bootstrap GSD"
grep -q 'work-to-chores' "$W2C_FIX/AGENTS.md" || fail "w2c planning text missing"
grep -q 'Python CLI' "$W2C_FIX/AGENTS.md" || fail "wrapper should mention Python CLI"
[[ ! -e "$W2C_FIX/.w2c/scripts" ]] || fail ".w2c/scripts should not be installed"
[[ ! -e "$W2C_FIX/.w2c/templates" ]] || fail ".w2c/templates should not be installed"
[[ -f "$W2C_FIX/.w2c/STATE.md" && ! -L "$W2C_FIX/.w2c/STATE.md" ]] || fail "STATE.md should be regular file"
[[ -f "$W2C_FIX/.w2c/config.toml" ]] || fail "missing .w2c/config.toml"
git -C "$W2C_FIX" check-ignore -q .w2c/STATE.md || fail "STATE.md should be gitignored"
grep -Fqx '.github/instructions/work-to-chores.instructions.md' "$W2C_FIX/.gitignore" || fail "copilot instructions should be gitignored"
pass "w2c inits ledger, gitignores by default, no playbook symlink"

W2C_TRACK="$(mktemp -d)"
git -C "$W2C_TRACK" init -q
git -C "$W2C_TRACK" config user.email test@example.com
git -C "$W2C_TRACK" config user.name test
bash "$ORCH" --source-repo "$ROOT" --client-repo "$W2C_TRACK" --platform universal --engine w2c --track >/dev/null
git -C "$W2C_TRACK" check-ignore -q .w2c/STATE.md && fail "--track should not ignore STATE.md"
mkdir -p "$W2C_TRACK/.w2c/runtime"
echo x > "$W2C_TRACK/.w2c/runtime/events.jsonl"
git -C "$W2C_TRACK" check-ignore -q .w2c/runtime/events.jsonl || fail "runtime still ignored with --track"
grep -q 'track = true' "$W2C_TRACK/.w2c/config.toml" || fail "track true missing"
pass "w2c --track keeps ledger committable and runtime ignored"

CLI_HOME="$(mktemp -d)"
install_out="$(HOME="$CLI_HOME" XDG_CONFIG_HOME="$CLI_HOME/.config" XDG_DATA_HOME="$CLI_HOME/.local/share" W2C_BIN_DIR="$CLI_HOME/.local/bin" env -u W2C_DATA_HOME -u W2C_CONFIG bash "$W2C_REPO/install.sh" --skip-skills --force 2>&1)" || true
[[ -x "$CLI_HOME/.local/bin/w2c" ]] || fail "CLI shim missing: $install_out"
help_out="$("$CLI_HOME/.local/bin/w2c" --help 2>&1)" || true
echo "$help_out" | grep -q migrate || fail "w2c help missing migrate"
[[ -d "$CLI_HOME/.local/share/w2c/src" ]] || fail "payload src missing"
[[ -d "$CLI_HOME/.local/share/w2c/templates" ]] || fail "payload templates missing"
[[ ! -L "$CLI_HOME/.local/share/w2c/src" ]] || fail "payload src should be a copy"
rm -rf "$CLI_HOME"
pass "OpenW2C install.sh copies payload and writes PATH shim"

GIT_TMP="$(mktemp -d)"
git -C "$GIT_TMP" init -q
git -C "$GIT_TMP" config user.email test@example.com
git -C "$GIT_TMP" config user.name test
out="$(bash "$ROOT/scripts/configure-client-git-account.sh" --client-repo "$GIT_TMP" --check 2>&1)"
echo "$out" | grep -q '\[MISSING\] gh account' || fail "git-account check expected MISSING"
pass "git-account check reports MISSING"

if command -v gh >/dev/null 2>&1; then
  GH_USER="$(gh auth status -h github.com 2>&1 | sed -n 's/.* account \([^ (]*\).*/\1/p' | head -1 || true)"
  if [[ -n "$GH_USER" ]]; then
    bash "$ROOT/scripts/configure-client-git-account.sh" --client-repo "$GIT_TMP" --gh-user "$GH_USER" >/dev/null
    grep -q 'BEGIN ai-playbook:gh-account' "$GIT_TMP/.envrc" || fail "envrc missing marker"
    grep -q "gh auth token -u $GH_USER" "$GIT_TMP/.envrc" || fail "envrc missing gh user"
    out="$(bash "$ROOT/scripts/configure-client-git-account.sh" --client-repo "$GIT_TMP" --check 2>&1)"
    echo "$out" | grep -q '\[OK\] gh account' || fail "git-account check expected OK"
    pass "git-account writes and verifies .envrc"
  else
    pass "git-account write test skipped (no gh login)"
  fi
else
  pass "git-account write test skipped (no gh CLI)"
fi
rm -rf "$GIT_TMP"
