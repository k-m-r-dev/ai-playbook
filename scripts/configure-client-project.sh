#!/usr/bin/env bash
# Orchestrate client overlay + exclusive planning engine (gsd | w2c | none).
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  configure-client-project.sh \
    --source-repo PATH \
    --client-repo PATH \
    --platform PLATFORM \
    --engine gsd|w2c|none \
    [--mode symlink] [--existing-policy merge] \
    [--check] [--dry-run] \
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

case "$MODE" in
  symlink|copy) ;;
  *) die "--mode must be symlink or copy" ;;
esac

if [[ "$ENGINE" != gsd && ( "$INIT_GSD" == 1 || "$WITH_DO_NEXT" == 1 || "$PATCH_MCP" == 1 || "$HARNESS_CONTEXT" == 1 ) ]]; then
  die "GSD flags are only valid with --engine gsd"
fi

case "$PLATFORM" in
  universal|ios|android|flutter-riverpod|flutter-bloc) ;;
  *) die "unknown --platform: $PLATFORM" ;;
esac

overlay_installed() {
  local git_dir_raw git_dir
  git_dir_raw="$(git -C "$CLIENT_REPO" rev-parse --git-dir 2>/dev/null)" || return 1
  if [[ "$git_dir_raw" = /* ]]; then
    git_dir="$git_dir_raw"
  else
    git_dir="$CLIENT_REPO/$git_dir_raw"
  fi
  [[ -e "$git_dir/ai-playbook/${PLATFORM}.manifest.tsv" ]]
}
upsert_planning_engine() {
  local file="$1" engine="$2"
  [[ -f "$file" ]] || die "wrapper missing: $file"
  python3 - "$file" "$engine" <<'PY'
import re
import sys

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
bad = re.compile(
    r"^- .*\b(GSD|gsd-pi|gsd-workflow|openGSD|graphify|ruflo|Furqan|LIBRARY_MANIFEST)\b.*\n",
    re.I,
)

parts = []
last = 0
for match in pat.finditer(text):
    parts.append(bad.sub("", text[last:match.start()]))
    parts.append(match.group(0))
    last = match.end()
parts.append(bad.sub("", text[last:]))
text = "".join(parts)

if pat.search(text):
    text = pat.sub(block, text, count=1)
else:
    if not text.endswith("\n"):
        text += "\n"
    text += "\n" + block
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
    w2c) info "would: install-w2c-to-project.sh --repo $CLIENT_REPO --mode $MODE" ;;
    none) info "would: skip GSD and W2C installers" ;;
  esac
  info "would: patch AGENTS.md and CLAUDE.md planning-engine markers"
  exit 0
fi

git -C "$CLIENT_REPO" rev-parse --git-dir >/dev/null 2>&1 || die "client is not a git repo"

if overlay_installed; then
  info "overlay already installed for platform=$PLATFORM"
else
  bash "$SOURCE_REPO/scripts/install-client-ai-overlay.sh" \
    --source-repo "$SOURCE_REPO" \
    --client-repo "$CLIENT_REPO" \
    --platform "$PLATFORM" \
    --mode "$MODE" \
    --existing-policy "$EXISTING_POLICY"
fi

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
    args=(--source-repo "$SOURCE_REPO" --repo "$CLIENT_REPO" --mode "$MODE")
    [[ "$FORCE" == 1 ]] && args+=(--force)
    bash "$SOURCE_REPO/scripts/install-w2c-to-project.sh" "${args[@]}"
    ;;
  none) ;;
esac

upsert_planning_engine "$CLIENT_REPO/AGENTS.md" "$ENGINE"
upsert_planning_engine "$CLIENT_REPO/CLAUDE.md" "$ENGINE"
info "done engine=$ENGINE"
