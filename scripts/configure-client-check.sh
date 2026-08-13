#!/usr/bin/env bash
# Read-only preflight for configure-client-project skill.
# Discovers client repo signals and reports GSD/overlay/MCP readiness.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  configure-client-check.sh \
    --source-repo /path/to/ai-playbook \
    --client-repo /path/to/client

Read-only. No files are copied or modified.
EOF
}

die() { printf 'Error: %s\n' "$1" >&2; exit 1; }

SOURCE_REPO=""
CLIENT_REPO=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-repo) SOURCE_REPO="$2"; shift 2 ;;
    --client-repo) CLIENT_REPO="$2"; shift 2 ;;
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

status() { printf '[%s] %s\n' "$1" "$2"; }

detect_universal_project_style() {
  local repo="$1"
  if [[ -f "$repo/composer.json" ]]; then printf '%s\n' "php"; return; fi
  if [[ -f "$repo/pyproject.toml" || -f "$repo/requirements.txt" || -f "$repo/setup.py" ]]; then
    printf '%s\n' "python"; return
  fi
  if [[ -f "$repo/package.json" || -f "$repo/pnpm-workspace.yaml" || -f "$repo/yarn.lock" ]]; then
    if command -v rg >/dev/null 2>&1 && rg -q --glob '**/package.json' '"react-native"|"expo"' "$repo" 2>/dev/null; then
      printf '%s\n' "react-native-mono"; return
    fi
    printf '%s\n' "node"; return
  fi
  printf '%s\n' "generic"
}

guess_platform() {
  local repo="$1"
  if [[ -f "$repo/pubspec.yaml" ]]; then
    if rg -q 'riverpod' "$repo/pubspec.yaml" 2>/dev/null; then printf '%s\n' "flutter-riverpod"; return; fi
    if rg -q 'flutter_bloc' "$repo/pubspec.yaml" 2>/dev/null; then printf '%s\n' "flutter-bloc"; return; fi
    printf '%s\n' "flutter-riverpod"; return
  fi
  if [[ -f "$repo/ios/Podfile" ]] || compgen -G "$repo/*.xcodeproj" >/dev/null 2>&1; then
    printf '%s\n' "ios"; return
  fi
  if [[ -f "$repo/build.gradle" || -f "$repo/build.gradle.kts" || -d "$repo/app/src/main" ]]; then
    printf '%s\n' "android"; return
  fi
  printf '%s\n' "universal"
}

detect_git_default_branch() {
  local repo="$1" branch=""
  branch="$(git -C "$repo" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||' || true)"
  if [[ -z "$branch" ]]; then
    branch="$(git -C "$repo" branch --show-current 2>/dev/null || true)"
  fi
  if [[ -z "$branch" ]]; then branch="main"; fi
  printf '%s\n' "$branch"
}

# ── Git repo check ──────────────────────────────────────────────────────────
if git -C "$CLIENT_REPO" rev-parse --git-dir >/dev/null 2>&1; then
  status "OK" "git repository"
else
  status "MISSING" "git repository (not a git checkout)"
fi

# ── Stack / platform discovery ──────────────────────────────────────────────
style="$(detect_universal_project_style "$CLIENT_REPO")"
platform="$(guess_platform "$CLIENT_REPO")"
branch="$(detect_git_default_branch "$CLIENT_REPO")"

status "DISCOVER" "platform guess: $platform"
status "DISCOVER" "project style: $style"
status "DISCOVER" "default branch: $branch"

if [[ -f "$CLIENT_REPO/composer.json" ]]; then status "DISCOVER" "stack marker: composer.json (PHP)"
elif [[ -f "$CLIENT_REPO/package.json" ]]; then status "DISCOVER" "stack marker: package.json (Node)"
elif [[ -f "$CLIENT_REPO/pubspec.yaml" ]]; then status "DISCOVER" "stack marker: pubspec.yaml (Flutter)"
elif [[ -f "$CLIENT_REPO/pyproject.toml" ]]; then status "DISCOVER" "stack marker: pyproject.toml (Python)"
elif [[ -f "$CLIENT_REPO/Cargo.toml" ]]; then status "DISCOVER" "stack marker: Cargo.toml (Rust)"
else status "DISCOVER" "stack marker: none (greenfield or unknown)"
fi

# ── GSD state ───────────────────────────────────────────────────────────────
if [[ -d "$CLIENT_REPO/.gsd" ]]; then
  status "OK" ".gsd/"
else
  status "MISSING" ".gsd/"
fi

if [[ -d "$CLIENT_REPO/.gsd/workflow" ]]; then
  status "OK" ".gsd/workflow/"
else
  status "MISSING" ".gsd/workflow/"
fi

if [[ -f "$CLIENT_REPO/.gsd/gsd.db" ]]; then
  status "OK" ".gsd/gsd.db"
else
  status "MISSING" ".gsd/gsd.db"
fi

profile="$CLIENT_REPO/.gsd/DELIVERY-PROFILE.md"
if [[ ! -f "$profile" ]]; then
  status "MISSING" "DELIVERY-PROFILE.md"
elif grep -q 'main or develop' "$profile" 2>/dev/null; then
  status "PLACEHOLDER" "DELIVERY-PROFILE.md (unconfigured — run configure-client-project or bootstrap --interactive)"
elif grep -qE '\[e\.g\.|TODO: add project verification' "$profile" 2>/dev/null; then
  status "PLACEHOLDER" "DELIVERY-PROFILE.md (partial — review validation block)"
else
  status "CONFIGURED" "DELIVERY-PROFILE.md"
fi

# ── Overlay state ───────────────────────────────────────────────────────────
if [[ -L "$CLIENT_REPO/_AGENTS.md" ]]; then
  status "OK" "overlay symlink (_AGENTS.md)"
elif [[ -f "$CLIENT_REPO/_AGENTS.md" ]]; then
  status "OK" "overlay file (_AGENTS.md, not symlink)"
else
  status "MISSING" "overlay (_AGENTS.md — run install-client-ai-overlay.sh)"
fi

if [[ -d "$CLIENT_REPO/.workflow" ]]; then
  status "OK" ".workflow/"
else
  status "MISSING" ".workflow/"
fi

# ── MCP ─────────────────────────────────────────────────────────────────────
mcp_file=""
for candidate in "$CLIENT_REPO/.mcp.json" "$CLIENT_REPO/.cursor/mcp.json"; do
  if [[ -f "$candidate" ]]; then mcp_file="$candidate"; break; fi
done

if [[ -z "$mcp_file" ]]; then
  status "MISSING" "gsd-workflow MCP (.mcp.json not found)"
elif grep -q 'gsd-workflow' "$mcp_file" 2>/dev/null; then
  status "OK" "gsd-workflow in $mcp_file"
else
  status "MISSING" "gsd-workflow in $mcp_file"
fi

if [[ -n "$mcp_file" ]] && grep -q 'playbook-gsd' "$mcp_file" 2>/dev/null; then
  status "OK" "playbook-gsd in $mcp_file"
elif [[ -f "$CLIENT_REPO/.mcp.json" ]]; then
  status "MISSING" "playbook-gsd in .mcp.json (ask to merge via configure-client-project / merge-mcp-template.sh)"
fi

# ── do-next health script ───────────────────────────────────────────────────
if [[ -f "$CLIENT_REPO/.workflow/scripts/playbook-gsd-health.sh" ]]; then
  status "OK" ".workflow/scripts/playbook-gsd-health.sh"
else
  status "MISSING" ".workflow/scripts/playbook-gsd-health.sh (bootstrap --with-do-next)"
fi

# ── Delegate to bootstrap --check when playbook scripts exist ───────────────
bootstrap="$SOURCE_REPO/scripts/bootstrap-gsd-workflow.sh"
if [[ -x "$bootstrap" || -f "$bootstrap" ]]; then
  printf '\n'
  bash "$bootstrap" \
    --source-repo "$SOURCE_REPO" \
    --client-repo "$CLIENT_REPO" \
    --check 2>/dev/null || true
fi
