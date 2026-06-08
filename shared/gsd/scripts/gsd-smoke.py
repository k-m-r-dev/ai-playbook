#!/usr/bin/env python3
"""Dry-run smoke checks for GSD milestone workflow (no product code changes).

Validates:
  1. Plan coherence — total tasks (md/db/files) and pending tasks (md unchecked vs DB)
  2. Gate-evaluate readiness — Q3/Q4 status for the active slice
  3. STATE.md sync — detects stale phase when DB gates are done but STATE lags

Usage:
  python3 .workflow/scripts/gsd-smoke.py
  python3 .workflow/scripts/gsd-smoke.py --milestone M001
  python3 .workflow/scripts/gsd-smoke.py --rebuild-state   # refresh STATE.md from DB
"""

from __future__ import annotations

import argparse
import json
import re
import sqlite3
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path

GATE_EVALUATE_IDS = ("Q3", "Q4")
SLICE_IDS = ("S01", "S02", "S03", "S04", "S05")


@dataclass
class Check:
    name: str
    status: str  # PASS | FAIL | WARN
    detail: str = ""


@dataclass
class Report:
    checks: list[Check] = field(default_factory=list)

    def add(self, name: str, status: str, detail: str = "") -> None:
        self.checks.append(Check(name, status, detail))

    @property
    def failed(self) -> bool:
        return any(c.status == "FAIL" for c in self.checks)

    def print(self) -> None:
        print("=== GSD smoke ===")
        for c in self.checks:
            line = f"[{c.status}] {c.name}"
            if c.detail:
                line += f" — {c.detail}"
            print(line)
        print()
        if self.failed:
            print("Result: FAIL")
        elif any(c.status == "WARN" for c in self.checks):
            print("Result: PASS (with warnings)")
        else:
            print("Result: PASS")


def find_repo_root(start: Path) -> Path:
    path = start.resolve()
    for candidate in (path, *path.parents):
        if (candidate / ".gsd").is_dir():
            return candidate
    raise SystemExit(f"Could not find .gsd/ above {start}")


def parse_state_field(content: str, label: str) -> str:
    match = re.search(rf"\*\*{re.escape(label)}:\*\*\s*(.+)$", content, re.MULTILINE)
    return match.group(1).strip() if match else ""


def parse_next_action(content: str) -> str:
    match = re.search(r"## Next Action\s*\n(.+?)(?:\n## |\Z)", content, re.DOTALL)
    if not match:
        return ""
    line = match.group(1).strip().splitlines()[0].strip()
    return line


def parse_active_id(value: str) -> str | None:
    match = re.match(r"(M\d+|S\d+|T\d+)", value)
    return match.group(1) if match else None


def markdown_slice_all_tasks(plan_path: Path) -> list[str]:
    """All task IDs listed in slice plan (checked or unchecked)."""
    text = plan_path.read_text(encoding="utf-8")
    return re.findall(r"- \[[ x]\] \*\*(T\d+):", text)


def markdown_slice_pending_tasks(plan_path: Path) -> list[str]:
    """Task IDs with unchecked boxes in slice plan."""
    text = plan_path.read_text(encoding="utf-8")
    return re.findall(r"- \[ \] \*\*(T\d+):", text)


def db_slice_task_counts(conn: sqlite3.Connection, milestone_id: str) -> dict[str, int]:
    rows = conn.execute(
        """
        SELECT slice_id, COUNT(*) AS n
        FROM tasks
        WHERE milestone_id = ?
        GROUP BY slice_id
        ORDER BY slice_id
        """,
        (milestone_id,),
    ).fetchall()
    return {row[0]: row[1] for row in rows}


def db_slice_pending_counts(conn: sqlite3.Connection, milestone_id: str) -> dict[str, int]:
    rows = conn.execute(
        """
        SELECT slice_id, COUNT(*) AS n
        FROM tasks
        WHERE milestone_id = ?
          AND status != 'complete'
        GROUP BY slice_id
        ORDER BY slice_id
        """,
        (milestone_id,),
    ).fetchall()
    return {row[0]: row[1] for row in rows}


def pending_gate_evaluate_count(
    conn: sqlite3.Connection, milestone_id: str, slice_id: str
) -> int:
    placeholders = ",".join("?" for _ in GATE_EVALUATE_IDS)
    row = conn.execute(
        f"""
        SELECT COUNT(*)
        FROM quality_gates
        WHERE milestone_id = ?
          AND slice_id = ?
          AND task_id = ''
          AND gate_id IN ({placeholders})
          AND status = 'pending'
        """,
        (milestone_id, slice_id, *GATE_EVALUATE_IDS),
    ).fetchone()
    return int(row[0]) if row else 0


def gate_evaluate_status(
    conn: sqlite3.Connection, milestone_id: str, slice_id: str
) -> dict[str, str]:
    placeholders = ",".join("?" for _ in GATE_EVALUATE_IDS)
    rows = conn.execute(
        f"""
        SELECT gate_id, status, verdict
        FROM quality_gates
        WHERE milestone_id = ?
          AND slice_id = ?
          AND task_id = ''
          AND gate_id IN ({placeholders})
        ORDER BY gate_id
        """,
        (milestone_id, slice_id, *GATE_EVALUATE_IDS),
    ).fetchall()
    return {row[0]: f"{row[1]} ({row[2] or '—'})" for row in rows}


def read_mcp_node(repo_root: Path) -> Path | None:
    mcp_path = repo_root / ".cursor" / "mcp.json"
    if not mcp_path.is_file():
        return None
    try:
        data = json.loads(mcp_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return None
    gsd = data.get("mcpServers", {}).get("gsd-workflow", {})
    command = gsd.get("command")
    return Path(command) if command else None


def node_major_version(node_path: Path) -> int | None:
    try:
        out = subprocess.run(
            [str(node_path), "--version"],
            check=True,
            capture_output=True,
            text=True,
        )
    except (OSError, subprocess.CalledProcessError):
        return None
    match = re.match(r"v(\d+)", out.stdout.strip())
    return int(match.group(1)) if match else None


def rebuild_state(repo_root: Path, node_path: Path) -> None:
    gsd_pi = Path.home() / ".npm-global/lib/node_modules/@opengsd/gsd-pi/dist/resources/extensions/gsd"
    bootstrap = gsd_pi / "bootstrap/dynamic-tools.js"
    doctor = gsd_pi / "doctor.js"
    if not bootstrap.is_file() or not doctor.is_file():
        raise SystemExit("Could not locate @opengsd/gsd-pi modules for rebuildState")

    script = f"""
import {{ ensureDbOpen }} from {json.dumps(str(bootstrap))};
import {{ rebuildState }} from {json.dumps(str(doctor))};
const root = {json.dumps(str(repo_root))};
const ok = await ensureDbOpen(root);
if (!ok) throw new Error('ensureDbOpen failed');
await rebuildState(root);
console.log('STATE.md rebuilt');
"""
    subprocess.run(
        [str(node_path), "--input-type=module", "-e", script],
        check=True,
    )


def run_smoke(repo_root: Path, milestone_id: str, rebuild: bool) -> Report:
    report = Report()
    gsd_dir = repo_root / ".gsd"
    db_path = gsd_dir / "gsd.db"
    state_path = gsd_dir / "STATE.md"
    milestone_dir = gsd_dir / "milestones" / milestone_id

    node_path = read_mcp_node(repo_root)
    if node_path is None:
        report.add("mcp-config", "WARN", ".cursor/mcp.json gsd-workflow node not found")
    elif not node_path.is_file():
        report.add("mcp-config", "FAIL", f"Node binary missing: {node_path}")
    else:
        major = node_major_version(node_path)
        if major is None:
            report.add("mcp-config", "WARN", f"Could not read Node version from {node_path}")
        elif major < 22:
            report.add("mcp-config", "FAIL", f"Node {major} < 22 required for GSD CLI/engine")
        else:
            report.add("mcp-config", "PASS", f"Node {major} at {node_path}")

    if not db_path.is_file():
        report.add("gsd-db", "FAIL", f"Missing {db_path}")
        return report
    report.add("gsd-db", "PASS", str(db_path))

    if not state_path.is_file():
        report.add("state-md", "FAIL", f"Missing {state_path}")
        return report

    state_content = state_path.read_text(encoding="utf-8")
    active_milestone = parse_active_id(parse_state_field(state_content, "Active Milestone") or "")
    active_slice = parse_active_id(parse_state_field(state_content, "Active Slice") or "")
    state_phase = parse_state_field(state_content, "Phase").lower()
    next_action = parse_next_action(state_content)

    if active_milestone and active_milestone != milestone_id:
        report.add(
            "active-milestone",
            "WARN",
            f"STATE.md active {active_milestone} != requested {milestone_id}",
        )

    conn = sqlite3.connect(db_path)
    try:
        db_counts = db_slice_task_counts(conn, milestone_id)
        db_pending = db_slice_pending_counts(conn, milestone_id)
        coherence_failures: list[str] = []
        print_coherence: list[str] = []

        for slice_id in SLICE_IDS:
            plan_path = milestone_dir / "slices" / slice_id / f"{slice_id}-PLAN.md"
            tasks_dir = milestone_dir / "slices" / slice_id / "tasks"
            md_total = 0
            md_pending_count = 0
            if plan_path.is_file():
                md_total = len(markdown_slice_all_tasks(plan_path))
                md_pending_count = len(markdown_slice_pending_tasks(plan_path))
            file_count = len(list(tasks_dir.glob("T*-PLAN.md"))) if tasks_dir.is_dir() else 0
            db_count = db_counts.get(slice_id, 0)
            db_pending_count = db_pending.get(slice_id, 0)

            total_ok = md_total == db_count == file_count
            pending_ok = md_pending_count == db_pending_count
            slice_ok = total_ok and pending_ok
            total_status = "OK" if total_ok else "DRIFT"
            pending_status = "OK" if pending_ok else "DRIFT"
            print_coherence.append(
                f"{slice_id}: total md={md_total} db={db_count} files={file_count} {total_status}; "
                f"pending md={md_pending_count} db={db_pending_count} {pending_status}"
            )
            if not slice_ok:
                coherence_failures.append(slice_id)

        if coherence_failures:
            report.add(
                "plan-coherence",
                "FAIL",
                "; ".join(print_coherence),
            )
        else:
            report.add("plan-coherence", "PASS", "; ".join(print_coherence))

        slice_for_gates = active_slice or "S01"
        pending_gates = pending_gate_evaluate_count(conn, milestone_id, slice_for_gates)
        gate_status = gate_evaluate_status(conn, milestone_id, slice_for_gates)
        gate_summary = ", ".join(f"{gid}={gate_status.get(gid, 'missing')}" for gid in GATE_EVALUATE_IDS)

        if pending_gates > 0:
            report.add(
                "gate-evaluate",
                "PASS",
                f"{slice_for_gates}: {pending_gates} pending ({gate_summary}) — route to gate evaluation",
            )
            expected_phase = "evaluating-gates"
        else:
            report.add(
                "gate-evaluate",
                "PASS",
                f"{slice_for_gates}: cleared ({gate_summary}) — route to execute",
            )
            expected_phase = "executing"

        stale = (
            pending_gates == 0
            and "evaluating-gates" in state_phase
        ) or (
            pending_gates > 0
            and "evaluating-gates" not in state_phase
            and state_phase not in ("executing", "execute", "pre-planning", "planning", "refining")
        )

        if stale:
            report.add(
                "state-sync",
                "FAIL",
                f"STATE phase={state_phase!r} but DB expects ~{expected_phase!r}; run with --rebuild-state",
            )
        else:
            report.add(
                "state-sync",
                "PASS",
                f"STATE phase={state_phase!r}, next={next_action[:80]}",
            )

        if rebuild:
            if node_path is None or not node_path.is_file():
                report.add("rebuild-state", "FAIL", "No Node 22+ path from mcp.json")
            else:
                rebuild_state(repo_root, node_path)
                report.add("rebuild-state", "PASS", "STATE.md regenerated from DB")
    finally:
        conn.close()

    return report


def main() -> int:
    parser = argparse.ArgumentParser(description="GSD workflow smoke checks")
    parser.add_argument(
        "--milestone",
        default="M001",
        help="Milestone id to check (default: M001)",
    )
    parser.add_argument(
        "--rebuild-state",
        action="store_true",
        help="Regenerate .gsd/STATE.md from DB after checks (requires Node 22+ from mcp.json)",
    )
    args = parser.parse_args()

    repo_root = find_repo_root(Path(__file__).resolve().parent)
    report = run_smoke(repo_root, args.milestone.upper(), args.rebuild_state)
    report.print()
    return 1 if report.failed else 0


if __name__ == "__main__":
    sys.exit(main())
