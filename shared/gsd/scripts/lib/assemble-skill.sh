#!/usr/bin/env bash
# Assemble SKILL.md or instructions from wrapper + body (+ optional include expansion).
set -euo pipefail

assemble_skill() {
  local wrapper="$1"
  local body="$2"
  local out="$3"
  local gsd_root="${4:-}"

  if [[ -z "$gsd_root" ]]; then
    gsd_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  fi

  mkdir -p "$(dirname "$out")"
  cat "$wrapper" > "$out"
  printf '\n' >> "$out"

  while IFS= read -r line || [[ -n "$line" ]]; do
    case "$line" in
      "<!-- include: "*)
        local inc="${line#<!-- include: }"
        inc="${inc% -->}"
        local inc_path="$gsd_root/$inc"
        if [[ -f "$inc_path" ]]; then
          cat "$inc_path" >> "$out"
          printf '\n' >> "$out"
        else
          echo "WARN: missing include $inc_path" >&2
        fi
        ;;
      *)
        printf '%s\n' "$line" >> "$out"
        ;;
    esac
  done < "$body"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  assemble_skill "$1" "$2" "$3" "${4:-}"
  echo "Wrote $3"
fi
