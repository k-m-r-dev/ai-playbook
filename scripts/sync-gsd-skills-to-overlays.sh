#!/usr/bin/env bash
# sync-gsd-skills-to-overlays.sh
#
# REFUSED: This script previously materialized GSD/do-next skills into
# platform overlay directories. That approach is superseded by the
# Personal Agents Hub model:
#
#   - Skills are assembled once into ~/.agents/skills by
#     scripts/install-personal-agents-hub.sh
#   - Cursor/Claude bridges are symlinks from ~/.cursor/skills and
#     ~/.claude/skills into the hub
#   - Platform overlays no longer carry copies of SoT skills
#
# The canonical skill list lives in shared/gsd/personal-skills.manifest.
#
# To update personal skills:
#   bash scripts/install-personal-agents-hub.sh --force
#
# To update a single skill:
#   bash scripts/update-personal-skill.sh <skill-name>
#
# If you need to install skills into a CLIENT project (not personal),
# use install-workflow-tools.sh:
#   bash shared/gsd/scripts/install-workflow-tools.sh --project --repo /path/to/client

set -euo pipefail

printf '\n[REFUSED] sync-gsd-skills-to-overlays.sh is retired.\n\n' >&2
printf 'Platform overlays no longer carry copies of SoT skills\n' >&2
printf '(do-next, do-next-runner, gsd-plan-milestone, gsd-advance-unit,\n' >&2
printf ' ticket-to-plan, verified-pr-review, graphify-obsidian).\n\n' >&2
printf 'Use instead:\n' >&2
printf '  Personal hub:  bash scripts/install-personal-agents-hub.sh --force\n' >&2
printf '  Client project: bash shared/gsd/scripts/install-workflow-tools.sh --project --repo <path>\n\n' >&2
printf 'See shared/gsd/personal-skills.manifest for the canonical skill list.\n\n' >&2
exit 1
