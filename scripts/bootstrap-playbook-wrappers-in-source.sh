#!/usr/bin/env bash
# One-time (idempotent) split of platform overlay root markdown into _* templates + committed wrappers.
# Run from ai-playbook repo root: bash scripts/bootstrap-playbook-wrappers-in-source.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYBOOK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES="$SCRIPT_DIR/templates"

die() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

sed_inplace() {
  if sed --version >/dev/null 2>&1; then
    sed -i "$@"
  else
    sed -i '' "$@"
  fi
}

strip_learned_sections() {
  local file="$1"
  awk '
    /^## Learned User Preferences/ { skip = 1; next }
    /^## Learned Workspace Facts/ { skip = 1; next }
    skip && /^## / { skip = 0 }
    skip { next }
    { print }
  ' "$file" | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}'
}

extract_section() {
  local file="$1"
  local heading="$2"
  awk -v h="$heading" '
    $0 == h { capture = 1; print; next }
    capture && /^## / { exit }
    capture { print }
  ' "$file"
}

split_platform() {
  local platform="$1"
  local dir="$PLAYBOOK_ROOT/$platform"
  [[ -d "$dir" ]] || return 0

  printf 'Processing %s...\n' "$platform"

  # Skip if already fully split
  if [[ -f "$dir/_AGENTS.md" && -f "$dir/AGENTS.md" && -f "$dir/_ARCHITECTURE.md" && -f "$dir/_SESSION_WORKFLOW.md" ]]; then
    head -1 "$dir/AGENTS.md" | grep -q '@_AGENTS.md' && {
      printf '  already split, skipping\n'
      return 0
    }
  fi

  local agents_src="$dir/AGENTS.md"
  [[ -f "$agents_src" ]] || die "Missing $agents_src"

  local learned_prefs learned_facts
  learned_prefs="$(extract_section "$agents_src" "## Learned User Preferences" || true)"
  learned_facts="$(extract_section "$agents_src" "## Learned Workspace Facts" || true)"

  mv "$agents_src" "$dir/_AGENTS.md"
  strip_learned_sections "$dir/_AGENTS.md" > "$dir/_AGENTS.tmp"
  mv "$dir/_AGENTS.tmp" "$dir/_AGENTS.md"

  {
    cat "$TEMPLATES/wrapper-AGENTS.md"
    if [[ -n "$learned_prefs" ]]; then
      printf '\n'
      printf '%s\n' "$learned_prefs"
    fi
    if [[ -n "$learned_facts" ]]; then
      printf '\n'
      printf '%s\n' "$learned_facts"
    fi
  } > "$dir/AGENTS.md"

  # Patch _AGENTS session line about symlink model
  sed_inplace \
    -e 's|typically \*\*symlink\*\* next to `AGENTS.md`|typically **symlink** as `_AGENTS.md`; committed `AGENTS.md` wraps it with `@_AGENTS.md`|g' \
    -e 's|refine it there, not via client-only edits to the symlink path|refine playbook templates (`_*` files) in ai-playbook; edit committed wrappers in the client repo|g' \
    "$dir/_AGENTS.md"

  if [[ -f "$dir/CLAUDE.md" && ! -f "$dir/_CLAUDE.md" ]]; then
    mv "$dir/CLAUDE.md" "$dir/_CLAUDE.old.md"
    if [[ "$platform" == "universal" ]]; then
      {
        head -n 7 "$dir/_CLAUDE.old.md" | sed \
          -e 's|@AGENTS.md|@_AGENTS.md|' \
          -e 's|@ARCHITECTURE.md|@_ARCHITECTURE.md|' \
          -e 's|@SESSION_WORKFLOW.md|@_SESSION_WORKFLOW.md|' \
          -e 's|Keep it high-signal; push durable policy to `AGENTS.md`|Playbook base — project ledger lives in committed `CLAUDE.md`|'
        printf '\n'
        tail -n +49 "$dir/_CLAUDE.old.md"
      } > "$dir/_CLAUDE.md"
      {
        printf '@_CLAUDE.md\n\n---\n\n'
        sed -n '11,45p' "$dir/_CLAUDE.old.md"
      } > "$dir/CLAUDE.md"
    else
      cp "$TEMPLATES/_CLAUDE-thin.md" "$dir/_CLAUDE.md"
      if [[ "$platform" == "flutter-riverpod" ]]; then
        cat >> "$dir/_CLAUDE.md" <<'EOF'

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
EOF
      fi
      cp "$TEMPLATES/wrapper-CLAUDE-ledger.md" "$dir/CLAUDE.md"
      case "$platform" in
        flutter-riverpod)
          sed_inplace 's|\[fill in per project\]|Flutter / Dart / Riverpod / GetIt-Injectable|' "$dir/CLAUDE.md"
          sed_inplace 's|\*\*Project type\*\*:.*|**Project type**: mobile|' "$dir/CLAUDE.md"
          ;;
        flutter-bloc)
          sed_inplace 's|\[fill in per project\]|Flutter / Dart / BLoC / GetIt-Injectable|' "$dir/CLAUDE.md"
          sed_inplace 's|\*\*Project type\*\*:.*|**Project type**: mobile|' "$dir/CLAUDE.md"
          ;;
        ios)
          sed_inplace 's|\[fill in per project\]|Swift / native iOS|' "$dir/CLAUDE.md"
          sed_inplace 's|\*\*Project type\*\*:.*|**Project type**: mobile|' "$dir/CLAUDE.md"
          ;;
        android)
          sed_inplace 's|\[fill in per project\]|Kotlin / native Android|' "$dir/CLAUDE.md"
          sed_inplace 's|\*\*Project type\*\*:.*|**Project type**: mobile|' "$dir/CLAUDE.md"
          ;;
      esac
    fi
    rm -f "$dir/_CLAUDE.old.md"
  fi

  if [[ -f "$dir/ARCHITECTURE.md" && ! -f "$dir/_ARCHITECTURE.md" ]]; then
    mv "$dir/ARCHITECTURE.md" "$dir/_ARCHITECTURE.md"
    cp "$TEMPLATES/wrapper-ARCHITECTURE.md" "$dir/ARCHITECTURE.md"
  fi

  if [[ -f "$dir/SESSION_WORKFLOW.md" && ! -f "$dir/_SESSION_WORKFLOW.md" ]]; then
    mv "$dir/SESSION_WORKFLOW.md" "$dir/_SESSION_WORKFLOW.md"
    cp "$TEMPLATES/wrapper-SESSION_WORKFLOW.md" "$dir/SESSION_WORKFLOW.md"
    sed_inplace \
      -e 's|usually a \*\*symlink\*\* into your private `ai-playbook`|symlinked as `_SESSION_WORKFLOW.md` into your private `ai-playbook`; committed `SESSION_WORKFLOW.md` wraps it|g' \
      "$dir/_SESSION_WORKFLOW.md"
  fi
}

for platform in universal ios android flutter-riverpod flutter-bloc; do
  split_platform "$platform"
done

printf 'Done.\n'
