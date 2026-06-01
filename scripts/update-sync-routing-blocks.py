#!/usr/bin/env python3
"""Update SYNC routing blocks for wrapper model across all platform overlays."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REPLACEMENTS = [
    (
        "- **`ARCHITECTURE.md`** — canonical **structure** (layers, modules, boundaries, verification). With default overlay it is usually a **symlink** to your shared `ai-playbook`; refine it there, not via client-only edits to the symlink path.",
        "- **`_ARCHITECTURE.md`** — playbook **template** (symlink to shared `ai-playbook`). Refine in ai-playbook, not in the client repo.\n"
        "- **`ARCHITECTURE.md`** — **project wrapper** (committed): `@_ARCHITECTURE.md` + `## Project Layout` for client-specific paths, modules, and diagrams.",
    ),
    (
        "- **`SESSION_WORKFLOW.md`** — canonical **process** (templates, lifecycle, verification). With default overlay it is usually a **symlink** to your shared `ai-playbook`; refine it there, not via client-only edits to the symlink path.",
        "- **`_SESSION_WORKFLOW.md`** — playbook **process** (symlink to shared `ai-playbook`). Refine in ai-playbook, not in the client repo.\n"
        "- **`SESSION_WORKFLOW.md`** — **project wrapper** (committed): `@_SESSION_WORKFLOW.md` only.",
    ),
    (
        "do not treat `SESSION_WORKFLOW.md` as editable project state when it is a symlink.",
        "use **`.workflow/`** for session scratch.",
    ),
]

patterns = ("15-architecture.mdc", "20-session-progress.mdc", "architecture.instructions.md", "session-progress.instructions.md", "architecture-playbook/SKILL.md", "session-progress-workflow/SKILL.md")

changed = 0
for platform in ("universal", "ios", "android", "flutter-riverpod", "flutter-bloc"):
    base = ROOT / platform
    if not base.is_dir():
        continue
    for path in base.rglob("*"):
        if not path.is_file():
            continue
        if not any(part in path.as_posix() for part in patterns):
            continue
        text = path.read_text()
        original = text
        for old, new in REPLACEMENTS:
            text = text.replace(old, new)
        if text != original:
            path.write_text(text)
            changed += 1
            print(path.relative_to(ROOT))

print(f"Updated {changed} files")
