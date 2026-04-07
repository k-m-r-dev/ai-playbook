# AI Playbooks Repository Template

This folder is a starter layout for storing AI playbooks in your own private Git repository, for example a personal GitHub repository named `ai-playbook`, and installing them into client projects without committing them to the client repository.

## Recommended Repository Layout

```text
ai-playbook/
  ios/
  android/
  flutter-riverpod/
  flutter-bloc/
  scripts/
    bootstrap-playbooks-from-aitools.sh
    install-client-ai-overlay.sh
    uninstall-client-ai-overlay.sh
```

## What Goes In The Platform Folders

- `ios/`: copy the contents of `aitools/ios/`
- `android/`: copy the contents of `aitools/android/`
- `flutter-riverpod/`: copy the contents of `aitools/flutter-riverpod/`
- `flutter-bloc/`: copy the contents of `aitools/flutter-bloc/`

## Bootstrap Example

If you already have a repository that contains `aitools/ios`, `aitools/android`, and optional Flutter variants (`aitools/flutter-riverpod`, `aitools/flutter-bloc`), you can populate this repository template automatically:

1. Create or clone your private `ai-playbook` repository.
2. Copy the `scripts/` folder from this template into that repository.
3. Run the bootstrap script from this repository, pointing `--source-repo` at the repo that contains `aitools/` and `--dest-repo` at your private `ai-playbook` repo.
4. Review the generated platform folders in your private repo, then commit and push them.

```bash
# example: seed ~/private/ai-playbook from this repository
bash scripts/bootstrap-playbooks-from-aitools.sh \
  --source-repo ~/workspace/template-source \
  --dest-repo ~/private/ai-playbook \
  --platform all
```

Use `--force` only when you intentionally want to replace existing playbook contents.

The bootstrap script copies:

- `aitools/ios` into `ai-playbook/ios`
- `aitools/android` into `ai-playbook/android`
- `aitools/flutter-riverpod` into `ai-playbook/flutter-riverpod`
- `aitools/flutter-bloc` into `ai-playbook/flutter-bloc`

Each platform folder in this template includes **session workflow** assets—root `.workflow/` (three markdown files) and `SESSION_WORKFLOW.md` at the same level as `AGENTS.md`—so bootstrapping from `aitools/` should carry the same layout into your private playbook. When you refresh from a source repo, ensure `aitools/<platform>` also contains those paths if you want them updated.

It is meant for initializing or refreshing your private playbook repository, not for installing files into a client project. For client projects, use `install-client-ai-overlay.sh` instead.

## Safety Model

- Files are installed only into the local client checkout
- Managed state is stored in the client repository's `.git` directory
- Managed paths are added to `.git/info/exclude`, not the shared `.gitignore`
- The installer aborts if a target path already exists and is not already managed by the installer

## Installed Paths

The installer manages these paths inside the client repository root:

- `AGENTS.md`
- `CLAUDE.md`
- `ARCHITECTURE.md`
- `skills-lock.json`
- `.claude/skills`
- `.cursor/rules`
- `.github/agents`
- `.github/instructions`
- `.workflow/` (session progress scratch pad, archive, and tracker)
- `SESSION_WORKFLOW.md` (playbook for maintaining those files; repository root)

That layout avoids replacing the entire `.github/`, `.claude/`, or `.cursor/` directories and reduces the risk of clobbering client-owned files.

**Session workflow install mode:** `.workflow/` is **always copied** so session logs and trackers stay real files in the client checkout. **`SESSION_WORKFLOW.md` follows `--mode`** like `AGENTS.md`, `CLAUDE.md`, and `ARCHITECTURE.md` (default symlink to your private `ai-playbook`). Use **`--mode copy`** for the whole overlay when a tool does not follow symlinks.

## Install Example

```bash
bash scripts/install-client-ai-overlay.sh \
  --source-repo ~/private/ai-playbook \
  --client-repo ~/clients/acme-ios-app \
  --platform ios \
  --mode symlink
```

## Uninstall Example

```bash
bash scripts/uninstall-client-ai-overlay.sh \
  --client-repo ~/clients/acme-ios-app \
  --platform ios
```

Flutter example:

```bash
bash scripts/install-client-ai-overlay.sh \
  --source-repo ~/private/ai-playbook \
  --client-repo ~/clients/acme-flutter-app \
  --platform flutter-riverpod \
  --mode symlink
```

## Add `SESSION_WORKFLOW.md` to an existing overlay

If a client repo was overlaid **before** `SESSION_WORKFLOW.md` existed in the installer mappings, the playbook file will be missing at the repo root even though `AGENTS.md` / `.cursor/rules` / etc. are present. Run:

```bash
bash scripts/add-session-workflow-to-overlay.sh \
  --source-repo ~/private/ai-playbook \
  --client-repo ~/Workspace/self/Furqan \
  --platform flutter-riverpod
```

If that client overlay was installed with **`--mode copy`**, pass the same mode:

```bash
bash scripts/add-session-workflow-to-overlay.sh \
  --source-repo ~/private/ai-playbook \
  --client-repo ~/Workspace/self/Furqan \
  --platform flutter-riverpod \
  --mode copy
```

Match `--platform`, `--source-repo`, and **`--mode`** to how you ran `install-client-ai-overlay.sh`. The script requires an existing overlay manifest under `.git/ai-playbook/`.

## Recommended Daily Workflow

1. Keep the source of truth in your own private repository, for example `ai-playbook`.
2. Use `bootstrap-playbooks-from-aitools.sh` once to seed the platform folders you need (`ios`, `android`, `flutter-riverpod`, `flutter-bloc`) from a repository that already contains `aitools/`.
3. Install the overlay into the client repository locally using `symlink` mode.
4. Confirm `git status` in the client repository shows no staged or tracked AI overlay files.
5. Use `copy` mode only if a specific tool does not follow symlinks correctly.

## Ownership Protection Notes

- This keeps your playbooks out of the client's Git history.
- It does not automatically keep the content out of AI vendor backends if the tool reads those files from the workspace.
- If you need both Git privacy and model-processing restrictions, configure the AI tools with the correct enterprise privacy settings too.
