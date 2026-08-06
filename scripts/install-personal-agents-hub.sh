#!/usr/bin/env bash
# install-personal-agents-hub.sh — Assemble personal agents hub at ~/.agents/skills
# with Cursor and Claude Code bridges. Source of truth: shared/gsd/personal-skills.manifest
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYBOOK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_REPO=""

HUB_DIR="$HOME/.agents/skills"
CURSOR_DIR="$HOME/.cursor/skills"
CLAUDE_DIR="$HOME/.claude/skills"
CODEX_DIR="$HOME/.codex/skills"
LOCKFILE="$HOME/.playbook-hub-lock.json"

MODE="flat"  # flat (copy) or assemble
DO_CURSOR=1
DO_CLAUDE=1
DO_CODEX=0
FORCE=0
DRY_RUN=0
SKILLS_FILTER=""
INSTALL_AGENTS=1

usage() {
  cat <<'EOF'
Usage: install-personal-agents-hub.sh [options]

Assemble personal skills from ai-playbook into ~/.agents/skills hub
with bridges to ~/.cursor/skills and ~/.claude/skills.

Options:
  --assemble        Use assemble mode (SKILL.body.md + wrapper)
  --flat            Use flat copy mode (default; copies assembled SKILL.md)
  --cursor          Install Cursor bridges (default: yes)
  --claude          Install Claude bridges (default: yes)
  --codex           Install Codex bridges
  --no-cursor       Skip Cursor bridges
  --no-claude       Skip Claude bridges
  --skills LIST     Comma-separated skill names to install (default: all from manifest)
  --force           Overwrite existing skills even if unchanged
  --dry-run         Print actions without executing
  --no-agents       Skip do-next-runner agent files
  --source-repo PATH  Playbook root (default: parent of scripts/)
  -h|--help         Show this help

Lockfile: ~/.playbook-hub-lock.json tracks installed versions.

Examples:
  install-personal-agents-hub.sh
  install-personal-agents-hub.sh --skills ticket-to-plan,graphify-obsidian
  install-personal-agents-hub.sh --assemble --force
  install-personal-agents-hub.sh --codex --dry-run
EOF
}

die() { printf 'Error: %s\n' "$1" >&2; exit 1; }
info() { printf '[hub] %s\n' "$1"; }
action() {
  if [[ "$DRY_RUN" == 1 ]]; then
    printf '[dry-run] %s\n' "$1"
  else
    printf '[hub] %s\n' "$1"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --assemble) MODE="assemble"; shift ;;
    --flat) MODE="flat"; shift ;;
    --cursor) DO_CURSOR=1; shift ;;
    --claude) DO_CLAUDE=1; shift ;;
    --codex) DO_CODEX=1; shift ;;
    --no-cursor) DO_CURSOR=0; shift ;;
    --no-claude) DO_CLAUDE=0; shift ;;
    --skills) SKILLS_FILTER="$2"; shift 2 ;;
    --force) FORCE=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --no-agents) INSTALL_AGENTS=0; shift ;;
    --source-repo) SOURCE_REPO="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown argument: $1" ;;
  esac
done

if [[ -n "$SOURCE_REPO" ]]; then
  [[ -d "$SOURCE_REPO" ]] || die "source-repo not found: $SOURCE_REPO"
  PLAYBOOK_ROOT="$(cd "$SOURCE_REPO" && pwd)"
fi
GSD_ROOT="$PLAYBOOK_ROOT/shared/gsd"
MANIFEST="$GSD_ROOT/personal-skills.manifest"

# shellcheck source=../shared/gsd/scripts/lib/assemble-skill.sh
# Source after PLAYBOOK_ROOT resolution so --source-repo works from any cwd/worktree.
[[ -f "$GSD_ROOT/scripts/lib/assemble-skill.sh" ]] && source "$GSD_ROOT/scripts/lib/assemble-skill.sh"

[[ -f "$MANIFEST" ]] || die "Manifest not found: $MANIFEST"

# --- Lockfile helpers ---
lockfile_read() {
  if [[ -f "$LOCKFILE" ]]; then
    cat "$LOCKFILE"
  else
    echo '{}'
  fi
}

lockfile_get_hash() {
  local skill="$1"
  lockfile_read | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(data.get('$skill', {}).get('hash', ''))
" 2>/dev/null || echo ""
}

lockfile_set() {
  local skill="$1" hash="$2" mode="$3"
  local ts
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local current
  current="$(lockfile_read)"
  echo "$current" | python3 -c "
import json, sys
data = json.load(sys.stdin)
data['$skill'] = {'hash': '$hash', 'mode': '$mode', 'installed_at': '$ts'}
json.dump(data, sys.stdout, indent=2)
print()
" > "$LOCKFILE.tmp" && mv "$LOCKFILE.tmp" "$LOCKFILE"
}

file_hash() {
  if [[ -f "$1" ]]; then
    shasum -a 256 "$1" | cut -c1-16
  elif [[ -d "$1" ]]; then
    find "$1" -type f | sort | xargs shasum -a 256 2>/dev/null | shasum -a 256 | cut -c1-16
  else
    echo "none"
  fi
}

# --- Parse manifest ---
parse_manifest() {
  local line skill stype spath
  while IFS= read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    read -r skill stype spath <<< "$line"
    [[ -z "$skill" ]] && continue
    if [[ -n "$SKILLS_FILTER" && ",${SKILLS_FILTER}," != *",${skill},"* ]]; then
      continue
    fi
    echo "$skill $stype $spath"
  done < "$MANIFEST"
}

# --- Install functions ---
install_assembled_skill() {
  local skill="$1" src_dir="$2" dest="$3"
  local wrapper body
  case "$skill" in
    do-next|do-next-runner)
      wrapper="$GSD_ROOT/$src_dir/SKILL.cursor.md"
      body="$GSD_ROOT/$src_dir/SKILL.body.md"
      ;;
    gsd-plan-milestone|gsd-advance-unit)
      wrapper="$GSD_ROOT/$src_dir/SKILL.cursor.md"
      body="$GSD_ROOT/$src_dir/SKILL.body.md"
      ;;
    *)
      die "Cannot assemble unknown skill: $skill"
      ;;
  esac
  [[ -f "$wrapper" ]] || die "Wrapper not found: $wrapper"
  [[ -f "$body" ]] || die "Body not found: $body"
  declare -F assemble_skill >/dev/null 2>&1 || die "assemble_skill not loaded (missing $GSD_ROOT/scripts/lib/assemble-skill.sh)"
  action "ASSEMBLE $dest"
  if [[ "$DRY_RUN" != 1 ]]; then
    mkdir -p "$(dirname "$dest")"
    assemble_skill "$wrapper" "$body" "$dest" "$GSD_ROOT"
  fi
}

install_flat_skill() {
  local skill="$1" src_dir="$2" dest="$3"
  local src="$GSD_ROOT/$src_dir/SKILL.md"
  [[ -f "$src" ]] || die "Flat skill source not found: $src"
  action "COPY $src -> $dest"
  if [[ "$DRY_RUN" != 1 ]]; then
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
  fi
}

bridge_symlink() {
  local src_dir="$1" dest_dir="$2" skill="$3"
  local dest="$dest_dir/$skill"
  local target="$src_dir/$skill"
  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ -L "$dest" ]]; then
      :
    elif [[ -d "$dest" && "$FORCE" != 1 ]]; then
      # Careful conflict policy: never replace a real skill dir without --force
      # (esp. ~/.codex/skills managed outside the hub).
      info "SKIP bridge $dest (real directory; pass --force to replace)"
      return 0
    fi
  fi
  action "BRIDGE $dest -> $target"
  if [[ "$DRY_RUN" != 1 ]]; then
    mkdir -p "$dest_dir"
    [[ -e "$dest" || -L "$dest" ]] && rm -rf "$dest"
    ln -sfn "$target" "$dest"
  fi
}

install_do_next_runner_agents() {
  local tpl="$GSD_ROOT/idea/do-next-runner/templates"
  if [[ ! -d "$tpl" ]]; then
    info "SKIP agents (templates not found at $tpl)"
    return
  fi
  for dest_dir in "$HOME/.cursor/agents" "$HOME/.claude/agents"; do
    action "AGENT $dest_dir/do-next-runner.md"
    if [[ "$DRY_RUN" != 1 ]]; then
      mkdir -p "$dest_dir"
      if [[ "$dest_dir" == *".cursor"* ]]; then
        cp "$tpl/agent.cursor.md" "$dest_dir/do-next-runner.md"
      else
        cp "$tpl/agent.claude.md" "$dest_dir/do-next-runner.md"
      fi
    fi
  done
}

# --- Main ---
info "Playbook: $PLAYBOOK_ROOT"
info "Hub: $HUB_DIR"
info "Mode: $MODE"
[[ "$DRY_RUN" == 1 ]] && info "DRY RUN"

INSTALLED=0
SKIPPED=0

while IFS= read -r entry; do
  [[ -z "$entry" ]] && continue
  read -r skill stype spath <<< "$entry"

  hub_dest="$HUB_DIR/$skill/SKILL.md"

  # Check source hash for skip logic
  if [[ "$stype" == "flat" ]]; then
    src_hash="$(file_hash "$GSD_ROOT/$spath/SKILL.md")"
  elif [[ "$stype" == "assembled" ]]; then
    src_hash="$(file_hash "$GSD_ROOT/$spath")"
  else
    src_hash="external"
  fi

  # Skip content install if unchanged and not forced — still refresh bridges
  # (bridges even when skipped) so --codex can link without --force.
  if [[ "$FORCE" != 1 && -f "$hub_dest" ]]; then
    existing_hash="$(lockfile_get_hash "$skill")"
    if [[ "$existing_hash" == "$src_hash" ]]; then
      [[ "$DO_CURSOR" == 1 ]] && bridge_symlink "$HUB_DIR" "$CURSOR_DIR" "$skill"
      [[ "$DO_CLAUDE" == 1 ]] && bridge_symlink "$HUB_DIR" "$CLAUDE_DIR" "$skill"
      [[ "$DO_CODEX" == 1 ]] && bridge_symlink "$HUB_DIR" "$CODEX_DIR" "$skill"
      SKIPPED=$((SKIPPED + 1))
      continue
    fi
  fi

  # Install to hub
  case "$stype" in
    assembled)
      install_assembled_skill "$skill" "$spath" "$hub_dest"
      ;;
    flat)
      install_flat_skill "$skill" "$spath" "$hub_dest"
      ;;
    external)
      if [[ ! -d "$HUB_DIR/$skill" ]]; then
        info "SKIP external skill $skill (not found in hub)"
        continue
      fi
      ;;
  esac

  # Create bridges
  [[ "$DO_CURSOR" == 1 ]] && bridge_symlink "$HUB_DIR" "$CURSOR_DIR" "$skill"
  [[ "$DO_CLAUDE" == 1 ]] && bridge_symlink "$HUB_DIR" "$CLAUDE_DIR" "$skill"
  [[ "$DO_CODEX" == 1 ]] && bridge_symlink "$HUB_DIR" "$CODEX_DIR" "$skill"

  # Update lockfile
  if [[ "$DRY_RUN" != 1 ]]; then
    lockfile_set "$skill" "$src_hash" "$MODE"
  fi

  INSTALLED=$((INSTALLED + 1))
done < <(parse_manifest)

# Install agents
if [[ "$INSTALL_AGENTS" == 1 ]]; then
  install_do_next_runner_agents
fi

info "Done. Installed: $INSTALLED, Skipped (unchanged): $SKIPPED"
if [[ "$DRY_RUN" == 1 ]]; then
  info "(dry run — no files were modified)"
fi
exit 0
