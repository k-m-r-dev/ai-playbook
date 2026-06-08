#!/usr/bin/env python3
"""Check whether slice plan authorizes push after slice complete.

Exit 0 — push allowed (push_after_slice: true or push: approved in S##-PLAN.md)
Exit 1 — push blocked (default)
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


def find_repo_root(start: Path) -> Path:
    path = start.resolve()
    for candidate in (path, *path.parents):
        if (candidate / ".gsd").is_dir():
            return candidate
    raise SystemExit(f"Could not find .gsd/ above {start}")


def slice_plan_path(root: Path, milestone: str, slice_id: str) -> Path:
    return root / ".gsd" / "milestones" / milestone / "slices" / slice_id / f"{slice_id}-PLAN.md"


def push_authorized(plan_text: str) -> bool:
    """True if slice plan explicitly allows push after slice."""
    if re.search(r"push_after_slice:\s*true", plan_text, re.IGNORECASE):
        return True
    if re.search(r"push:\s*approved", plan_text, re.IGNORECASE):
        return True
    # Explicit deny
    if re.search(r"push_after_slice:\s*false", plan_text, re.IGNORECASE):
        return False
    return False


def main() -> int:
    p = argparse.ArgumentParser(description="Slice push authorization gate")
    p.add_argument("--milestone", required=True, help="e.g. M001")
    p.add_argument("--slice", required=True, help="e.g. S03")
    args = p.parse_args()

    root = find_repo_root(Path(__file__))
    plan_path = slice_plan_path(root, args.milestone, args.slice)

    if not plan_path.is_file():
        print(f"BLOCKED: slice plan not found: {plan_path}", file=sys.stderr)
        return 1

    text = plan_path.read_text(encoding="utf-8")
    if push_authorized(text):
        print(f"ALLOWED: {args.slice} has push authorization in {plan_path.name}")
        return 0

    print(
        f"BLOCKED: {args.slice} has no push_after_slice: true or push: approved in {plan_path.name}",
        file=sys.stderr,
    )
    return 1


if __name__ == "__main__":
    sys.exit(main())
