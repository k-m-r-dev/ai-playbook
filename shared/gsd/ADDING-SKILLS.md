# Adding and updating playbook skills

Single source of truth (SoT) for hub-managed skills lives under **`shared/gsd/`**.  
Do **not** copy assembled skills into `universal/`, `ios/`, `android/`, or `flutter-*` platform trees.  
Do **not** run `scripts/sync-gsd-skills-to-overlays.sh` (retired — it refuses).

Canonical list: [`personal-skills.manifest`](personal-skills.manifest).  
Personal install: [`scripts/install-personal-agents-hub.sh`](../../scripts/install-personal-agents-hub.sh).  
Update one skill: [`scripts/update-personal-skill.sh`](../../scripts/update-personal-skill.sh).

---

## Mental model

```text
shared/gsd/… (edit here)
        │
        ├─► Personal hub     bash scripts/install-personal-agents-hub.sh
        │                     ~/.agents/skills/<name>  + bridges → ~/.cursor + ~/.claude
        │                     optional --codex → ~/.codex/skills
        │
        └─► Client project   bash shared/gsd/scripts/install-workflow-tools.sh --project …
                              (or bootstrap-gsd-workflow.sh --with-do-next)
```

Platform-specific verify/read-order text goes in **`templates/platforms/<platform>/`**, not in forked `SKILL.md` copies.

---

## Update an existing skill

1. Edit SoT only:
   - **Assembled** — `idea/<name>/templates/` or `skills/<name>/` (`SKILL.body.md` + `SKILL.cursor.md` / wrappers)
   - **Flat** — `skills/<name>/SKILL.md` (e.g. `ticket-to-plan`, `verified-pr-review`, `graphify-obsidian`)
2. Refresh your machine:

```bash
cd /path/to/ai-playbook
bash scripts/update-personal-skill.sh <skill-name>
# or all manifest skills:
bash scripts/update-personal-skill.sh --all
```

3. Commit and push the playbook change.
4. Refresh **client** repos (project-local skills, not the hub):

```bash
bash shared/gsd/scripts/install-workflow-tools.sh \
  --project --cursor --claude --copilot \
  --repo /path/to/client
```

Flat skills are **not** in the default `--tools` list — pass them explicitly when needed:

```bash
--tools do-next,do-next-runner,gsd-plan-milestone,gsd-advance-unit,ticket-to-plan,verified-pr-review,graphify-obsidian
```

---

## Add a new skill

### 1. Choose layout

| Layout | When | Paths |
|--------|------|--------|
| **flat** | One `SKILL.md`, no per-IDE wrappers | `shared/gsd/skills/<name>/SKILL.md` |
| **assembled** | Shared body + thin Cursor/Copilot wrappers | `shared/gsd/skills/<name>/SKILL.body.md` + `SKILL.cursor.md` (+ `SKILL.copilot.md` if Copilot matters) |

`do-next` / `do-next-runner` live under `shared/gsd/idea/<name>/templates/` (same assemble pattern). Prefer that layout only for that family.

### 2. Author the skill

- Frontmatter: `name`, `description` (and other IDE fields as needed).
- Keep process in the body; do not bind platform-specific verify commands into the skill — use `platform.md` packs.
- For assemble skills, put IDE-neutral steps in `SKILL.body.md`; wrappers only route/invoke.

### 3. Register in the manifest

Edit [`personal-skills.manifest`](personal-skills.manifest):

```text
my-skill    flat        skills/my-skill
# or
my-skill    assembled   skills/my-skill
```

Paths are relative to `shared/gsd/`.

### 4. Install to the Personal Agents Hub

```bash
bash scripts/install-personal-agents-hub.sh --force --skills my-skill

# Optional Codex bridge (skips existing real dirs unless --force):
bash scripts/install-personal-agents-hub.sh --force --skills my-skill --codex

# Preview:
bash scripts/install-personal-agents-hub.sh --dry-run --skills my-skill
```

This writes `~/.agents/skills/my-skill/`, symlinks `~/.cursor/skills/my-skill` and `~/.claude/skills/my-skill`, and updates `~/.playbook-hub-lock.json`.

### 5. Ship to client projects (optional)

```bash
bash shared/gsd/scripts/install-workflow-tools.sh \
  --project --cursor --claude --copilot \
  --tools my-skill \
  --repo /path/to/client
```

Or include `my-skill` in a broader `--tools` list / bootstrap `--with-do-next` flow when it belongs with the GSD set.

### 6. Platform-specific context (optional)

If the skill needs stack-specific verify/read order, add or extend packs under:

```text
shared/gsd/templates/platforms/<platform>/
```

Harness/bootstrap copies those into the **client** at install time. Do not bake a permanent fork under platform overlay skill dirs.

### 7. Docs and verify

- Mention the skill in [`README.md`](README.md) / [`FRAMEWORK.md`](../../FRAMEWORK.md) only if it is part of the default GSD ladder.
- Run:

```bash
bash shared/gsd/scripts/verify-sync.sh
```

---

## What not to do

| Anti-pattern | Do this instead |
|--------------|-----------------|
| Copy `SKILL.md` into `universal/.cursor/skills/…` | Hub + `--project` install from `shared/gsd` |
| Edit `~/.agents/skills/…` by hand as SoT | Edit playbook, then `update-personal-skill.sh` |
| Run `sync-gsd-skills-to-overlays.sh` | It exits 1 by design |
| Put client-only verify cmds in the skill body | `templates/platforms/<platform>/platform.md` |
| Expect Copilot personal skills under `~/.github` | Copilot is project-local via `--project --copilot` only |

---

## Quick reference

| Goal | Command |
|------|---------|
| Install / refresh all hub skills | `bash scripts/install-personal-agents-hub.sh --force` |
| Update one skill | `bash scripts/update-personal-skill.sh <name>` |
| Dry run | `bash scripts/install-personal-agents-hub.sh --dry-run` |
| Client GSD defaults | `install-workflow-tools.sh --project --cursor --claude --copilot --repo …` |
| Client + flat orphans | same + `--tools …,ticket-to-plan,…` |
| Drift check | `bash shared/gsd/scripts/verify-sync.sh` |

Related: [shared/gsd/README.md](README.md) · [FRAMEWORK.md](../../FRAMEWORK.md) · [EXTENDING.md](../../EXTENDING.md)
