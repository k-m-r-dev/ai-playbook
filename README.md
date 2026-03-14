# AI Playbooks Repository Template

This folder is a starter layout for storing AI playbooks in your own private Git repository, for example a personal GitHub repository named `ai-playbook`, and installing them into client projects without committing them to the client repository.

## Recommended Repository Layout

```text
ai-playbook/
  ios/
  android/
  scripts/
    bootstrap-playbooks-from-aitools.sh
    install-client-ai-overlay.sh
    uninstall-client-ai-overlay.sh
```

## What Goes In The Platform Folders

- `ios/`: copy the contents of `aitools/ios/`
- `android/`: copy the contents of `aitools/android/`

## Bootstrap Example

If you already have a repository that contains `aitools/ios` and `aitools/android`, you can populate this repository template automatically:

1. Create or clone your private `ai-playbook` repository.
2. Copy the `scripts/` folder from this template into that repository.
3. Run the bootstrap script from this repository, pointing `--source-repo` at the repo that contains `aitools/` and `--dest-repo` at your private `ai-playbook` repo.
4. Review the generated `ios/` and `android/` folders in your private repo, then commit and push them.

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
- `skills-lock.json`
- `.claude/skills`
- `.cursor/rules`
- `.github/agents`
- `.github/instructions`

That layout avoids replacing the entire `.github/`, `.claude/`, or `.cursor/` directories and reduces the risk of clobbering client-owned files.

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

## Recommended Daily Workflow

1. Keep the source of truth in your own private repository, for example `ai-playbook`.
2. Use `bootstrap-playbooks-from-aitools.sh` once to seed `ios/` and `android/` from a repository that already contains `aitools/`.
3. Install the overlay into the client repository locally using `symlink` mode.
4. Confirm `git status` in the client repository shows no staged or tracked AI overlay files.
5. Use `copy` mode only if a specific tool does not follow symlinks correctly.

## Ownership Protection Notes

- This keeps your playbooks out of the client's Git history.
- It does not automatically keep the content out of AI vendor backends if the tool reads those files from the workspace.
- If you need both Git privacy and model-processing restrictions, configure the AI tools with the correct enterprise privacy settings too.
