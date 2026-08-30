#!/usr/bin/env bash
# Sync canonical .claude/helpers/hook-handler.cjs to all platform overlay trees.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CANONICAL="$ROOT_DIR/.claude/helpers/hook-handler.cjs"
PLATFORMS=(universal ios android flutter-bloc flutter-riverpod)

[[ -f "$CANONICAL" ]] || { echo "Missing canonical: $CANONICAL" >&2; exit 1; }

for platform in "${PLATFORMS[@]}"; do
  target="$ROOT_DIR/$platform/.claude/helpers/hook-handler.cjs"
  [[ -f "$target" ]] || { echo "Missing target: $target" >&2; exit 1; }
  if cmp -s "$CANONICAL" "$target"; then
    echo "OK  $platform (already in sync)"
  else
    cp "$CANONICAL" "$target"
    echo "SYNC $platform"
  fi
done

echo "Done. Run: bash scripts/verify-hook-safety.sh"
