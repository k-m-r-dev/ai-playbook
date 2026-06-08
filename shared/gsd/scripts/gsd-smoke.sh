#!/usr/bin/env bash
# GSD workflow smoke test — plan coherence, gates, STATE sync.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

exec python3 "$ROOT/.workflow/scripts/gsd-smoke.py" "$@"
