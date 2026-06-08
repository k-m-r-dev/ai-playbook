#!/usr/bin/env python3
"""Append a unit report to do-next-runner run logs (JSONL + markdown summary)."""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path


def find_repo_root(start: Path) -> Path:
    path = start.resolve()
    for candidate in (path, *path.parents):
        if (candidate / ".gsd").is_dir():
            return candidate
    raise SystemExit(f"Could not find .gsd/ above {start}")


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Append do-next-runner unit report")
    p.add_argument("--run-id", required=True)
    p.add_argument("--milestone", required=True)
    p.add_argument("--slice", default="")
    p.add_argument("--task", default="")
    p.add_argument("--unit-type", required=True, choices=["task", "slice", "gate", "plan", "dry-run"])
    p.add_argument("--smoke", default="PASS")
    p.add_argument("--verification-cmd", default="")
    p.add_argument("--verification-exit", type=int, default=None)
    p.add_argument("--files", default="", help="Comma-separated changed files")
    p.add_argument("--commit", default="")
    p.add_argument("--next-action", default="")
    p.add_argument("--blockers", default="", help="Comma-separated blockers")
    p.add_argument("--notes", default="")
    return p.parse_args()


def main() -> int:
    args = parse_args()
    root = find_repo_root(Path(__file__))
    runtime = root / ".gsd" / "runtime" / "do-next-runner"
    runtime.mkdir(parents=True, exist_ok=True)

    ts = datetime.now(timezone.utc).isoformat()
    entry = {
        "ts": ts,
        "runId": args.run_id,
        "milestone": args.milestone,
        "slice": args.slice or None,
        "task": args.task or None,
        "unitType": args.unit_type,
        "smoke": args.smoke,
        "verification": {
            "command": args.verification_cmd or None,
            "exitCode": args.verification_exit,
        },
        "filesChanged": [f.strip() for f in args.files.split(",") if f.strip()],
        "commit": args.commit or None,
        "nextAction": args.next_action or None,
        "blockers": [b.strip() for b in args.blockers.split(",") if b.strip()],
        "notes": args.notes or None,
    }

    jsonl_path = runtime / f"RUN-{args.run_id}.jsonl"
    with jsonl_path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")

    summary_path = runtime / f"RUN-{args.run_id}-summary.md"
    lines = [
        f"## {ts} — {args.unit_type.upper()}",
        "",
        f"- **Milestone:** {args.milestone}",
    ]
    if args.slice:
        lines.append(f"- **Slice:** {args.slice}")
    if args.task:
        lines.append(f"- **Task:** {args.task}")
    lines.extend([
        f"- **Smoke:** {args.smoke}",
    ])
    if args.verification_cmd:
        exit_str = str(args.verification_exit) if args.verification_exit is not None else "—"
        lines.append(f"- **Verification:** `{args.verification_cmd}` (exit {exit_str})")
    if entry["filesChanged"]:
        lines.append(f"- **Files:** {', '.join(entry['filesChanged'])}")
    if args.commit:
        lines.append(f"- **Commit:** `{args.commit}`")
    if args.next_action:
        lines.append(f"- **Next:** {args.next_action}")
    if entry["blockers"]:
        lines.append(f"- **Blockers:** {', '.join(entry['blockers'])}")
    if args.notes:
        lines.append(f"- **Notes:** {args.notes}")
    lines.append("")

    header = f"# Run {args.run_id}\n\n"
    if not summary_path.exists():
        summary_path.write_text(header, encoding="utf-8")
    with summary_path.open("a", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")

    print(json.dumps({"jsonl": str(jsonl_path), "summary": str(summary_path), "entry": entry}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
