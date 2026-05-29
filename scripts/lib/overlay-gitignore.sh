# shellcheck shell=bash
# Shared helpers for client-repo .gitignore blocks (sourced by install/uninstall/patch scripts).

overlay_gitignore_artifacts_file() {
  local source_repo="$1"
  printf '%s/config/client-ai-gitignore-artifacts.txt' "$source_repo"
}

overlay_gitignore_artifacts_begin() {
  printf '# BEGIN %s:local-artifacts' "$1"
}

overlay_gitignore_artifacts_end() {
  printf '# END %s:local-artifacts' "$1"
}

overlay_gitignore_platform_begin() {
  printf '# BEGIN %s:%s' "$1" "$2"
}

overlay_gitignore_platform_end() {
  printf '# END %s:%s' "$1" "$2"
}

overlay_gitignore_read_patterns() {
  local file="$1"
  [[ -f "$file" ]] || return 1
  grep -v '^[[:space:]]*#' "$file" | sed '/^[[:space:]]*$/d'
}

overlay_gitignore_overlay_entries() {
  cat <<'EOF'
/AGENTS.md
/CLAUDE.md
/ARCHITECTURE.md
/skills-lock.json
/.claude/helpers
/.claude/skills
/.cursor/rules
/.cursor/skills
/.github/agents
/.github/instructions
/.github/copilot-instructions.md
/.workflow
/SESSION_WORKFLOW.md
EOF
}

overlay_gitignore_ensure_file() {
  local client_repo="$1"
  local gitignore="$client_repo/.gitignore"
  if [[ ! -f "$gitignore" ]]; then
    touch "$gitignore"
  fi
}

overlay_gitignore_apply_artifacts() {
  local client_repo="$1"
  local name="$2"
  local source_repo="$3"

  local artifacts_file
  artifacts_file="$(overlay_gitignore_artifacts_file "$source_repo")"
  [[ -f "$artifacts_file" ]] || return 1

  local gitignore="$client_repo/.gitignore"
  local begin end
  begin="$(overlay_gitignore_artifacts_begin "$name")"
  end="$(overlay_gitignore_artifacts_end "$name")"

  overlay_gitignore_ensure_file "$client_repo"
  remove_block "$gitignore" "$begin" "$end"

  local -a patterns=()
  while IFS= read -r line; do
    patterns+=("$line")
  done < <(overlay_gitignore_read_patterns "$artifacts_file")

  [[ ${#patterns[@]} -gt 0 ]] || return 0
  append_block "$gitignore" "$begin" "$end" "${patterns[@]}"
}

overlay_gitignore_apply_platform() {
  local client_repo="$1"
  local name="$2"
  local platform="$3"

  local gitignore="$client_repo/.gitignore"
  local begin end
  begin="$(overlay_gitignore_platform_begin "$name" "$platform")"
  end="$(overlay_gitignore_platform_end "$name" "$platform")"

  overlay_gitignore_ensure_file "$client_repo"
  remove_block "$gitignore" "$begin" "$end"

  local -a entries=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && entries+=("$line")
  done < <(overlay_gitignore_overlay_entries)

  append_block "$gitignore" "$begin" "$end" "${entries[@]}"
}

overlay_gitignore_remove_platform() {
  local client_repo="$1"
  local name="$2"
  local platform="$3"

  local gitignore="$client_repo/.gitignore"
  [[ -f "$gitignore" ]] || return 0

  remove_block "$gitignore" \
    "$(overlay_gitignore_platform_begin "$name" "$platform")" \
    "$(overlay_gitignore_platform_end "$name" "$platform")"
}

overlay_gitignore_remove_artifacts_if_unused() {
  local client_repo="$1"
  local name="$2"
  local git_dir="$3"

  local state_dir="$git_dir/$name"
  local gitignore="$client_repo/.gitignore"
  [[ -d "$state_dir" ]] || true

  local remaining="false"
  if [[ -d "$state_dir" ]]; then
    for manifest in "$state_dir"/*.manifest.tsv; do
      [[ -e "$manifest" ]] || continue
      remaining="true"
      break
    done
  fi

  if [[ "$remaining" == "true" ]]; then
    return 0
  fi

  [[ -f "$gitignore" ]] || return 0
  remove_block "$gitignore" \
    "$(overlay_gitignore_artifacts_begin "$name")" \
    "$(overlay_gitignore_artifacts_end "$name")"
}
