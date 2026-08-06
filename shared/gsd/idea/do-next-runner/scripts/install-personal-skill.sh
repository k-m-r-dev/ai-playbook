#!/usr/bin/env bash
# DEPRECATED: This script is superseded by scripts/install-personal-agents-hub.sh
# which manages ALL personal skills via shared/gsd/personal-skills.manifest.
#
# Migration:
#   bash scripts/install-personal-agents-hub.sh --skills do-next-runner --force
#
# Or update a single skill:
#   bash scripts/update-personal-skill.sh do-next-runner
set -euo pipefail

printf '\n[DEPRECATED] install-personal-skill.sh is superseded.\n\n' >&2
printf 'Use instead:\n' >&2
printf '  bash scripts/install-personal-agents-hub.sh --skills do-next-runner\n' >&2
printf '  bash scripts/update-personal-skill.sh do-next-runner\n\n' >&2
printf 'See: scripts/install-personal-agents-hub.sh --help\n\n' >&2
exit 1
