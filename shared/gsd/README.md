# shared/gsd -- GSD milestone workflow bootstrap pack

Canonical source for GSD workflow rules, do-next tooling, and multi-IDE skill templates.

| Path | Purpose |
|------|-------|
| `workflow/` | Abstract milestone rules -> copied to client `.gsd/workflow/` |
| `templates/` | `DELIVERY-PROFILE.md`, `DECISIONS.md` starters |
| `templates/platforms/` | Platform packs (ios, android, flutter-*, universal) |
| `skills/` | IDE-neutral skill bodies (`gsd-plan-milestone`, `gsd-advance-unit`, flat skills) |
| `idea/do-next/` | do-next skill templates + assembly |
| `idea/do-next-runner/` | Runner templates, scripts (`push-gate.py`, etc.) |
| `scripts/` | `bootstrap-gsd-workflow.sh` helpers, smoke, installer |
| `personal-skills.manifest` | Canonical list of skills managed by the Personal Agents Hub |
| `ADDING-SKILLS.md` | Add / update hub-managed skills (single SoT) |

## Readiness ladder

```text
1. install-client-ai-overlay.sh     -> skills (symlinked)
2. bootstrap-gsd-workflow.sh        -> .gsd/ REQUIRED
3. $gsd-plan-milestone              -> ROADMAP
4. do next / $do-next-runner        -> custom workflow execution
   -- or $gsd-advance-unit          -> pure GSD one unit
```

## Bootstrap (client repo)

```bash
bash /path/to/ai-playbook/scripts/bootstrap-gsd-workflow.sh \\
  --source-repo /path/to/ai-playbook \\
  --client-repo /path/to/client \\
  --platform universal \\
  --harness-context \\
  --init-gsd --with-do-next --patch-mcp
```

`--platform` + `--harness-context` seed **platform-specific** `.gsd/DELIVERY-PROFILE.md` and
`.cursor/skills/*/platform.md` from `templates/platforms/<platform>/`. Always customize for the client.

For `--platform universal`, harness/bootstrap auto-detect project style and choose from:

- `templates/platforms/universal/php/`
- `templates/platforms/universal/node/`
- `templates/platforms/universal/react-native-mono/`
- `templates/platforms/universal/python/`
- fallback `templates/platforms/universal/`

Override auto-detection with `--project-style <style>`.

## Personal Agents Hub

The **Personal Agents Hub** centralizes skill management at `~/.agents/skills`
with symlink bridges to `~/.cursor/skills` and `~/.claude/skills`.

```bash
# Full install (all skills from manifest)
bash scripts/install-personal-agents-hub.sh

# Update a single skill
bash scripts/update-personal-skill.sh ticket-to-plan

# Dry run
bash scripts/install-personal-agents-hub.sh --dry-run
```

The canonical skill list lives in `personal-skills.manifest`. Platform overlays
no longer carry copies of SoT skills (do-next, do-next-runner, gsd-plan-milestone,
gsd-advance-unit, ticket-to-plan, verified-pr-review, graphify-obsidian).

### Hub layout

```text
~/.agents/skills/           # Hub (SoT copies)
  do-next/SKILL.md
  do-next-runner/SKILL.md
  gsd-plan-milestone/SKILL.md
  ...
~/.cursor/skills/do-next -> ~/.agents/skills/do-next   # Bridge
~/.claude/skills/do-next -> ~/.agents/skills/do-next   # Bridge
~/.playbook-hub-lock.json   # Version lockfile (home dir — not under ~/.agents/skills)
```

## Adding or updating skills

Author under `shared/gsd/`, register in `personal-skills.manifest`, then refresh the hub or a client. Full guide: **[ADDING-SKILLS.md](ADDING-SKILLS.md)**.

1. Edit SoT (`skills/<name>/` or `idea/<name>/templates/`) — do not copy into platform overlay trees.
2. Register new skills in `personal-skills.manifest`.
3. Personal: `bash scripts/update-personal-skill.sh <name>` (or `install-personal-agents-hub.sh --force`).
4. Client: `bash shared/gsd/scripts/install-workflow-tools.sh --project …` (pass flat skills via `--tools` when needed).

## Harness project context only

```bash
bash shared/gsd/scripts/harness-gsd-project-context.sh \\
  --source-repo /path/to/ai-playbook \\
  --client-repo /path/to/client \\
  --platform universal
```

## Install skills only (no overlay)

```bash
bash shared/gsd/scripts/install-workflow-tools.sh \\
  --project --cursor --claude --copilot \\
  --repo /path/to/client
```

Flat skills (ticket-to-plan, verified-pr-review, graphify-obsidian) are supported
but NOT included in the default `--tools` list. Add them explicitly:

```bash
bash shared/gsd/scripts/install-workflow-tools.sh \\
  --project --cursor --claude \\
  --tools do-next,do-next-runner,gsd-plan-milestone,gsd-advance-unit,ticket-to-plan,verified-pr-review,graphify-obsidian \\
  --repo /path/to/client
```

## Personal global skills

Prefer the Personal Agents Hub (`install-personal-agents-hub.sh`) over direct
`install-workflow-tools.sh --personal`. The hub provides lockfile tracking,
bridges, and flat skill support.

**Copilot** has no personal hub path — use project install with `--copilot` only
(`.github/instructions/`). Cursor and Claude use hub bridges under `~/.cursor/skills`
and `~/.claude/skills`.

## Platform packs

Platform-specific context files live in `templates/platforms/<platform>/`:

| Platform | Files |
|----------|-------|
| `ios` | `platform.md`, `platform.gsd-plan-milestone.md`, `DELIVERY-PROFILE.md` |
| `android` | `platform.md`, `platform.gsd-plan-milestone.md` |
| `flutter-riverpod` | `platform.md`, `platform.gsd-plan-milestone.md` |
| `flutter-bloc` | `platform.md`, `platform.gsd-plan-milestone.md` |
| `universal` | `platform.md`, `platform.gsd-plan-milestone.md`, `DELIVERY-PROFILE.md` + sub-styles |
