# Configure client: GSD, W2C, or none

Date: 2026-08-17
Status: approved (design sections 1–4)
Repo: ai-playbook (operator skill + scripts + overlay templates)

## Goal

`/configure-client-project` can bring up a client with an exclusive **planning engine**: GSD, W2C, or none. Overlay architecture files stay engine-agnostic so client **symlinks** do not pull GSD/graphify/ruflo. A new CLI orchestrator performs writes; the skill only interviews and then calls that CLI.

Out of scope for this change: re-running configure on `bitoron_mobile` (follows after this lands). Graphify/codeintel Cursor rules stay in platform packs but are not required in `_CLAUDE.md`.

## Locked decisions

| Topic | Choice |
| --- | --- |
| Engine | Exclusive: `gsd` \| `w2c` \| `none`. Never both. |
| Overlay `_AGENTS.md` / `_CLAUDE.md` | Architecture-only. No GSD skill tables, bootstrap gates, graphify, ruflo, openGSD. |
| Engine text | Committed wrappers `AGENTS.md` / `CLAUDE.md` only. |
| W2C install | Full `install-w2c-to-project.sh`. Default `--mode symlink`: `.w2c/scripts` and `.w2c/templates` are directory symlinks to `shared/w2c/{scripts,templates}`. Ledger files (`STATE.md`, plans) stay real files in the client. `--mode copy` for machines without a playbook checkout. Gitignore the two symlink dirs. |
| Default engine | `w2c` if client has no `.gsd/`; `gsd` if `.gsd/` exists. |
| Implementation shape | New `scripts/configure-client-project.sh`; skill is a thin wrapper. |

## Architecture

Three layers, one write path:

```
skill (interview) → configure-client-project.sh → existing installers
                                              ↘ wrapper patch (markers)
```

- **Skill** (`configure-client-project`): discover, one question at a time, confirmation gate, then a **single** orchestrator invocation. Does not call overlay/bootstrap/w2c scripts itself.
- **Orchestrator** (`scripts/configure-client-project.sh`): validates args, runs approved installers, patches wrappers.
- **Installers:** `install-client-ai-overlay.sh` and `bootstrap-gsd-workflow.sh` keep current flags. `install-w2c-to-project.sh` gains `--mode symlink|copy` (default `symlink`) and gitignores `.w2c/scripts/` + `.w2c/templates/` + `.w2c/runtime/`.

`configure-client-check.sh` stays read-only and is the verification surface for both the skill and `--check`.

## Components

### 1. `scripts/configure-client-project.sh`

Required:

```bash
--source-repo PATH
--client-repo PATH
--platform PLATFORM
--engine gsd|w2c|none
```

Optional: `--mode symlink` (default), `--existing-policy merge` (default), `--check`, `--dry-run`.

GSD-only flags: `--init-gsd`, `--with-do-next`, `--patch-mcp`, `--harness-context`, `--force`. Allowed only with `--engine gsd`; any of these with `--engine w2c` or `none` is an error.

| `--engine` | Runs |
| --- | --- |
| `gsd` | overlay → `bootstrap-gsd-workflow.sh` with GSD flags → wrapper patch (`gsd`) |
| `w2c` | overlay → `install-w2c-to-project.sh --repo CLIENT --source-repo PLAYBOOK --mode $MODE` → wrapper patch (`w2c`) |
| `none` | overlay → wrapper patch (`none`) |

`--check`: print overlay + GSD + W2C gap lines; no writes. May delegate to existing bootstrap `--check` plus new W2C probes (`[MISSING] .w2c/scripts/`, etc.).

`--dry-run`: print the plan (engine, installers, wrapper markers) without writing.

`--engine w2c` with GSD flags: **error**. Same for `--engine none` plus GSD flags.

`--engine gsd` does not install W2C. `--engine w2c` does not create `.gsd/` or MCP.

### 2. `scripts/configure-client-check.sh`

Keep current GSD/overlay/MCP probes. Add W2C probes:

- `[OK]` / `[MISSING]` `.w2c/scripts/w2c.py` (file or via directory symlink)
- `[OK]` / `[MISSING]` `.w2c/templates/` (dir or symlink to playbook templates)
- `[OK]` / `[MISSING]` `.github/instructions/work-to-chores.instructions.md`

Discover line: if `.gsd/` exists, note default engine would be `gsd`; else `w2c`.

The check script still reports all gaps. The **skill** treats missing GSD as SKIPPED after `w2c`/`none` (not FAIL).

### 2b. `scripts/install-w2c-to-project.sh`

Add `--mode symlink` (default) and `--mode copy`.

- **symlink:** `ln -sfn` playbook `shared/w2c/scripts` → client `.w2c/scripts`, and `shared/w2c/templates` → client `.w2c/templates`. If a real directory already exists at those paths, refuse unless `--force` (do not delete a copied tree without asking).
- **copy:** current `cp` behavior for those two dirs.
- **Always:** Copilot instruction files stay copied (not symlinked). Ledger `init` still writes real `STATE.md` / `DECISIONS.md` and never overwrites them. Gitignore `.w2c/scripts/`, `.w2c/templates/`, `.w2c/runtime/`.
- Orchestrator passes the same `--mode` it uses for overlay.


### 3. Overlay templates (all platform packs)

Packs: `universal/`, `ios/`, `android/`, `flutter-riverpod/`, `flutter-bloc/`.

- `_AGENTS.md`: drop GSD skill rows and “GSD prerequisite” bootstrap gate. Keep Flutter/platform skills and architecture routing.
- `_CLAUDE.md`: drop the `## graphify` section. Keep usage / include list.
- Copied `AGENTS.md` / `CLAUDE.md`: generic stubs (`@_` include + empty Learned sections, stack placeholders). Remove Furqan/Library/Azure/GSD/graphify/ruflo facts from `flutter-riverpod/AGENTS.md` and equivalent contamination on other packs if present.
- Flutter `CLAUDE.md` stack placeholders: `flutter analyze` / `flutter test` / `flutter build …`, not `npm`.

Existing symlink clients pick up `_AGENTS.md` / `_CLAUDE.md` as soon as this repo is updated. Committed wrappers need an orchestrator re-run.

### 4. Wrapper patch

Orchestrator patches **committed** `AGENTS.md` and `CLAUDE.md` only.

Idempotent block:

```markdown
<!-- BEGIN PLAYBOOK:PLANNING-ENGINE -->
## Planning engine
…engine-specific bullets…
<!-- END PLAYBOOK:PLANNING-ENGINE -->
```

| Engine | Meaning |
| --- | --- |
| `gsd` | Use GSD (`.gsd/`, gsd-workflow MCP). Do not use `.w2c/` or work-to-chores. |
| `w2c` | Use work-to-chores / do-chores (`.w2c/`). Python CLI owns STATE/QUEUE checkboxes. Do not use GSD / `$gsd-plan-milestone` / do-next. |
| `none` | No GSD and no W2C. Do not scaffold `.gsd/` or `.w2c/` unless asked. |

Also strip leftover GSD/graphify/ruflo/openGSD learned bullets from those wrappers if they match the old overlay template (so a re-run on a contaminated client is safe). Do not delete unrelated learned facts.

`CLAUDE.md`: do not restore GSD-Pi / graphify topography / ruflo sections. Keep `.workflow/` session scratch.

### 5. Skill + USAGE

Keep byte-synced:

- `.cursor/skills/configure-client-project/SKILL.md`
- `.cursor/skills/configure-client-project/USAGE.md`
- `shared/gsd/skills/configure-client-project/SKILL.md`
- `shared/gsd/skills/configure-client-project/USAGE.md`

Interview order:

1. Discover (`configure-client-check.sh`).
2. Platform.
3. Planning engine (defaults as locked).
4. Overlay gap if missing.
5. Engine-specific gaps only (GSD: current set; W2C: confirm full install; none: skip ledger gaps).
6. Confirmation listing engine + flags + wrapper plan.
7. One `configure-client-project.sh` call.
8. Verify `--check`. Handoff: GSD → `$gsd-plan-milestone`; W2C → `work to chores`; none → overlay only.

Hard rules from the current skill (one question at a time, no silent skips of in-scope gaps, confirm before write) stay.

Skill location remains under `shared/gsd/skills/` for hub install; behavior is no longer GSD-only.

## Data flow

1. Skill runs check → gap inventory (all engines visible).
2. User picks platform + engine + in-scope fixes.
3. Skill builds argv (never `--engine w2c` plus `--init-gsd`).
4. Orchestrator: overlay → engine installer → wrapper markers.
5. Skill re-runs check; reports PASS / FAIL / SKIPPED. Missing GSD after `w2c`/`none` is SKIPPED, not FAIL.

## Error handling

- Missing/invalid `--engine` or `--platform`: exit 1 with usage.
- Client not a git repo: fail before writes (same as overlay installer).
- `--engine w2c|none` with GSD flags: exit 1.
- Overlay install failure: stop; do not patch wrappers.
- W2C or GSD installer failure: stop; do not claim success; skip wrapper patch if it is the last step and prior step failed.
- Wrapper files missing after overlay: fail (overlay should have created them).
- Re-run: overlay `--existing-policy merge`; W2C installer must not clobber existing `DECISIONS.md` / `STATE.md` (already true); planning-engine markers replaced in place.

## Testing

- Orchestrator `--check` reports overlay/GSD/W2C lines without writing.
- `--dry-run --engine w2c` does not create `.w2c/` or edit wrappers.
- `--engine none` does not create `.gsd/` or `.w2c/`.
- `--engine w2c --init-gsd` exits non-zero.
- `--engine w2c` (default mode): `.w2c/scripts` and `.w2c/templates` are symlinks into the playbook; `STATE.md` is a regular file.
- Platform `_AGENTS.md` / `_CLAUDE.md` contain no required-workflow mentions of `gsd-plan-milestone`, `openGSD`, `graphify-out`, or `ruflo`.
- Second wrapper patch keeps a single pair of `BEGIN/END PLAYBOOK:PLANNING-ENGINE` markers.
- Add `scripts/configure-client-project.test.sh` (run directly with bash). No new CI test runner.

## Docs to update (same change)

- Skill SKILL.md + USAGE.md (both copies).
- `FRAMEWORK.md` / `README.md` / `shared/gsd/README.md` configure paragraphs: engine choice and the new script.
- Do not document “merge MCP manually” as homework when the user approved GSD MCP (existing rule).

## Success criteria

- Operator can configure GSD, W2C, or none through the skill or the CLI.
- New overlay symlink clients do not inherit GSD/graphify/ruflo from `_AGENTS.md` / `_CLAUDE.md`.
- W2C clients get `.w2c/scripts/` and wrapper text that forbids GSD.
- `flutter-riverpod` copied `AGENTS.md` no longer ships another client’s learned facts.
- After merge, a later configure of `bitoron_mobile` with `--engine w2c` can refresh committed wrappers; symlink policy files are already fixed.
