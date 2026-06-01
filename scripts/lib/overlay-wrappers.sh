# shellcheck shell=bash
# Shared helpers for playbook template (_*) vs project wrapper (committed) root files.

overlay_wrapper_root_files() {
  printf '%s\n' AGENTS.md CLAUDE.md ARCHITECTURE.md SESSION_WORKFLOW.md
}

overlay_template_root_files() {
  printf '%s\n' _AGENTS.md _CLAUDE.md _ARCHITECTURE.md _SESSION_WORKFLOW.md
}

overlay_is_wrapper_file() {
  case "$1" in
    AGENTS.md | CLAUDE.md | ARCHITECTURE.md | SESSION_WORKFLOW.md) return 0 ;;
    *) return 1 ;;
  esac
}

overlay_is_template_file() {
  case "$1" in
    _AGENTS.md | _CLAUDE.md | _ARCHITECTURE.md | _SESSION_WORKFLOW.md) return 0 ;;
    *) return 1 ;;
  esac
}

# Wrappers and .workflow/ are always copied; playbook templates follow --mode.
overlay_effective_install_mode() {
  local source_rel="$1"
  local mode="$2"
  if [[ "$source_rel" == ".workflow" ]] || overlay_is_wrapper_file "$source_rel"; then
    printf '%s' "copy"
  else
    printf '%s' "$mode"
  fi
}

overlay_gitignore_template_entries() {
  cat <<'EOF'
/_AGENTS.md
/_CLAUDE.md
/_ARCHITECTURE.md
/_SESSION_WORKFLOW.md
/skills-lock.json
/.claude/helpers
/.claude/skills
/.cursor/rules
/.cursor/skills
/.github/agents
/.github/instructions
/.github/copilot-instructions.md
/.workflow
EOF
}

overlay_gitignore_info_exclude_template_entries() {
  overlay_gitignore_template_entries
}
