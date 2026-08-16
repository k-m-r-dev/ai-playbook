#!/usr/bin/env python3
"""Fixture tests for the W2C ledger CLI."""
from __future__ import annotations

import re
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parents[1] / "scripts"
sys.path.insert(0, str(SCRIPTS))

import w2c  # noqa: E402


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


SLICE_PLAN = """---
MILESTONE ID: M001
SLICE ID: S01
---

# S01: Foundation

<tasks>
- [ ] **T01**: First task.
  - Files: `a.py`
  - Verify: python3 -c 'print(1)'
- [ ] **T02**: Second task.
  - Verify: python3 -c 'print(2)'
</tasks>
"""

M_ROADMAP = """# M001: demo

## Slices

- [ ] **S01: Foundation** `risk:low` `depends:[]`
"""


class W2CTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = Path(tempfile.mkdtemp(prefix="w2c-test-"))
        self.addCleanup(lambda: shutil.rmtree(self.tmp, ignore_errors=True))
        w2c.cmd_init(self.tmp)

    def test_next_milestone_id_starts_at_m001(self) -> None:
        self.assertEqual(w2c.next_milestone_id(self.tmp), "M001")

    def test_milestone_new_unique_ids(self) -> None:
        w2c.cmd_milestone_new(self.tmp, "alpha")
        w2c.cmd_milestone_new(self.tmp, "beta")
        self.assertEqual(w2c.next_milestone_id(self.tmp), "M003")
        self.assertTrue((self.tmp / ".w2c/plans/M001-alpha/M001-ROADMAP.md").is_file())
        self.assertTrue((self.tmp / ".w2c/plans/M002-beta/M002-CONTEXT.md").is_file())

    def _seed_open_tasks(self) -> None:
        w2c.cmd_milestone_new(self.tmp, "demo")
        d = self.tmp / ".w2c/plans/M001-demo"
        write(d / "M001-ROADMAP.md", M_ROADMAP)
        write(d / "M001-S01-PLAN.md", SLICE_PLAN)
        w2c.rebuild_ledger(self.tmp)

    def test_next_skips_checked_and_respects_filters(self) -> None:
        self._seed_open_tasks()
        t = w2c.next_open_task(self.tmp)
        assert t is not None
        self.assertEqual((t.mid, t.sid, t.tid), ("M001", "S01", "T01"))
        plan = d = self.tmp / ".w2c/plans/M001-demo/M001-S01-PLAN.md"
        write(plan, w2c.set_task_checked(plan.read_text(encoding="utf-8"), "T01", True))
        t2 = w2c.next_open_task(self.tmp)
        assert t2 is not None
        self.assertEqual(t2.tid, "T02")
        none = w2c.next_open_task(self.tmp, milestone="M009")
        self.assertIsNone(none)
        t3 = w2c.next_open_task(self.tmp, milestone="M001", slice_id="S01", task_id="T02")
        assert t3 is not None
        self.assertEqual(t3.tid, "T02")

    def test_complete_updates_and_refuses_unknown(self) -> None:
        self._seed_open_tasks()
        with self.assertRaises(w2c.W2CError):
            w2c.cmd_complete(self.tmp, "M001", "S01", "T99")
        self.assertEqual(w2c.cmd_complete(self.tmp, "M001", "S01", "T01"), 0)
        plan = (self.tmp / ".w2c/plans/M001-demo/M001-S01-PLAN.md").read_text(encoding="utf-8")
        self.assertIn("- [x] **T01**", plan)
        state = (self.tmp / ".w2c/STATE.md").read_text(encoding="utf-8")
        self.assertIn("T02", state)
        self.assertEqual(w2c.cmd_complete(self.tmp, "M001", "S01", "T02"), 0)
        road = (self.tmp / ".w2c/ROADMAP.md").read_text(encoding="utf-8")
        self.assertIn("**M001:", road)
        self.assertIn("DONE", [m.status for m in w2c.parse_milestones(road)])
        queue = (self.tmp / ".w2c/QUEUE.md").read_text(encoding="utf-8")
        self.assertNotIn("M001", queue)

    def test_decide_only_appends(self) -> None:
        w2c.cmd_decide(
            self.tmp, "M001", "Use CLI", "Python", "Single writer", "Yes", "human", "2026-08-16"
        )
        w2c.cmd_decide(
            self.tmp, "M001", "Keep markdown", "Yes", "Reviewable", "Yes", "human", "2026-08-16"
        )
        text = (self.tmp / ".w2c/DECISIONS.md").read_text(encoding="utf-8")
        self.assertEqual(text.count("| D001 |"), 1)
        self.assertEqual(text.count("| D002 |"), 1)
        self.assertTrue(text.index("| D001 |") < text.index("| D002 |"))

    def test_context_new_never_overwrites(self) -> None:
        w2c.cmd_context_new(self.tmp, major=False, minor=True)
        v11 = self.tmp / ".w2c/contexts/CONTEXTv1.1.md"
        self.assertTrue(v11.is_file())
        original = v11.read_text(encoding="utf-8")
        v11.write_text(original + "\nmarker\n", encoding="utf-8")
        w2c.cmd_context_new(self.tmp, major=False, minor=True)
        self.assertTrue((self.tmp / ".w2c/contexts/CONTEXTv1.2.md").is_file())
        self.assertIn("marker", v11.read_text(encoding="utf-8"))
        w2c.cmd_context_new(self.tmp, major=True, minor=False)
        self.assertTrue((self.tmp / ".w2c/contexts/CONTEXTv2.0.md").is_file())
        self.assertTrue((self.tmp / ".w2c/contexts/CONTEXTv1.0.md").is_file())

    def test_smoke_pass_on_fixture(self) -> None:
        self._seed_open_tasks()
        report = w2c.run_smoke(self.tmp)
        self.assertFalse(report.failed(), [c for c in report.checks if c.status == "FAIL"])

    def test_smoke_fail_on_id_clash_and_state_mismatch(self) -> None:
        self._seed_open_tasks()
        road = self.tmp / ".w2c/ROADMAP.md"
        text = road.read_text(encoding="utf-8")
        road.write_text(
            text + "- \u2705 **M001: duplicate** (`depends:[\u2014]`)\n",
            encoding="utf-8",
        )
        report = w2c.run_smoke(self.tmp)
        names = {c.name: c for c in report.checks}
        self.assertEqual(names["unique-milestone-ids"].status, "FAIL")
        self.assertTrue(report.failed())

        # Unique-id clash already asserted. Fresh tree for STATE vs ROADMAP mismatch.
        shutil.rmtree(self.tmp / ".w2c", ignore_errors=True)
        w2c.cmd_init(self.tmp)
        self._seed_open_tasks()
        w2c.cmd_milestone_status(self.tmp, "M001", "INPROGRESS")
        state = self.tmp / ".w2c/STATE.md"
        broken = re.sub(
            r"^- \S+ \*\*M001:\*\*",
            "- \u2705 **M001:**",
            state.read_text(encoding="utf-8"),
            count=1,
            flags=re.M,
        )
        state.write_text(broken, encoding="utf-8")
        report2 = w2c.run_smoke(self.tmp)
        names2 = {c.name: c for c in report2.checks}
        self.assertEqual(names2["state-agrees-roadmap"].status, "FAIL")
        self.assertTrue(report2.failed())

    def test_events_append_under_runtime_not_ledger_root(self) -> None:
        path = w2c.events_path(self.tmp)
        self.assertEqual(path, self.tmp / ".w2c/runtime/events.jsonl")
        self.assertEqual(
            w2c.cmd_event(
                self.tmp, "work-to-chores", "gather", "started", "M001", "S01", "T01", "begin"
            ),
            0,
        )
        self.assertTrue(path.is_file())
        self.assertFalse((self.tmp / ".w2c/events.jsonl").exists())
        recs = w2c.read_events(self.tmp)
        self.assertGreaterEqual(len(recs), 1)
        last = recs[-1]
        self.assertEqual(last["skill"], "work-to-chores")
        self.assertEqual(last["stage"], "gather")
        self.assertEqual(last["event"], "started")
        self.assertEqual(last["milestone"], "M001")
        self.assertEqual(last["slice"], "S01")
        self.assertEqual(last["task"], "T01")
        self.assertIn("ts", last)

        self.assertEqual(w2c.cmd_event(self.tmp, "do-chores", "smoke", "pass", None, None, None, ""), 0)
        self.assertEqual(
            w2c.cmd_event(self.tmp, "do-chores", "implement", "started", "M001", None, None, ""),
            0,
        )
        import contextlib
        import io

        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            self.assertEqual(w2c.cmd_events(self.tmp, tail=2, skill="do-chores"), 0)
        lines = [ln for ln in buf.getvalue().splitlines() if ln and ln != "(no events)"]
        self.assertEqual(len(lines), 2)
        for ln in lines:
            rec = __import__("json").loads(ln)
            self.assertEqual(rec["skill"], "do-chores")

        rc = w2c.main(
            [
                "--root",
                str(self.tmp),
                "event",
                "--skill",
                "w2c",
                "--stage",
                "test",
                "--event",
                "started",
                "--detail",
                "cli",
            ]
        )
        self.assertEqual(rc, 0)
        recs = w2c.read_events(self.tmp)
        self.assertEqual(recs[-1]["skill"], "w2c")
        self.assertEqual(recs[-1]["detail"], "cli")

    def test_complete_logs_under_runtime(self) -> None:
        self._seed_open_tasks()
        self.assertEqual(w2c.cmd_complete(self.tmp, "M001", "S01", "T01"), 0)
        path = w2c.events_path(self.tmp)
        self.assertTrue(path.is_file())
        self.assertEqual(path.parent.name, "runtime")
        recs = w2c.read_events(self.tmp)
        self.assertTrue(
            any(r.get("event") == "complete" and r.get("task") == "T01" for r in recs)
        )


if __name__ == "__main__":
    unittest.main()
