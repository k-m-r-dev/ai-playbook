#!/usr/bin/env bash
# Install do-next / do-next-runner / gsd-plan-milestone / gsd-advance-unit skills.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GSD_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=lib/assemble-skill.sh
source "$SCRIPT_DIR/lib/assemble-skill.sh"

usage() {
  cat <<'EOF'
Usage: install-workflow-tools.sh [options]

  --project          Install into --repo (default: cwd)
  --personal         Install into ~/.cursor/skills and ~/.claude/skills
  --repo PATH        Client repo for --project (default: pwd)
  --cursor --claude --copilot   IDE targets (default: all if any install mode)
  --tools LIST       Comma-separated: do-next,do-next-runner,gsd-plan-milestone,gsd-advance-unit
  --platform NAME    After project install, harness platform.md + DELIVERY-PROFILE (universal|ios|...)
  --harness-context  Alias for --platform with generic universal when skills installed
  --link|--copy      Project install mode (default: link on Unix)
  --dry-run          Print actions only
  --all              --project + --personal + all IDEs

Examples:
  install-workflow-tools.sh --project --cursor --claude --repo /path/to/client
  install-workflow-tools.sh --personal --cursor
  install-workflow-tools.sh --all --repo .
EOF
}

die() { printf 'Error: %s\n' "$1" >&2; exit 1; }

REPO="$(pwd)"
MODE_PROJECT=0
MODE_PERSONAL=0
DO_CURSOR=0
DO_CLAUDE=0
DO_COPILOT=0
INSTALL_MODE="link"
DRY_RUN=0
TOOLS="do-next,do-next-runner,gsd-plan-milestone,gsd-advance-unit"
PLATFORM=""
HARNESS_CONTEXT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) MODE_PROJECT=1; shift ;;
    --personal) MODE_PERSONAL=1; shift ;;
    --repo) REPO="$2"; shift 2 ;;
    --cursor) DO_CURSOR=1; shift ;;
    --claude) DO_CLAUDE=1; shift ;;
    --copilot) DO_COPILOT=1; shift ;;
    --tools) TOOLS="$2"; shift 2 ;;
    --platform) PLATFORM="$2"; shift 2 ;;
    --harness-context) HARNESS_CONTEXT=1; shift ;;
    --link) INSTALL_MODE="link"; shift ;;
    --copy) INSTALL_MODE="copy"; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --all) MODE_PROJECT=1; MODE_PERSONAL=1; DO_CURSOR=1; DO_CLAUDE=1; DO_COPILOT=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown arg: $1" ;;
  esac
done

[[ "$MODE_PROJECT" == 1 || "$MODE_PERSONAL" == 1 ]] || die "Specify --project and/or --personal"

if [[ "$DO_CURSOR$DO_CLAUDE$DO_COPILOT" == "000" ]]; then
  DO_CURSOR=1; DO_CLAUDE=1; DO_COPILOT=1
fi

tool_enabled() {
  [[ ",$TOOLS," == *",$1,"* ]]
}

write_file() {
  local dest="$1"
  local src="$2"
  if [[ "$DRY_RUN" == 1 ]]; then
    echo "WRITE $dest <- $src"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  if [[ "$INSTALL_MODE" == "link" && "$MODE_PROJECT" == 1 ]]; then
    ln -sf "$src" "$dest"
  else
    cp "$src" "$dest"
  fi
}

install_skill_cursor() {
  local base="$1" skill="$2"
  local src_dir body wrapper
  case "$skill" in
    do-next|do-next-runner)
      src_dir="$GSD_ROOT/idea/$skill/templates"
      wrapper="$src_dir/SKILL.cursor.md"
      body="$src_dir/SKILL.body.md"
      ;;
    gsd-plan-milestone|gsd-advance-unit)
      src_dir="$GSD_ROOT/skills/$skill"
      wrapper="$src_dir/SKILL.cursor.md"
      body="$src_dir/SKILL.body.md"
      ;;
    *) die "Unknown skill: $skill" ;;
  esac
  local dest_dir="$base/.cursor/skills/$skill"
  local dest="$dest_dir/SKILL.md"
  if [[ "$DRY_RUN" == 1 ]]; then
    echo "ASSEMBLE $dest"
    return
  fi
  mkdir -p "$dest_dir"
  assemble_skill "$wrapper" "$body" "$dest" "$GSD_ROOT"
  if [[ -f "$src_dir/platform.md.template" && ! -f "$dest_dir/platform.md" ]]; then
    cp "$src_dir/platform.md.template" "$dest_dir/platform.md"
  fi
}

install_skill_claude() {
  local base="$1" skill="$2"
  local dest="$base/.claude/skills/$skill"
  if [[ "$DRY_RUN" == 1 ]]; then
    echo "LINK $dest -> ../../.cursor/skills/$skill"
    return
  fi
  mkdir -p "$base/.claude/skills"
  [[ -e "$dest" && ! -L "$dest" ]] && rm -rf "$dest"
  ln -sfn "../../.cursor/skills/$skill" "$dest"
}

install_skill_copilot() {
  local base="$1" skill="$2"
  local src_dir wrapper body dest
  case "$skill" in
    do-next|do-next-runner)
      src_dir="$GSD_ROOT/idea/$skill/templates"
      wrapper="$src_dir/SKILL.copilot.md"
      body="$src_dir/SKILL.body.md"
      dest="$base/.github/instructions/$skill.instructions.md"
      ;;
    gsd-plan-milestone|gsd-advance-unit)
      src_dir="$GSD_ROOT/skills/$skill"
      wrapper="$src_dir/SKILL.copilot.md"
      body="$src_dir/SKILL.body.md"
      dest="$base/.github/instructions/$skill.instructions.md"
      ;;
    *) die "Unknown skill: $skill" ;;
  esac
  if [[ "$DRY_RUN" == 1 ]]; then
    echo "ASSEMBLE $dest"
    return
  fi
  mkdir -p "$base/.github/instructions"
  assemble_skill "$wrapper" "$body" "$dest" "$GSD_ROOT"
}

install_agents() {
  local base="$1"
  local tpl="$GSD_ROOT/idea/do-next-runner/templates"
  if [[ "$DRY_RUN" == 1 ]]; then
    echo "AGENTS $base/.cursor/agents + .claude/agents"
    return
  fi
  mkdir -p "$base/.cursor/agents" "$base/.claude/agents"
  cp "$tpl/agent.cursor.md" "$base/.cursor/agents/do-next-runner.md"
  cp "$tpl/agent.claude.md" "$base/.claude/agents/do-next-runner.md"
}

remove_retired_skills() {
  local base="$1"
  for name in gsd-pi-cursor gsd-next-cursor; do
    for dir in .cursor/skills .claude/skills; do
      local path="$base/$dir/$name"
      if [[ "$DRY_RUN" == 1 ]]; then
        [[ -e "$path" || -L "$path" ]] && echo "REMOVE $path"
        continue
      fi
      [[ -e "$path" || -L "$path" ]] && rm -rf "$path"
    done
  done
}

check_gsd_gate() {
  local base="$1"
  if [[ ! -d "$base/.gsd" ]]; then
    printf '\n[WARN] .gsd/ not found in %s\n' "$base" >&2
    printf '       GSD skills will NOT work until bootstrap:\n' >&2
    printf '       bootstrap-gsd-workflow.sh --client-repo %s --init-gsd --patch-mcp --with-do-next\n\n' "$base" >&2
  fi
}

run_install() {
  local base="$1"
  IFS=',' read -ra arr <<< "$TOOLS"
  for skill in "${arr[@]}"; do
    [[ "$DO_CURSOR" == 1 ]] && tool_enabled "$skill" && install_skill_cursor "$base" "$skill"
    [[ "$DO_CLAUDE" == 1 ]] && tool_enabled "$skill" && install_skill_claude "$base" "$skill"
    [[ "$DO_COPILOT" == 1 ]] && tool_enabled "$skill" && install_skill_copilot "$base" "$skill"
  done
  if tool_enabled "do-next-runner"; then
    install_agents "$base"
  fi
  remove_retired_skills "$base"
  check_gsd_gate "$base"
}

if [[ "$MODE_PROJECT" == 1 ]]; then
  project_base="$(cd "$REPO" && pwd)"
  run_install "$project_base"
  harness_platform="$PLATFORM"
  [[ "$HARNESS_CONTEXT" == 1 && -z "$harness_platform" ]] && harness_platform="universal"
  if [[ -n "$harness_platform" && "$DRY_RUN" != 1 ]]; then
    playbook_root="$(cd "$GSD_ROOT/../.." && pwd)"
    harness="$GSD_ROOT/scripts/harness-gsd-project-context.sh"
    if [[ -x "$harness" || -f "$harness" ]]; then
      chmod +x "$harness" 2>/dev/null || true
      bash "$harness" --source-repo "$playbook_root" --client-repo "$project_base" --platform "$harness_platform"
    fi
  elif [[ -n "$harness_platform" && "$DRY_RUN" == 1 ]]; then
    echo "HARNESS platform.md + DELIVERY-PROFILE for $harness_platform"
  fi
fi
[[ "$MODE_PERSONAL" == 1 ]] && {
  [[ "$DO_CURSOR" == 1 ]] && run_install "$HOME"
  # Claude personal uses ~/.claude/skills only — run_install expects .cursor under same base
  if [[ "$DO_CLAUDE" == 1 && "$MODE_PROJECT" != 1 ]]; then
    for skill in do-next do-next-runner gsd-plan-milestone gsd-advance-unit; do
      tool_enabled "$skill" || continue
      dest="$HOME/.claude/skills/$skill"
      src="$GSD_ROOT"
      if [[ "$DRY_RUN" == 1 ]]; then
        echo "PERSONAL claude skill $skill -> assemble to $dest"
      else
        mkdir -p "$HOME/.claude/skills/$skill"
        case "$skill" in
          do-next|do-next-runner)
            assemble_skill "$GSD_ROOT/idea/$skill/templates/SKILL.claude.md" \
              "$GSD_ROOT/idea/$skill/templates/SKILL.body.md" \
              "$HOME/.claude/skills/$skill/SKILL.md" "$GSD_ROOT"
            ;;
          *)
            assemble_skill "$GSD_ROOT/skills/$skill/SKILL.cursor.md" \
              "$GSD_ROOT/skills/$skill/SKILL.body.md" \
              "$HOME/.claude/skills/$skill/SKILL.md" "$GSD_ROOT"
            ;;
        esac
      fi
    done
  fi
}

echo "install-workflow-tools.sh complete."
