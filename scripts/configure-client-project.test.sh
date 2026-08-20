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
cleanup() { rm -rf "$TMP" "$TMP2" "$SCRIPTS_SRC" "$FIX" "$W2C_FIX"; }
trap cleanup EXIT
git -C "$TMP" init -q
git -C "$TMP" config user.email test@example.com
git -C "$TMP" config user.name test

out="$(bash "$CHECK" --source-repo "$ROOT" --client-repo "$TMP" || true)"
echo "$out" | grep -q '\[DISCOVER\] default engine: w2c' || fail "expected default engine w2c"
echo "$out" | grep -q '\[MISSING\] .w2c/scripts/w2c.py' || fail "expected missing w2c.py"
echo "$out" | grep -q '\[MISSING\] .github/instructions/work-to-chores.instructions.md' || fail "expected missing w2c copilot"
echo "$out" | grep -q '\[MISSING\] .w2c/templates/' || fail "expected missing w2c templates"
pass "check reports w2c gaps and default w2c"

mkdir -p "$TMP/.gsd"
out="$(bash "$CHECK" --source-repo "$ROOT" --client-repo "$TMP" || true)"
echo "$out" | grep -q '\[DISCOVER\] default engine: gsd' || fail "expected default engine gsd"
pass "check reports default gsd when .gsd exists"

TMP2="$(mktemp -d)"
git -C "$TMP2" init -q
git -C "$TMP2" config user.email test@example.com
git -C "$TMP2" config user.name test
SCRIPTS_SRC="$(mktemp -d)"
echo '# w2c stub' > "$SCRIPTS_SRC/w2c.py"
mkdir -p "$TMP2/.w2c"
ln -s "$SCRIPTS_SRC" "$TMP2/.w2c/scripts"
out="$(bash "$CHECK" --source-repo "$ROOT" --client-repo "$TMP2" || true)"
echo "$out" | grep -q '\[OK\] .w2c/scripts/w2c.py' || fail "expected OK w2c.py via scripts symlink"
pass "check detects w2c.py when .w2c/scripts is symlink"

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

W2C_FIX="$(mktemp -d)"
git -C "$W2C_FIX" init -q
git -C "$W2C_FIX" config user.email test@example.com
git -C "$W2C_FIX" config user.name test
w2c_out="$(bash "$ORCH" --source-repo "$ROOT" --client-repo "$W2C_FIX" --platform universal --engine w2c 2>&1)"
echo "$w2c_out" | grep -q 'bootstrap GSD' && fail "w2c overlay warned to bootstrap GSD"
grep -q 'work-to-chores' "$W2C_FIX/AGENTS.md" || fail "w2c planning text missing"
[[ -L "$W2C_FIX/.w2c/scripts" ]] || fail ".w2c/scripts should be symlink"
[[ -L "$W2C_FIX/.w2c/templates" ]] || fail ".w2c/templates should be symlink"
[[ -f "$W2C_FIX/.w2c/STATE.md" && ! -L "$W2C_FIX/.w2c/STATE.md" ]] || fail "STATE.md should be regular file"
pass "w2c symlinks scripts/templates and keeps STATE.md real"
