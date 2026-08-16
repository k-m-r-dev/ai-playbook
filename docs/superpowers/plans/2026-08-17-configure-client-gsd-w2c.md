# Configure Client GSD/W2C/None Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add exclusive planning-engine configure (`gsd` | `w2c` | `none`) via `scripts/configure-client-project.sh`, keep overlay `_AGENTS.md`/`_CLAUDE.md` architecture-only, and make the configure skill a thin interviewer that calls that CLI.

**Architecture:** Skill interviews (one question at a time) then runs a single orchestrator. The orchestrator installs overlay, then GSD bootstrap **or** W2C install **or** neither, then patches committed wrappers with `<!-- BEGIN PLAYBOOK:PLANNING-ENGINE -->` markers. `configure-client-check.sh` stays read-only and reports overlay + GSD + W2C gaps.

**Tech Stack:** bash, python3 (W2C installer + wrapper marker patch), existing `install-client-ai-overlay.sh` / `bootstrap-gsd-workflow.sh` / `install-w2c-to-project.sh`.

**Spec:** `docs/superpowers/specs/2026-08-17-configure-client-gsd-w2c-design.md`

## Global Constraints

- Engine is exclusive: `gsd` | `w2c` | `none`. Never both.
- Overlay `_AGENTS.md` / `_CLAUDE.md` stay architecture-only (no GSD skill tables, bootstrap gates, graphify, ruflo, openGSD).
- Engine text lives only in committed `AGENTS.md` / `CLAUDE.md`.
- `--engine w2c` runs full `install-w2c-to-project.sh` with `--mode symlink` by default: directory-symlink `.w2c/scripts` and `.w2c/templates` to playbook `shared/w2c/{scripts,templates}`. Ledger files stay real. `--mode copy` copies those dirs. Gitignore scripts + templates + runtime.
- Default engine: `w2c` if client has no `.gsd/`; `gsd` if `.gsd/` exists.
- GSD flags (`--init-gsd`, `--with-do-next`, `--patch-mcp`, `--harness-context`, `--force`) with `--engine w2c` or `none` exit 1.
- Skill copies stay byte-identical: `.cursor/skills/configure-client-project/` and `shared/gsd/skills/configure-client-project/`.
- Do not re-run configure on `bitoron_mobile` in this plan.
- Do not add a new CI test runner; tests are `bash scripts/configure-client-project.test.sh`.
- Frequent commits are in the plan; skip git commit steps if the user has not asked to commit.

## File map

| File | Responsibility |
| --- | --- |
| `scripts/configure-client-check.sh` | Read-only gaps: overlay, GSD, W2C, default-engine discover |
| `scripts/configure-client-project.sh` | Orchestrator: validate, overlay, engine installer, wrapper patch |
| `scripts/configure-client-project.test.sh` | Direct bash tests for check + orchestrator |
| `universal/_AGENTS.md`, `ios/_AGENTS.md`, `android/_AGENTS.md`, `flutter-riverpod/_AGENTS.md`, `flutter-bloc/_AGENTS.md` | Architecture-only policy (symlink SoT) |
| `universal/_CLAUDE.md`, `ios/_CLAUDE.md`, `android/_CLAUDE.md`, `flutter-riverpod/_CLAUDE.md`, `flutter-bloc/_CLAUDE.md` | Architecture-only entry (no graphify/GSD required) |
| `*/AGENTS.md`, `*/CLAUDE.md` (copied wrappers) | Generic stubs; flutter-riverpod AGENTS.md must drop Furqan/GSD facts |
| `shared/gsd/skills/configure-client-project/SKILL.md` + `USAGE.md` | Operator interview (SoT) |
| `.cursor/skills/configure-client-project/SKILL.md` + `USAGE.md` | Byte-copy of SoT |
| `FRAMEWORK.md`, `README.md`, `shared/gsd/README.md` | Operator docs mention `--engine` |

---

### Task 1: Check script W2C probes + default engine

**Files:**
- Modify: `scripts/configure-client-check.sh`
- Create: `scripts/configure-client-project.test.sh`

**Interfaces:**
- Consumes: existing `status()` / `DISCOVER` lines
- Produces: `[DISCOVER] default engine: gsd|w2c`, `[OK]/[MISSING] .w2c/scripts/w2c.py`, `[OK]/[MISSING] .github/instructions/work-to-chores.instructions.md`

- [ ] **Step 1: Write the failing test**

Create `scripts/configure-client-project.test.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHECK="$ROOT/scripts/configure-client-check.sh"
ORCH="$ROOT/scripts/configure-client-project.sh"
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "$1"; }

TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT
git -C "$TMP" init -q
git -C "$TMP" config user.email test@example.com
git -C "$TMP" config user.name test

out="$(bash "$CHECK" --source-repo "$ROOT" --client-repo "$TMP" || true)"
echo "$out" | grep -q '\[DISCOVER\] default engine: w2c' || fail "expected default engine w2c"
echo "$out" | grep -q '\[MISSING\] .w2c/scripts/w2c.py' || fail "expected missing w2c.py"
echo "$out" | grep -q '\[MISSING\] .github/instructions/work-to-chores.instructions.md' || fail "expected missing w2c copilot"
pass "check reports w2c gaps and default w2c"

mkdir -p "$TMP/.gsd"
out="$(bash "$CHECK" --source-repo "$ROOT" --client-repo "$TMP" || true)"
echo "$out" | grep -q '\[DISCOVER\] default engine: gsd' || fail "expected default engine gsd"
pass "check reports default gsd when .gsd exists"
```

chmod +x the file.

- [ ] **Step 2: Run test to verify it fails**

Run: `bash scripts/configure-client-project.test.sh`

Expected: FAIL with `expected default engine w2c` (check script has no such line yet).

- [ ] **Step 3: Implement check probes**

In `scripts/configure-client-check.sh`, after the default-branch DISCOVER block (after `status "DISCOVER" "default branch: $branch"`), add:

```bash
if [[ -d "$CLIENT_REPO/.gsd" ]]; then
  status "DISCOVER" "default engine: gsd"
else
  status "DISCOVER" "default engine: w2c"
fi
```

After the do-next health block (before bootstrap `--check` delegate), add:

```bash
# ── W2C ─────────────────────────────────────────────────────────────────────
if [[ -f "$CLIENT_REPO/.w2c/scripts/w2c.py" ]]; then
  status "OK" ".w2c/scripts/w2c.py"
else
  status "MISSING" ".w2c/scripts/w2c.py"
fi

if [[ -f "$CLIENT_REPO/.github/instructions/work-to-chores.instructions.md" ]]; then
  status "OK" ".github/instructions/work-to-chores.instructions.md"
else
  status "MISSING" ".github/instructions/work-to-chores.instructions.md"
fi
```

- [ ] **Step 4: Run test to verify check assertions pass**

Run: `bash scripts/configure-client-project.test.sh`

Expected: PASS for the two check cases. Later orchestrator assertions are not in this file yet.

- [ ] **Step 5: Commit** (only if the user asked)

```bash
git add scripts/configure-client-check.sh scripts/configure-client-project.test.sh
git commit -m "$(cat <<'EOF'
Add W2C probes and default-engine discover to configure-client-check.

EOF
)"
```

---

### Task 2: Strip GSD from platform `_AGENTS.md`

**Files:**
- Modify: `flutter-riverpod/_AGENTS.md`, `flutter-bloc/_AGENTS.md`, `ios/_AGENTS.md`, `android/_AGENTS.md`, `universal/_AGENTS.md`

**Interfaces:**
- Consumes: current Skills tables
- Produces: architecture/platform skills only; no `gsd-plan-milestone` / `do-next` rows; no GSD prerequisite paragraph

- [ ] **Step 1: Write failing overlay grep into the test file**

Append to `scripts/configure-client-project.test.sh` (before TMP git tests is fine, or after):

```bash
for f in flutter-riverpod/_AGENTS.md flutter-bloc/_AGENTS.md ios/_AGENTS.md android/_AGENTS.md universal/_AGENTS.md; do
  if grep -E 'gsd-plan-milestone|do-next-runner|GSD prerequisite|openGSD' "$ROOT/$f"; then
    fail "GSD still in $f"
  fi
done
pass "_AGENTS.md packs have no GSD workflow rows"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash scripts/configure-client-project.test.sh`

Expected: FAIL with `GSD still in flutter-riverpod/_AGENTS.md`.

- [ ] **Step 3: Edit each `_AGENTS.md`**

**flutter-riverpod/_AGENTS.md** and **flutter-bloc/_AGENTS.md**: delete the four GSD/do-next table rows and the `**GSD prerequisite:**` paragraph. Keep the Flutter skill rows through `session-progress-workflow`.

**ios/_AGENTS.md** and **android/_AGENTS.md**: same — delete the four GSD/do-next rows and the GSD prerequisite paragraph. Keep platform skills through `session-progress-workflow`.

**universal/_AGENTS.md**: in Tool mapping, delete the three rows:

```
| GSD planning | `gsd-plan-milestone` | same | same | `gsd-plan-milestone.instructions.md` |
| GSD execution | `gsd-advance-unit`, `do-next` | same | same | `gsd-advance-unit.instructions.md`, `do-next.instructions.md` |
| Milestone auto-chain | `do-next-runner` | same | same | `do-next-runner.instructions.md` |
```

Keep `local-first-context` / `graph-navigate` skills (optional engines, not required workflow). Do not add W2C skill rows here (personal hub).

- [ ] **Step 4: Re-run tests**

Run: `bash scripts/configure-client-project.test.sh`

Expected: PASS on `_AGENTS.md` grep.

- [ ] **Step 5: Commit** (only if asked)

```bash
git add flutter-riverpod/_AGENTS.md flutter-bloc/_AGENTS.md ios/_AGENTS.md android/_AGENTS.md universal/_AGENTS.md scripts/configure-client-project.test.sh
git commit -m "$(cat <<'EOF'
Keep platform _AGENTS.md architecture-only; drop GSD skill tables.

EOF
)"
```

---

### Task 3: Strip graphify/GSD from `_CLAUDE.md` and copied wrappers

**Files:**
- Modify: `flutter-riverpod/_CLAUDE.md`, `ios/_CLAUDE.md` (if it has `## graphify`), `universal/_CLAUDE.md`
- Modify: `flutter-riverpod/AGENTS.md`, `flutter-riverpod/CLAUDE.md`, `flutter-bloc/CLAUDE.md`, `ios/CLAUDE.md`, `android/CLAUDE.md`, `universal/CLAUDE.md`
- `flutter-bloc/AGENTS.md`, `ios/AGENTS.md`, `android/AGENTS.md`, `universal/AGENTS.md` already empty Learned sections — leave them.

**Interfaces:**
- Produces: copied wrappers with stack + session scratch only; no openGSD/graphify/ruflo/GSD-Pi sections; flutter-riverpod AGENTS.md has no Furqan/Library facts

- [ ] **Step 1: Extend the test**

```bash
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
```

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL on `flutter-riverpod/_CLAUDE.md` (`## graphify`) and/or contaminated AGENTS.md.

- [ ] **Step 3: `_CLAUDE.md` edits**

**flutter-riverpod/_CLAUDE.md**: delete the entire `## graphify` section (from `## graphify` through the last graphify rule bullet). Keep Usage list. Change Usage bullet for CLAUDE.md from “environment, topography, milestones, learnings” to “environment, session scratch, learnings”.

**ios/_CLAUDE.md**: same Usage wording if present. It has no `## graphify` in the playbook file itself.

**universal/_CLAUDE.md**: in Tool routing, replace Local engines cells so GSD/graphify are not required:

```markdown
| Tool | Primary config | Local engines |
|------|----------------|---------------|
| Claude Code | `.claude/settings.json`, `.mcp.json`, hooks | optional; none required |
| Cursor | `.cursor/rules/`, `.cursor/mcp.json` | optional; none required |
| VS Code Copilot | `.github/copilot-instructions.md`, `.github/instructions/` | optional; none required |
```

- [ ] **Step 4: Replace copied `AGENTS.md` / `CLAUDE.md` templates**

**flutter-riverpod/AGENTS.md** (entire file):

```markdown
@_AGENTS.md

## Learned User Preferences

## Learned Workspace Facts
```

**flutter-riverpod/CLAUDE.md** and **flutter-bloc/CLAUDE.md** (stack-specific; BLoC file uses BLoC not Riverpod):

```markdown
@_CLAUDE.md

---

## Project Environment & Architecture Context

- **Primary stack**: Flutter / Dart / Riverpod / GetIt-Injectable
- **Project type**: mobile
- **Build**: `flutter build apk --debug` / `flutter build ios --debug --no-codesign`
- **Test**: `flutter test`
- **Lint/format**: `flutter analyze`

## Session scratch (optional — prefer `.workflow/`)

For active work, use `.workflow/current_session_progress.md` per `SESSION_WORKFLOW.md`.
```

For `flutter-bloc/CLAUDE.md` use `Flutter / Dart / BLoC / GetIt-Injectable`.

**ios/CLAUDE.md**: same shape, stack `Swift / native iOS`, build/test/lint placeholders `xcodebuild` (keep `[e.g. …]` if scheme is unknown).

**android/CLAUDE.md**: stack `Kotlin / native Android`, build `./gradlew assembleDebug`, test `./gradlew testDebugUnitTest`, lint `./gradlew lint`.

**universal/CLAUDE.md**: stack/type placeholders remain `[e.g. …]` but drop Optimization baseline, Topography, GSD-Pi, ruflo sections. Keep Session scratch.

**ios/CLAUDE.md**: also delete the trailing `## graphify` block if present in the committed wrapper.

- [ ] **Step 5: Re-run tests**

Expected: PASS overlay grep assertions.

- [ ] **Step 6: Commit** (only if asked)

```bash
git add flutter-riverpod/_CLAUDE.md flutter-riverpod/AGENTS.md flutter-riverpod/CLAUDE.md \
  flutter-bloc/CLAUDE.md ios/CLAUDE.md android/CLAUDE.md universal/CLAUDE.md universal/_CLAUDE.md \
  scripts/configure-client-project.test.sh
git commit -m "$(cat <<'EOF'
Make overlay Claude/AGENTS wrappers engine-agnostic.

EOF
)"
```

---

### Task 4: Orchestrator CLI (validate, dry-run, check, wrapper patch, installers)

**Files:**
- Create: `scripts/configure-client-project.sh`
- Modify: `scripts/configure-client-project.test.sh`
- Modify: `scripts/install-w2c-to-project.sh` (`--mode symlink|copy`; symlink both `scripts` and `templates` dirs; gitignore them)

**Interfaces:**
- Consumes: `--source-repo`, `--client-repo`, `--platform`, `--engine gsd|w2c|none`, `--mode` (default `symlink`), `--existing-policy` (default `merge`), `--check`, `--dry-run`, GSD flags
- Produces: exit 0/1; wrapper markers in client `AGENTS.md`/`CLAUDE.md`; calls overlay / bootstrap / w2c installers

- [ ] **Step 1: Append orchestrator tests**

```bash
# invalid engine
if bash "$ORCH" --source-repo "$ROOT" --client-repo "$TMP" --platform universal --engine nope 2>/dev/null; then
  fail "invalid engine should exit 1"
fi
pass "invalid engine exits 1"

# GSD flags with w2c
if bash "$ORCH" --source-repo "$ROOT" --client-repo "$TMP" --platform universal --engine w2c --init-gsd 2>/dev/null; then
  fail "w2c+init-gsd should exit 1"
fi
pass "w2c rejects GSD flags"

# dry-run w2c writes nothing
before="$(find "$TMP" -type f | wc -l)"
bash "$ORCH" --source-repo "$ROOT" --client-repo "$TMP" --platform universal --engine w2c --dry-run
after="$(find "$TMP" -type f | wc -l)"
[[ "$before" == "$after" ]] || fail "dry-run wrote files"
[[ ! -d "$TMP/.w2c" ]] || fail "dry-run created .w2c"
pass "dry-run w2c writes nothing"

# --check is read-only
bash "$ORCH" --source-repo "$ROOT" --client-repo "$TMP" --platform universal --engine none --check >/dev/null
[[ ! -f "$TMP/_AGENTS.md" ]] || fail "--check installed overlay"
pass "--check is read-only"
```

Keep these tests **above** any real overlay install (slow). After orchestrator exists, add a fixture test that does not need full overlay: unit-test wrapper patch via a function, **or** run `--engine none` against a mini client that already has stub `AGENTS.md`/`CLAUDE.md` if overlay is too heavy.

Add a wrapper-only fixture (no overlay) by extracting patch into the orchestrator so `--engine none --skip-overlay` is **not** in the spec. Instead: after `--dry-run` tests, create a tiny git repo with `AGENTS.md`/`CLAUDE.md` stubs and run a sourced helper.

Simplest spec-faithful path: implement overlay in the orchestrator always; for wrapper idempotency, after a real `--engine none` run on a temp git repo **if** overlay install works in the environment. If overlay is too slow, test `patch_planning_engine` by sourcing:

The orchestrator MUST define `patch_planning_engine "$client" "$engine"` so tests can:

```bash
# shellcheck disable=SC1091
# Do not source the whole script (it parses argv). Duplicate is forbidden.
# Instead the orchestrator accepts --patch-wrappers-only for tests? Spec does not.
# Use a temp git repo + --engine none which runs overlay then patch.
```

For this repo, overlay install **does** work. Add:

```bash
FIX="$(mktemp -d)"
git -C "$FIX" init -q
git -C "$FIX" config user.email test@example.com
git -C "$FIX" config user.name test
printf 'name: t\n' > "$FIX/pubspec.yaml"  # optional
bash "$ORCH" --source-repo "$ROOT" --client-repo "$FIX" --platform flutter-riverpod --engine none
grep -q 'BEGIN PLAYBOOK:PLANNING-ENGINE' "$FIX/AGENTS.md" || fail "missing planning marker"
grep -q 'Do not scaffold' "$FIX/AGENTS.md" || fail "none engine text missing"
[[ ! -d "$FIX/.gsd" ]] || fail "none created .gsd"
[[ ! -d "$FIX/.w2c" ]] || fail "none created .w2c"
c1="$(grep -c 'BEGIN PLAYBOOK:PLANNING-ENGINE' "$FIX/AGENTS.md")"
bash "$ORCH" --source-repo "$ROOT" --client-repo "$FIX" --platform flutter-riverpod --engine none
c2="$(grep -c 'BEGIN PLAYBOOK:PLANNING-ENGINE' "$FIX/AGENTS.md")"
[[ "$c1" == 1 && "$c2" == 1 ]] || fail "planning marker not idempotent"
rm -rf "$FIX"
pass "engine none overlay + idempotent wrapper"
```

- [ ] **Step 2: Run tests — expect FAIL** (orchestrator missing)

Expected: `No such file or directory` for `configure-client-project.sh`.

- [ ] **Step 3: Write `scripts/configure-client-project.sh`**

Full file:

```bash
#!/usr/bin/env bash
# Orchestrate client overlay + exclusive planning engine (gsd | w2c | none).
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  configure-client-project.sh \\
    --source-repo PATH \\
    --client-repo PATH \\
    --platform PLATFORM \\
    --engine gsd|w2c|none \\
    [--mode symlink] [--existing-policy merge] \\
    [--check] [--dry-run] \\
    [--init-gsd] [--with-do-next] [--patch-mcp] [--harness-context] [--force]

GSD flags are valid only with --engine gsd.
EOF
}

die() { printf 'Error: %s\n' "$1" >&2; exit 1; }
info() { printf '[configure] %s\n' "$1"; }

SOURCE_REPO=""
CLIENT_REPO=""
PLATFORM=""
ENGINE=""
MODE="symlink"
EXISTING_POLICY="merge"
CHECK=0
DRY_RUN=0
INIT_GSD=0
WITH_DO_NEXT=0
PATCH_MCP=0
HARNESS_CONTEXT=0
FORCE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-repo) SOURCE_REPO="$2"; shift 2 ;;
    --client-repo) CLIENT_REPO="$2"; shift 2 ;;
    --platform) PLATFORM="$2"; shift 2 ;;
    --engine) ENGINE="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --existing-policy) EXISTING_POLICY="$2"; shift 2 ;;
    --check) CHECK=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --init-gsd) INIT_GSD=1; shift ;;
    --with-do-next) WITH_DO_NEXT=1; shift ;;
    --patch-mcp) PATCH_MCP=1; shift ;;
    --harness-context) HARNESS_CONTEXT=1; shift ;;
    --force) FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown arg: $1" ;;
  esac
done

[[ -n "$SOURCE_REPO" ]] || die "--source-repo required"
[[ -n "$CLIENT_REPO" ]] || die "--client-repo required"
[[ -d "$SOURCE_REPO" ]] || die "source not found: $SOURCE_REPO"
[[ -d "$CLIENT_REPO" ]] || die "client not found: $CLIENT_REPO"
SOURCE_REPO="$(cd "$SOURCE_REPO" && pwd)"
CLIENT_REPO="$(cd "$CLIENT_REPO" && pwd)"

case "$ENGINE" in
  gsd|w2c|none) ;;
  *) die "--engine must be gsd, w2c, or none" ;;
esac

GSD_FLAG_SET=0
[[ "$INIT_GSD" == 1 || "$WITH_DO_NEXT" == 1 || "$PATCH_MCP" == 1 || "$HARNESS_CONTEXT" == 1 || "$FORCE" == 1 ]] && GSD_FLAG_SET=1
if [[ "$ENGINE" != gsd && "$GSD_FLAG_SET" == 1 ]]; then
  die "GSD flags are only valid with --engine gsd"
fi

case "$PLATFORM" in
  universal|ios|android|flutter-riverpod|flutter-bloc) ;;
  *) die "unknown --platform: $PLATFORM" ;;
esac

planning_block() {
  local engine="$1"
  case "$engine" in
    gsd)
      cat <<'EOF'
<!-- BEGIN PLAYBOOK:PLANNING-ENGINE -->
## Planning engine

- This repo uses **GSD** (`.gsd/`, gsd-workflow MCP).
- Do not use `.w2c/` or work-to-chores / do-chores.
<!-- END PLAYBOOK:PLANNING-ENGINE -->
EOF
      ;;
    w2c)
      cat <<'EOF'
<!-- BEGIN PLAYBOOK:PLANNING-ENGINE -->
## Planning engine

- This repo uses **work-to-chores / do-chores** (`.w2c/`).
- The Python CLI (`.w2c/scripts/w2c.py`) is the only writer of STATE/QUEUE/ROADMAP status bits and task checkboxes.
- Do not use GSD, `$gsd-plan-milestone`, or do-next.
<!-- END PLAYBOOK:PLANNING-ENGINE -->
EOF
      ;;
    none)
      cat <<'EOF'
<!-- BEGIN PLAYBOOK:PLANNING-ENGINE -->
## Planning engine

- No GSD and no W2C in this repo.
- Do not scaffold `.gsd/` or `.w2c/` unless asked.
<!-- END PLAYBOOK:PLANNING-ENGINE -->
EOF
      ;;
  esac
}

upsert_planning_engine() {
  local file="$1" engine="$2"
  [[ -f "$file" ]] || die "wrapper missing: $file"
  python3 - "$file" "$engine" <<'PY'
import re, sys
path, engine = sys.argv[1], sys.argv[2]
text = open(path, encoding="utf-8").read()
blocks = {
  "gsd": """<!-- BEGIN PLAYBOOK:PLANNING-ENGINE -->
## Planning engine

- This repo uses **GSD** (`.gsd/`, gsd-workflow MCP).
- Do not use `.w2c/` or work-to-chores / do-chores.
<!-- END PLAYBOOK:PLANNING-ENGINE -->
""",
  "w2c": """<!-- BEGIN PLAYBOOK:PLANNING-ENGINE -->
## Planning engine

- This repo uses **work-to-chores / do-chores** (`.w2c/`).
- The Python CLI (`.w2c/scripts/w2c.py`) is the only writer of STATE/QUEUE/ROADMAP status bits and task checkboxes.
- Do not use GSD, `$gsd-plan-milestone`, or do-next.
<!-- END PLAYBOOK:PLANNING-ENGINE -->
""",
  "none": """<!-- BEGIN PLAYBOOK:PLANNING-ENGINE -->
## Planning engine

- No GSD and no W2C in this repo.
- Do not scaffold `.gsd/` or `.w2c/` unless asked.
<!-- END PLAYBOOK:PLANNING-ENGINE -->
""",
}
block = blocks[engine].rstrip() + "\n"
pat = re.compile(r"<!-- BEGIN PLAYBOOK:PLANNING-ENGINE -->.*?<!-- END PLAYBOOK:PLANNING-ENGINE -->\n?", re.S)
if pat.search(text):
    text = pat.sub(block, text, count=1)
else:
    if not text.endswith("\n"):
        text += "\n"
    text += "\n" + block
# Drop known overlay-template engine bullets; keep unrelated learned facts.
bad = re.compile(
    r"^- .*\b(GSD|gsd-pi|gsd-workflow|openGSD|graphify|ruflo|Furqan|LIBRARY_MANIFEST)\b.*\n",
    re.I,
)
text = bad.sub("", text)
open(path, "w", encoding="utf-8").write(text)
PY
}

if [[ "$CHECK" == 1 ]]; then
  bash "$SOURCE_REPO/scripts/configure-client-check.sh" \
    --source-repo "$SOURCE_REPO" --client-repo "$CLIENT_REPO"
  exit 0
fi

if [[ "$DRY_RUN" == 1 ]]; then
  info "dry-run engine=$ENGINE platform=$PLATFORM client=$CLIENT_REPO"
  info "would: install-client-ai-overlay.sh --platform $PLATFORM --mode $MODE --existing-policy $EXISTING_POLICY"
  case "$ENGINE" in
    gsd) info "would: bootstrap-gsd-workflow.sh (GSD flags as passed)" ;;
    w2c) info "would: install-w2c-to-project.sh --repo $CLIENT_REPO" ;;
    none) info "would: skip GSD and W2C installers" ;;
  esac
  info "would: patch AGENTS.md and CLAUDE.md planning-engine markers"
  exit 0
fi

git -C "$CLIENT_REPO" rev-parse --git-dir >/dev/null 2>&1 || die "client is not a git repo"

bash "$SOURCE_REPO/scripts/install-client-ai-overlay.sh" \
  --source-repo "$SOURCE_REPO" \
  --client-repo "$CLIENT_REPO" \
  --platform "$PLATFORM" \
  --mode "$MODE" \
  --existing-policy "$EXISTING_POLICY"

case "$ENGINE" in
  gsd)
    args=(--source-repo "$SOURCE_REPO" --client-repo "$CLIENT_REPO" --platform "$PLATFORM" --project-style auto)
    [[ "$INIT_GSD" == 1 ]] && args+=(--init-gsd)
    [[ "$WITH_DO_NEXT" == 1 ]] && args+=(--with-do-next)
    [[ "$PATCH_MCP" == 1 ]] && args+=(--patch-mcp)
    [[ "$HARNESS_CONTEXT" == 1 ]] && args+=(--harness-context)
    [[ "$FORCE" == 1 ]] && args+=(--force)
    bash "$SOURCE_REPO/scripts/bootstrap-gsd-workflow.sh" "${args[@]}"
    ;;
  w2c)
    bash "$SOURCE_REPO/scripts/install-w2c-to-project.sh" \
      --source-repo "$SOURCE_REPO" --repo "$CLIENT_REPO" --mode "$MODE"
    ;;
  none) ;;
esac

upsert_planning_engine "$CLIENT_REPO/AGENTS.md" "$ENGINE"
upsert_planning_engine "$CLIENT_REPO/CLAUDE.md" "$ENGINE"
info "done engine=$ENGINE"
```

chmod +x.

Note: overlay install currently prints a GSD bootstrap hint to stderr. Leave it; do not change overlay in this task unless it blocks tests.

- [ ] **Step 4: Run `bash scripts/configure-client-project.test.sh`**

Expected: all PASS. If overlay install fails in sandbox, fix installer args (`--existing-policy merge`) or git identity on the fixture (already in test).

- [ ] **Step 5: Commit** (only if asked)

```bash
git add scripts/configure-client-project.sh scripts/configure-client-project.test.sh
git commit -m "$(cat <<'EOF'
Add configure-client-project.sh orchestrator for gsd, w2c, or none.

EOF
)"
```

---

### Task 5: Skill + USAGE (thin wrapper around the CLI)

**Files:**
- Modify: `shared/gsd/skills/configure-client-project/SKILL.md`
- Modify: `shared/gsd/skills/configure-client-project/USAGE.md`
- Copy those two files onto `.cursor/skills/configure-client-project/` (byte-identical)

**Interfaces:**
- Consumes: check script DISCOVER/MISSING lines; user answers
- Produces: one `configure-client-project.sh` argv after confirmation

- [ ] **Step 1: Update SKILL.md frontmatter and when-to-use**

Replace YAML `description` with:

```yaml
description: Playbook-operator skill. Configure a client repo from ai-playbook with exclusive planning engine gsd, w2c, or none — discover stack, flag gaps, confirm, then run scripts/configure-client-project.sh. Use when bringing up a client checkout from the playbook workspace.
```

Replace “When to use” bullets with overlay + optional GSD **or** W2C **or** none. Replace “When NOT to use”: inside an already-configured client, use `$gsd-plan-milestone` / `work to chores` as appropriate — not this skill.

Add `scripts/configure-client-project.sh` and `scripts/install-w2c-to-project.sh` to the Scripts table. Keep overlay/check/bootstrap/merge listed as **callees of the orchestrator**, not skill-direct writes.

- [ ] **Step 2: Rewrite Phase 2–7**

After check, print gap inventory including `w2c-scripts` and `w2c-copilot`.

Interview order (one question at a time, still):

1. Platform (unchanged options).
2. Planning engine: `gsd` / `w2c` / `none`. `[recommended]` = `w2c` if DISCOVER default engine is w2c, else `gsd`.
3. Overlay gap if MISSING.
4. If engine=gsd: existing GSD gap questions (workflow, do-next, gsd.db, MCP, delivery-profile, harness).
5. If engine=w2c: one question — full W2C install now? `[recommended]` yes.
6. If engine=none: skip GSD and W2C gap questions. Missing GSD/W2C lines are SKIPPED, not asked.
7. Confirmation lists engine + orchestrator flags + wrapper plan.
8. Execute **only**:

```bash
bash "$PLAYBOOK_ROOT/scripts/configure-client-project.sh" \\
  --source-repo "$PLAYBOOK_ROOT" \\
  --client-repo "$CLIENT_REPO" \\
  --platform "$PLATFORM" \\
  --engine gsd|w2c|none \\
  --mode symlink --existing-policy merge \\
  # GSD only: [--init-gsd] [--with-do-next] [--patch-mcp] [--harness-context] [--force]
```

Never call overlay/bootstrap/w2c directly from the skill after this lands. Never pass GSD flags with w2c/none.

9. Verify: `configure-client-project.sh --check` (or check.sh). PASS/FAIL/SKIPPED: missing GSD after w2c/none is SKIPPED.
10. Handoff: gsd → `$gsd-plan-milestone`; w2c → `work to chores`; none → overlay only.

Keep hard rules 1–10. Rule 5: flag every **in-scope** gap (engine-selected). Out-of-scope GSD gaps after w2c/none are listed as SKIPPED, not asked.

Do not pass `--interactive` to bootstrap; skill still interviews delivery profile when engine=gsd and user said yes, then Phase 5 patch of DELIVERY-PROFILE remains **or** stays inside bootstrap flags only if the skill already wrote the profile. Spec: GSD path uses existing bootstrap; keep current Phase 5 delivery-profile write **after** orchestrator if bootstrap did not get `--interactive`. Order: orchestrator first (creates `.gsd/DELIVERY-PROFILE.md` placeholder), then skill patches interviewed fields (existing Phase 5).

- [ ] **Step 3: USAGE.md**

Document terminal path:

```bash
bash scripts/configure-client-project.sh \\
  --source-repo /path/to/ai-playbook \\
  --client-repo /path/to/client \\
  --platform flutter-riverpod \\
  --engine w2c
```

Replace “After handoff, run `$gsd-plan-milestone`” with engine-specific handoff. Keep preflight `configure-client-check.sh`.

- [ ] **Step 4: Sync copies**

```bash
cp shared/gsd/skills/configure-client-project/SKILL.md .cursor/skills/configure-client-project/SKILL.md
cp shared/gsd/skills/configure-client-project/USAGE.md .cursor/skills/configure-client-project/USAGE.md
diff -q shared/gsd/skills/configure-client-project/SKILL.md .cursor/skills/configure-client-project/SKILL.md
```

Expected: no diff.

- [ ] **Step 5: Commit** (only if asked)

```bash
git add shared/gsd/skills/configure-client-project .cursor/skills/configure-client-project
git commit -m "$(cat <<'EOF'
Teach configure-client-project to pick gsd, w2c, or none via the CLI.

EOF
)"
```

---

### Task 6: Playbook docs

**Files:**
- Modify: `FRAMEWORK.md` (Install into a client repo / Bootstrap GSD bullets)
- Modify: `README.md` (GSD milestone workflow / configure paragraphs)
- Modify: `shared/gsd/README.md` (Readiness ladder + Configure client project)

- [ ] **Step 1: FRAMEWORK.md**

Where it says bootstrap GSD / `configure-client-project`, add: exclusive `--engine gsd|w2c|none` via `scripts/configure-client-project.sh`. W2C uses `install-w2c-to-project.sh`. Overlay `_AGENTS.md` is architecture-only.

- [ ] **Step 2: README.md**

In GSD milestone workflow, add a sibling W2C path (`work to chores` / `do chores`) and `configure-client-project.sh --engine w2c`. Do not say every client needs `.gsd/`.

- [ ] **Step 3: shared/gsd/README.md**

Update ladder step 0: skill asks engine. Step 2 is GSD-only. Add W2C: `install-w2c-to-project.sh` / orchestrator `--engine w2c`.

Include a `--engine none` sentence.

- [ ] **Step 4: Commit** (only if asked)

```bash
git add FRAMEWORK.md README.md shared/gsd/README.md
git commit -m "$(cat <<'EOF'
Document exclusive GSD vs W2C vs none client configure.

EOF
)"
```

---

## Spec coverage (self-review)

| Spec item | Task |
| --- | --- |
| CLI contract + GSD flag errors | 4 |
| `--check` / `--dry-run` | 4 |
| Check W2C probes + default engine | 1 |
| Overlay `_AGENTS.md` architecture-only | 2 |
| Overlay `_CLAUDE.md` / wrappers | 3 |
| Wrapper markers + idempotency | 4 |
| W2C full install | 4 |
| Skill interview + single CLI call | 5 |
| Handoff per engine | 5 |
| FRAMEWORK/README | 6 |
| `configure-client-project.test.sh` | 1–4 |
| Not configuring bitoron_mobile | out of scope (all tasks) |
