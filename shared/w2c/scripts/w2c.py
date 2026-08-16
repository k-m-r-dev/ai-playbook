#!/usr/bin/env python3
"""W2C ledger CLI — the only writer of .w2c status bits."""
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Iterable

STATUS_EMOJI = {
    "PLANNING": "\U0001f4cb",
    "TODO": "\u231b",
    "PAUSED": "\u23f8\ufe0f",
    "INPROGRESS": "\U0001f504",
    "DONE": "\u2705",
    "ERROR": "\u26d4",
    "STOP": "\u23f9\ufe0f",
}
EMOJI_STATUS = {}
for _name, _emo in STATUS_EMOJI.items():
    EMOJI_STATUS[_emo] = _name
    EMOJI_STATUS[_emo.replace("\ufe0f", "")] = _name

VALID_STATUSES = tuple(STATUS_EMOJI)

_EMOJI_ALT = "|".join(
    re.escape(e)
    for e in dict.fromkeys(
        [*STATUS_EMOJI.values(), *(e.replace("\ufe0f", "") for e in STATUS_EMOJI.values())]
    )
)
MILESTONE_LINE_RE = re.compile(
    r"^- +(?P<emoji>" + _EMOJI_ALT + r")\s+\*\*(?P<id>M\d+):\s*(?P<title>.+?)\*\*"
)
SLICE_LINE_RE = re.compile(r"^- \[([ xX])\] \*\*(S\d+):")
TASK_LINE_RE = re.compile(r"^- \[([ xX])\] \*\*(T\d+)\*\*")
DECISION_ROW_RE = re.compile(r"^\| (D\d+) \|", re.M)
CONTEXT_FILE_RE = re.compile(r"^CONTEXTv(\d+)\.(\d+)\.md$")
ID_M = re.compile(r"^M\d+$")
ID_S = re.compile(r"^S\d+$")
ID_T = re.compile(r"^T\d+$")

DECISIONS_HEADER = (
    "# Decisions Register\n\n"
    "<!-- Append-only. Never edit or remove existing rows.\n"
    "     To reverse a decision, add a new row that supersedes it.\n"
    "     Read this file at the start of any planning or research phase. -->\n\n"
    "| # | When | Scope | Decision | Choice | Rationale | Revisable? | Made By |\n"
    "|---|------|-------|----------|--------|-----------|------------|---------|\n"
)

STATE_TEMPLATE = """# State\n\n**Active Milestone:** None\n**Active Slice:** None\n**Phase:** idle\n**Requirements Status:** 0 active · 0 validated · 0 deferred · 0 out of scope\n\n## Milestone Registry\n\n## Recent Decisions\n\n## Blockers\n- None\n\n## Next Action\nPlan work with work-to-chores.\n"""

ROADMAP_TEMPLATE = "# Roadmap\n\n## Milestones\n"
QUEUE_TEMPLATE = "# Queue\n"

CONTEXT_BODY = """# Project Knowledge\n\nAppend-only register of project-specific rules, patterns, and lessons learned.\nAgents read this before every unit. Add entries when you discover something worth remembering.\n## Rules\n\n| # | Scope | Rule | Why | Added |\n|---|-------|------|-----|-------|\n\n## Patterns\n\n| # | Pattern | Where | Notes |\n|---|---------|-------|-------|\n\n## Lessons Learned\n\n| # | What Happened | Root Cause | Fix | Scope |\n|---|--------------|------------|-----|-------|\n"""

M_ROADMAP_STUB = """# {mid}: {title}\n\n**Vision:**\n\n## Success Criteria\n\n## Slices\n\n## Boundary Map\n\n## In scope\n\n## Out of scope\n\n## Soft dependency\n\n## Delivery & Guardrails\n| Field | Value |\n| --- | --- |\n| Milestone / planning ID | {mid} |\n| Human-readable scope slug | {slug} |\n| Workstream name | |\n| External ticket ID | |\n| Integration strategy | trunk-direct |\n| Integration branch | |\n| Commit cadence | milestone |\n| Review unit | none |\n| Git/PR checkpoint mode | none |\n| Branch name | N/A |\n| Execution sequence | |\n| Validation commands | |\n| Completion condition | All slices verified; single commit after milestone verification; push only with explicit approval |\n| Size budget (LOC diff) | |\n\n### Guardrails\n- **Commit cadence** — one commit after the milestone is verified unless this table says otherwise. Do not commit per slice by default.\n- **Remote mutation** — no push, PR, or remote git mutation without explicit user approval.\n- **Validation** — run the validation commands in this table before each commit and before each push.\n- **Status writes** — never hand-edit STATE.md, QUEUE.md, ROADMAP status emojis, or task checkboxes. Use `.w2c/scripts/w2c.sh`.\n- **Verify loop** — a task is not complete until its Verify commands pass and requesting-code-review is clean.\n"""

M_CONTEXT_STUB = """# {mid} — {title}\n\n## Problem\n\n## Solution\n\n## Key Decisions\n\n## Out of Scope\n\n## Validation\n\n## Completion Criteria\n"""


class W2CError(Exception):
    """User-facing CLI error."""


@dataclass
class Milestone:
    mid: str
    title: str
    status: str
    emoji: str
    depends: str = "—"


@dataclass
class Task:
    mid: str
    sid: str
    tid: str
    title: str
    done: bool
    plan_path: Path
    verify: str = ""


@dataclass
class Check:
    name: str
    status: str
    detail: str = ""


class Report:
    def __init__(self) -> None:
        self.checks: list[Check] = []

    def add(self, name: str, status: str, detail: str = "") -> None:
        self.checks.append(Check(name, status, detail))

    def failed(self) -> bool:
        return any(c.status == "FAIL" for c in self.checks)

    def print(self) -> None:
        width = max((len(c.name) for c in self.checks), default=8)
        for c in self.checks:
            extra = f"  {c.detail}" if c.detail else ""
            print(f"{c.status:<4} {c.name:<{width}}{extra}")
        print("FAIL" if self.failed() else "PASS")


def die(msg: str, code: int = 1) -> None:
    print(f"error: {msg}", file=sys.stderr)
    raise SystemExit(code)


def atomic_write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(content, encoding="utf-8")
    tmp.replace(path)


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.exists() else ""


def format_datetime(dt: datetime | None = None) -> str:
    dt = dt or datetime.now().astimezone()
    offset = dt.utcoffset()
    hours = int((offset.total_seconds() if offset else 0) // 3600)
    sign = "+" if hours >= 0 else "-"
    return dt.strftime("%b %d, %Y %I:%M %p") + f" (GMT {sign}{abs(hours)})"


def find_repo_root(start: Path | None = None) -> Path:
    cur = (start or Path.cwd()).resolve()
    for p in [cur, *cur.parents]:
        if (p / ".w2c").is_dir() or (p / ".git").exists():
            return p
    return cur


def w2c_dir(root: Path) -> Path:
    return root / ".w2c"


def templates_dir(script_file: Path | None = None) -> Path | None:
    here = (script_file or Path(__file__)).resolve().parent
    cand = here.parent / "templates"
    return cand if cand.is_dir() else None


def load_template(name: str, embedded: str) -> str:
    tdir = templates_dir()
    if tdir is not None:
        path = tdir / name
        if path.is_file():
            return path.read_text(encoding="utf-8")
    return embedded


def parse_milestones(text: str) -> list[Milestone]:
    out: list[Milestone] = []
    for line in text.splitlines():
        m = MILESTONE_LINE_RE.match(line.strip() if False else line)
        if not m:
            continue
        emoji = m.group("emoji")
        status = EMOJI_STATUS.get(emoji) or EMOJI_STATUS.get(emoji.replace("\ufe0f", ""))
        if not status:
            continue
        dep_m = re.search(r"`depends:\[(.+?)\]`", line)
        out.append(
            Milestone(
                mid=m.group("id"),
                title=m.group("title").strip(),
                status=status,
                emoji=STATUS_EMOJI[status],
                depends=dep_m.group(1) if dep_m else "\u2014",
            )
        )
    return out


def parse_state_field(text: str, label: str) -> str:
    m = re.search(rf"^\*\*{re.escape(label)}:\*\*\s*(.*)$", text, re.M)
    return m.group(1).strip() if m else ""


def parse_active_id(value: str) -> str | None:
    if not value or value.lower() in {"none", "—", "-"}:
        return None
    m = re.match(r"(M\d+|S\d+)", value.strip())
    return m.group(1) if m else None


def set_state_field(text: str, label: str, value: str) -> str:
    pat = rf"^(\*\*{re.escape(label)}:\*\*)\s*.*$", 
    repl = rf"\1 {value}"
    new, n = re.subn(pat, repl, text, count=1, flags=re.M)
    if n == 0:
        raise W2CError(f"STATE.md missing field {label}")
    return new


def replace_section(text: str, heading: str, body: str) -> str:
    """Replace markdown section body until the next ## heading or EOF."""
    pat = re.compile(
        rf"(## {re.escape(heading)}\n)(.*?)(?=\n## |\Z)",
        re.S,
    )
    if not pat.search(text):
        if not text.endswith("\n"):
            text += "\n"
        return text + f"\n## {heading}\n{body}"
    return pat.sub(lambda m: m.group(1) + body, text, count=1)


def list_plan_dirs(root: Path) -> list[Path]:
    plans = w2c_dir(root) / "plans"
    if not plans.is_dir():
        return []
    return sorted(p for p in plans.iterdir() if p.is_dir() and re.match(r"M\d+-", p.name))


def plan_dir_for(root: Path, mid: str) -> Path | None:
    plans = w2c_dir(root) / "plans"
    if not plans.is_dir():
        return None
    matches = sorted(plans.glob(f"{mid}-*"))
    dirs = [p for p in matches if p.is_dir()]
    return dirs[0] if dirs else None


def slice_plan_path(root: Path, mid: str, sid: str) -> Path | None:
    d = plan_dir_for(root, mid)
    if d is None:
        return None
    p = d / f"{mid}-{sid}-PLAN.md"
    return p if p.is_file() else None


def parse_slices(text: str) -> list[tuple[str, bool, str]]:
    """Return (sid, done, title)."""
    out: list[tuple[str, bool, str]] = []
    for line in text.splitlines():
        m = re.match(r"^- \[([ xX])\] \*\*(S\d+):\s*(.+?)\*\*", line)
        if m:
            out.append((m.group(2), m.group(1).lower() == "x", m.group(3).strip()))
    return out


def parse_tasks(plan_path: Path, mid: str, sid: str) -> list[Task]:
    text = read_text(plan_path)
    tasks: list[Task] = []
    lines = text.splitlines()
    for i, line in enumerate(lines):
        m = TASK_LINE_RE.match(line)
        if not m:
            continue
        done = m.group(1).lower() == "x"
        rest = line.split("**" + m.group(2) + "**:", 1)
        title = rest[1].strip() if len(rest) == 2 else line
        title = re.sub(r"_\([^)]*\)_\s*$", "", title).strip().rstrip(".")
        verify = ""
        for follow in lines[i + 1 : i + 8]:
            vm = re.match(r"^\s+- Verify:\s*(.*)$", follow)
            if vm:
                verify = vm.group(1).strip()
                break
            if follow.startswith("- ["):
                break
        tasks.append(
            Task(
                mid=mid,
                sid=sid,
                tid=m.group(2),
                title=title or m.group(2),
                done=done,
                plan_path=plan_path,
                verify=verify,
            )
        )
    return tasks


def all_tasks(root: Path, milestones: list[Milestone] | None = None) -> list[Task]:
    ms = milestones if milestones is not None else parse_milestones(read_text(w2c_dir(root) / "ROADMAP.md"))
    found: list[Task] = []
    for mil in ms:
        d = plan_dir_for(root, mil.mid)
        if d is None:
            continue
        road = read_text(d / f"{mil.mid}-ROADMAP.md")
        slices = parse_slices(road)
        if not slices:
            for p in sorted(d.glob(f"{mil.mid}-S*-PLAN.md")):
                sm = re.search(r"-(S\d+)-PLAN\.md$", p.name)
                if sm:
                    slices.append((sm.group(1), False, ""))
        for sid, _done, _title in slices:
            p = d / f"{mil.mid}-{sid}-PLAN.md"
            if p.is_file():
                found.extend(parse_tasks(p, mil.mid, sid))
    return found


def filter_tasks(
    tasks: Iterable[Task],
    milestone: str | None = None,
    slice_id: str | None = None,
    task_id: str | None = None,
) -> list[Task]:
    out = list(tasks)
    if milestone:
        out = [t for t in out if t.mid == milestone]
    if slice_id:
        out = [t for t in out if t.sid == slice_id]
    if task_id:
        out = [t for t in out if t.tid == task_id]
    return out


def next_open_task(
    root: Path,
    milestone: str | None = None,
    slice_id: str | None = None,
    task_id: str | None = None,
) -> Task | None:
    tasks = filter_tasks(all_tasks(root), milestone, slice_id, task_id)
    for t in tasks:
        if not t.done:
            return t
    return None


def collected_ids_from_plans(root: Path) -> set[str]:
    ids: set[str] = set()
    for d in list_plan_dirs(root):
        m = re.match(r"(M\d+)-", d.name)
        if m:
            ids.add(m.group(1))
    return ids


def next_milestone_id(root: Path) -> str:
    nums: list[int] = []
    for mil in parse_milestones(read_text(w2c_dir(root) / "ROADMAP.md")):
        nums.append(int(mil.mid[1:]))
    for mid in collected_ids_from_plans(root):
        nums.append(int(mid[1:]))
    n = (max(nums) + 1) if nums else 1
    return f"M{n:03d}"


def parse_decisions(text: str) -> list[str]:
    return DECISION_ROW_RE.findall(text)


def next_decision_id(text: str) -> str:
    ids = parse_decisions(text)
    if not ids:
        return "D001"
    n = max(int(i[1:]) for i in ids) + 1
    return f"D{n:03d}"


def latest_context(root: Path) -> tuple[int, int, Path] | None:
    ctx = w2c_dir(root) / "contexts"
    if not ctx.is_dir():
        return None
    best: tuple[int, int, Path] | None = None
    for p in ctx.glob("CONTEXTv*.md"):
        m = CONTEXT_FILE_RE.match(p.name)
        if not m:
            continue
        ver = (int(m.group(1)), int(m.group(2)), p)
        if best is None or ver[:2] > best[:2]:
            best = ver
    return best


def context_frontmatter(version: str, slug: str = "") -> str:
    return (
        "---\n"
        f"version: {version}\n"
        f"datetime: {format_datetime()}\n"
        f"slug: {slug}\n"
        "---\n\n"
    )


def strip_frontmatter(text: str) -> tuple[dict[str, str], str]:
    if not text.startswith("---"):
        return {}, text
    parts = text.split("---", 2)
    if len(parts) < 3:
        return {}, text
    meta: dict[str, str] = {}
    for line in parts[1].splitlines():
        if ":" in line:
            k, v = line.split(":", 1)
            meta[k.strip()] = v.strip()
    return meta, parts[2].lstrip("\n")


def rebuild_ledger(root: Path, state_overrides: dict[str, str] | None = None) -> None:
    """Rebuild STATE registry, QUEUE, and ROADMAP-derived pointers."""
    wdir = w2c_dir(root)
    milestones = parse_milestones(read_text(wdir / "ROADMAP.md"))
    state = read_text(wdir / "STATE.md") or STATE_TEMPLATE
    overrides = state_overrides or {}

    active_m = overrides.get("active_milestone")
    if active_m is None:
        active_m = parse_state_field(state, "Active Milestone")
    active_s = overrides.get("active_slice")
    if active_s is None:
        active_s = parse_state_field(state, "Active Slice")
    phase = overrides.get("phase") or parse_state_field(state, "Phase") or "idle"
    req = parse_state_field(state, "Requirements Status") or (
        "0 active · 0 validated · 0 deferred · 0 out of scope"
    )
    blockers = "- None\n"
    bm = re.search(r"## Blockers\n(.*?)(?=\n## |\Z)", state, re.S)
    if bm and bm.group(1).strip():
        blockers = bm.group(1)
        if not blockers.endswith("\n"):
            blockers += "\n"

    nxt = next_open_task(root)
    if nxt:
        next_action = f"Execute {nxt.mid} {nxt.sid} {nxt.tid}: {nxt.title}"
    elif any(m.status not in {"DONE", "STOP"} for m in milestones):
        next_action = "Continue planned work (no open tasks in current filters)."
    else:
        next_action = "Plan work with work-to-chores."

    registry_lines = []
    for m in milestones:
        registry_lines.append(f"- {m.emoji} **{m.mid}:** {m.title}")
    registry = ("\n".join(registry_lines) + "\n") if registry_lines else "\n"

    dec_text = read_text(wdir / "DECISIONS.md")
    recent_lines = []
    rows = re.findall(
        r"^\| (D\d+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \|",
        dec_text,
        re.M,
    )
    for row in rows[-5:]:
        did, when, scope, decision, choice = (x.strip() for x in row[:5])
        recent_lines.append(f"- {did} ({when} {scope}): {decision} -> {choice}")
    recent = ("\n".join(recent_lines) + "\n") if recent_lines else "\n"

    active_m_display = active_m if active_m else "None"
    active_s_display = active_s if active_s else "None"

    new_state = (
        "# State\n\n"
        f"**Active Milestone:** {active_m_display}\n"
        f"**Active Slice:** {active_s_display}\n"
        f"**Phase:** {phase}\n"
        f"**Requirements Status:** {req}\n\n"
        f"## Milestone Registry\n{registry}\n"
        f"## Recent Decisions\n{recent}\n"
        f"## Blockers\n{blockers}"
        f"{'\n' if not blockers.endswith(chr(10)) else ''}"
        f"## Next Action\n{next_action}\n"
    )
    atomic_write(wdir / "STATE.md", new_state)

    q_lines = ["# Queue\n"]
    for m in milestones:
        if m.status != "DONE":
            q_lines.append(f"- {m.emoji} **{m.mid}: {m.title}**\n")
    atomic_write(wdir / "QUEUE.md", "".join(q_lines) if len(q_lines) > 1 else "# Queue\n")


def set_task_checked(text: str, tid: str, checked: bool = True) -> str:
    mark = "x" if checked else " "
    new, n = re.subn(
        rf"^- \[[ xX]\] \*\*({re.escape(tid)})\*\*",
        lambda m: f"- [{mark}] **{m.group(1)}**",
        text,
        count=1,
        flags=re.M,
    )
    if n != 1:
        raise W2CError(f"task {tid} not found in plan")
    return new


def set_slice_checked(text: str, sid: str, checked: bool = True) -> str:
    mark = "x" if checked else " "
    new, n = re.subn(
        rf"^- \[[ xX]\] \*\*({re.escape(sid)}):",
        lambda m: f"- [{mark}] **{m.group(1)}:",
        text,
        count=1,
        flags=re.M,
    )
    return new if n else text


def set_milestone_status_in_roadmap(text: str, mid: str, status: str) -> str:
    emoji = STATUS_EMOJI[status]
    new, n = re.subn(
        r"^- +(?:" + _EMOJI_ALT + r")\s+\*\*(" + re.escape(mid) + r"):",
        lambda m: f"- {emoji} **{m.group(1)}:",
        text,
        count=1,
        flags=re.M,
    )
    if n != 1:
        raise W2CError(f"milestone {mid} not found in ROADMAP.md")
    return new


def cmd_init(root: Path) -> int:
    wdir = w2c_dir(root)
    wdir.mkdir(parents=True, exist_ok=True)
    (wdir / "plans").mkdir(exist_ok=True)
    (wdir / "contexts").mkdir(exist_ok=True)
    (wdir / "runtime").mkdir(exist_ok=True)
    files = {
        "DECISIONS.md": load_template("DECISIONS.md", DECISIONS_HEADER),
        "ROADMAP.md": load_template("ROADMAP.md", ROADMAP_TEMPLATE),
        "STATE.md": load_template("STATE.md", STATE_TEMPLATE),
        "QUEUE.md": load_template("QUEUE.md", QUEUE_TEMPLATE),
    }
    created = []
    for name, body in files.items():
        path = wdir / name
        if not path.exists():
            atomic_write(path, body if body.endswith("\n") else body + "\n")
            created.append(name)
    ctx0 = wdir / "contexts" / "CONTEXTv1.0.md"
    if not ctx0.exists() and latest_context(root) is None:
        tpl = load_template("CONTEXTv1.0.md", context_frontmatter("1.0") + CONTEXT_BODY)
        tpl = tpl.replace("PLACEHOLDER", format_datetime())
        if "datetime:" in tpl and "PLACEHOLDER" not in tpl:
            pass
        atomic_write(ctx0, tpl if tpl.endswith("\n") else tpl + "\n")
        created.append("contexts/CONTEXTv1.0.md")
    rebuild_ledger(root)
    print("initialized .w2c/" + (f" ({', '.join(created)})" if created else " (already present)"))
    return 0


def cmd_status(root: Path) -> int:
    path = w2c_dir(root) / "STATE.md"
    if not path.exists():
        raise W2CError("STATE.md missing — run `w2c init`")
    sys.stdout.write(read_text(path))
    if not read_text(path).endswith("\n"):
        print()
    return 0


def task_to_dict(t: Task) -> dict:
    return {
        "milestone_id": t.mid,
        "slice_id": t.sid,
        "task_id": t.tid,
        "title": t.title,
        "plan_path": str(t.plan_path),
        "verify": t.verify,
    }


def cmd_next(
    root: Path,
    milestone: str | None,
    slice_id: str | None,
    task_id: str | None,
) -> int:
    t = next_open_task(root, milestone, slice_id, task_id)
    if t is None:
        print("NEXT none")
        print(json.dumps({"task": None}))
        return 0
    print(f"NEXT {t.mid} {t.sid} {t.tid} — {t.title}")
    print(json.dumps({"task": task_to_dict(t)}, indent=2))
    return 0


def cmd_complete(root: Path, mid: str, sid: str, tid: str) -> int:
    path = slice_plan_path(root, mid, sid)
    if path is None:
        raise W2CError(f"slice plan not found for {mid} {sid}")
    tasks = parse_tasks(path, mid, sid)
    match = [t for t in tasks if t.tid == tid]
    if not match:
        raise W2CError(f"unknown task {mid} {sid} {tid}")
    if match[0].done:
        raise W2CError(f"{tid} is already complete")
    atomic_write(path, set_task_checked(read_text(path), tid, True))

    d = plan_dir_for(root, mid)
    assert d is not None
    mroad_path = d / f"{mid}-ROADMAP.md"
    remaining = [t for t in parse_tasks(path, mid, sid) if not t.done]
    if not remaining and mroad_path.is_file():
        atomic_write(mroad_path, set_slice_checked(read_text(mroad_path), sid, True))

    slices = parse_slices(read_text(mroad_path)) if mroad_path.is_file() else []
    all_slices_done = bool(slices) and all(done for _s, done, _t in slices)
    road_path = w2c_dir(root) / "ROADMAP.md"
    if all_slices_done:
        atomic_write(road_path, set_milestone_status_in_roadmap(read_text(road_path), mid, "DONE"))
        nxt = next_open_task(root)
        overrides = {
            "active_milestone": f"{nxt.mid}: {nxt.title}" if nxt else "None",
            "active_slice": nxt.sid if nxt else "None",
            "phase": "idle" if nxt is None else "executing",
        }
    else:
        nxt = next_open_task(root, milestone=mid)
        mils = parse_milestones(read_text(road_path))
        mil = next((m for m in mils if m.mid == mid), None)
        if mil and mil.status in {"PLANNING", "TODO", "PAUSED"}:
            atomic_write(
                road_path, set_milestone_status_in_roadmap(read_text(road_path), mid, "INPROGRESS")
            )
        overrides = {
            "active_milestone": f"{mid}: {mil.title if mil else mid}",
            "active_slice": nxt.sid if nxt else sid,
            "phase": "executing",
        }
    rebuild_ledger(root, overrides)
    print(f"complete {mid} {sid} {tid}")
    return 0


def cmd_set(
    root: Path,
    active_milestone: str | None,
    active_slice: str | None,
    phase: str | None,
) -> int:
    overrides: dict[str, str] = {}
    if active_milestone is not None:
        mils = parse_milestones(read_text(w2c_dir(root) / "ROADMAP.md"))
        mil = next((m for m in mils if m.mid == active_milestone or m.mid == parse_active_id(active_milestone or "")), None)
        mid = parse_active_id(active_milestone) or active_milestone
        title = mil.title if mil else active_milestone
        overrides["active_milestone"] = f"{mid}: {title}" if mil else active_milestone
    if active_slice is not None:
        overrides["active_slice"] = active_slice
    if phase is not None:
        overrides["phase"] = phase
    rebuild_ledger(root, overrides)
    print("updated STATE.md")
    return 0


def cmd_milestone_status(root: Path, mid: str, status: str) -> int:
    status = status.upper()
    if status not in STATUS_EMOJI:
        raise W2CError(f"invalid status {status}; use {', '.join(VALID_STATUSES)}")
    road = w2c_dir(root) / "ROADMAP.md"
    atomic_write(road, set_milestone_status_in_roadmap(read_text(road), mid, status))
    mils = parse_milestones(read_text(road))
    mil = next((m for m in mils if m.mid == mid), None)
    overrides = {}
    if mil:
        overrides["active_milestone"] = f"{mil.mid}: {mil.title}"
        if status == "INPROGRESS":
            overrides["phase"] = "executing"
        elif status == "DONE":
            overrides["phase"] = "idle"
    rebuild_ledger(root, overrides or None)
    print(f"{mid} -> {status} {STATUS_EMOJI[status]}")
    return 0


def cmd_next_milestone_id(root: Path) -> int:
    print(next_milestone_id(root))
    return 0


def slugify(s: str) -> str:
    s = s.strip().lower()
    s = re.sub(r"[^a-z0-9]+", "-", s)
    return s.strip("-") or "milestone"


def cmd_milestone_new(root: Path, slug: str) -> int:
    slug = slugify(slug)
    mid = next_milestone_id(root)
    title = slug.replace("-", " ")
    d = w2c_dir(root) / "plans" / f"{mid}-{slug}"
    if d.exists():
        raise W2CError(f"already exists: {d}")
    d.mkdir(parents=True)
    atomic_write(d / f"{mid}-ROADMAP.md", M_ROADMAP_STUB.format(mid=mid, title=title, slug=slug))
    atomic_write(d / f"{mid}-CONTEXT.md", M_CONTEXT_STUB.format(mid=mid, title=title))
    road = w2c_dir(root) / "ROADMAP.md"
    text = read_text(road) or ROADMAP_TEMPLATE
    if not text.endswith("\n"):
        text += "\n"
    line = f"- {STATUS_EMOJI['PLANNING']} **{mid}: {title}** (`depends:[—]`)\n"
    if "## Milestones" in text:
        # append after the Milestones heading block
        if not text.endswith("\n"):
            text += "\n"
        text = text.rstrip() + "\n" + line
    else:
        text = text.rstrip() + "\n\n## Milestones\n" + line
    atomic_write(road, text if text.endswith("\n") else text + "\n")
    rebuild_ledger(
        root,
        {
            "active_milestone": f"{mid}: {title}",
            "active_slice": "None",
            "phase": "planning",
        },
    )
    print(f"created {d.relative_to(root)} ({mid})")
    return 0


def cmd_decide(
    root: Path,
    scope: str,
    decision: str,
    choice: str,
    rationale: str,
    revisable: str,
    made_by: str,
    when: str | None,
) -> int:
    path = w2c_dir(root) / "DECISIONS.md"
    text = read_text(path)
    if not text:
        text = DECISIONS_HEADER
    if "| # | When | Scope |" not in text:
        raise W2CError("DECISIONS.md missing table header")
    did = next_decision_id(text)
    when_s = when or datetime.now().astimezone().strftime("%Y-%m-%d")
    def cell(s: str) -> str:
        return s.replace("|", "\\|").strip()
    row = (
        f"| {did} | {cell(when_s)} | {cell(scope)} | {cell(decision)} | "
        f"{cell(choice)} | {cell(rationale)} | {cell(revisable)} | {cell(made_by)} |\n"
    )
    if not text.endswith("\n"):
        text += "\n"
    atomic_write(path, text + row)
    rebuild_ledger(root)
    print(did)
    return 0


def cmd_context_new(root: Path, major: bool, minor: bool) -> int:
    if major == minor:
        raise W2CError("pass exactly one of --major or --minor")
    ctx_dir = w2c_dir(root) / "contexts"
    ctx_dir.mkdir(parents=True, exist_ok=True)
    latest = latest_context(root)
    if latest is None:
        x, y, prev_path = 1, 0, None
        body = CONTEXT_BODY
        slug = ""
    else:
        x, y, prev_path = latest
        meta, body = strip_frontmatter(read_text(prev_path))
        slug = meta.get("slug", "")
        if major:
            x, y = x + 1, 0
        else:
            y = y + 1
    version = f"{x}.{y}"
    dest = ctx_dir / f"CONTEXTv{version}.md"
    if dest.exists():
        raise W2CError(f"refusing to overwrite {dest.name}")
    atomic_write(dest, context_frontmatter(version, slug) + body)
    print(dest.relative_to(root))
    return 0


def run_smoke(root: Path) -> Report:
    report = Report()
    wdir = w2c_dir(root)
    if not wdir.is_dir():
        report.add("w2c-present", "FAIL", ".w2c/ missing")
        return report
    report.add("w2c-present", "PASS")

    road = read_text(wdir / "ROADMAP.md")
    state = read_text(wdir / "STATE.md")
    queue = read_text(wdir / "QUEUE.md")
    decisions = read_text(wdir / "DECISIONS.md")

    mils = parse_milestones(road)
    seen_m: dict[str, int] = {}
    for m in mils:
        seen_m[m.mid] = seen_m.get(m.mid, 0) + 1
    dup_m = [k for k, v in seen_m.items() if v > 1]
    plan_ids = collected_ids_from_plans(root)
    clash = sorted(set(seen_m) & plan_ids)
    # unique among ROADMAP rows
    if dup_m:
        report.add("unique-milestone-ids", "FAIL", ", ".join(dup_m))
    else:
        report.add("unique-milestone-ids", "PASS")

    slice_ok = True
    task_ok = True
    details = []
    for mil in mils:
        d = plan_dir_for(root, mil.mid)
        if d is None:
            continue
        slices = parse_slices(read_text(d / f"{mil.mid}-ROADMAP.md"))
        sids = [s[0] for s in slices]
        if len(sids) != len(set(sids)):
            slice_ok = False
            details.append(f"{mil.mid} duplicate slices")
        for sid, _done, _t in slices:
            p = d / f"{mil.mid}-{sid}-PLAN.md"
            if not p.is_file():
                continue
            tids = [t.tid for t in parse_tasks(p, mil.mid, sid)]
            if len(tids) != len(set(tids)):
                task_ok = False
                details.append(f"{mil.mid}/{sid} duplicate tasks")
    report.add("unique-slice-ids", "PASS" if slice_ok else "FAIL", "; ".join(details) if not slice_ok else "")
    report.add("unique-task-ids", "PASS" if task_ok else "FAIL", "; ".join(d for d in details if "task" in d))

    active = parse_active_id(parse_state_field(state, "Active Milestone"))
    if not state:
        report.add("state-active-exists", "FAIL", "STATE.md missing")
    elif active is None:
        report.add("state-active-exists", "PASS", "None")
    elif any(m.mid == active for m in mils) or active in plan_ids:
        report.add("state-active-exists", "PASS", active)
    else:
        report.add("state-active-exists", "FAIL", f"{active} not in ROADMAP or plans/")

    # QUEUE ids subset of ROADMAP; emoji matches
    q_mils = parse_milestones(queue)
    road_map = {m.mid: m for m in mils}
    q_ok = True
    q_detail = []
    for q in q_mils:
        if q.mid not in road_map:
            q_ok = False
            q_detail.append(f"{q.mid} not in ROADMAP")
        elif q.status != road_map[q.mid].status:
            q_ok = False
            q_detail.append(f"{q.mid} status {q.status}!={road_map[q.mid].status}")
    report.add("queue-agrees-roadmap", "PASS" if q_ok else "FAIL", "; ".join(q_detail))

    # STATE registry vs ROADMAP
    reg_ok = True
    reg_detail = []
    for line in state.splitlines():
        m = re.match(r"^- (\S+) \*\*(M\d+):\*\*", line)
        if not m:
            continue
        emoji, mid = m.group(1), m.group(2)
        st = EMOJI_STATUS.get(emoji) or EMOJI_STATUS.get(emoji.replace("\ufe0f", ""))
        if mid not in road_map:
            reg_ok = False
            reg_detail.append(f"{mid} in STATE not ROADMAP")
        elif st and st != road_map[mid].status:
            reg_ok = False
            reg_detail.append(f"{mid} STATE {st} ROADMAP {road_map[mid].status}")
    report.add("state-agrees-roadmap", "PASS" if reg_ok else "FAIL", "; ".join(reg_detail))

    nxt = next_open_task(root)
    open_count = sum(1 for t in all_tasks(root) if not t.done)
    if open_count and nxt is None:
        report.add("next-agrees-checkboxes", "FAIL", "open tasks exist but next is none")
    elif nxt and nxt.done:
        report.add("next-agrees-checkboxes", "FAIL", f"{nxt.tid} marked done")
    else:
        report.add("next-agrees-checkboxes", "PASS", f"{nxt.mid} {nxt.sid} {nxt.tid}" if nxt else "none")

    if "| # | When | Scope | Decision | Choice | Rationale | Revisable? | Made By |" in decisions:
        report.add("decisions-header", "PASS")
    else:
        report.add("decisions-header", "FAIL", "missing table header")

    return report


def cmd_smoke(root: Path) -> int:
    report = run_smoke(root)
    report.print()
    return 1 if report.failed() else 0


def main_smoke(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(prog="w2c-smoke")
    p.add_argument("--root", type=Path, default=None)
    args = p.parse_args(argv)
    root = args.root.resolve() if args.root else find_repo_root()
    try:
        return cmd_smoke(root)
    except W2CError as e:
        die(str(e))
        return 1


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="w2c", description="W2C ledger CLI")
    p.add_argument("--root", type=Path, default=None, help="repo root (default: discover)")
    sub = p.add_subparsers(dest="cmd", required=True)

    sub.add_parser("init", help="create ledger stubs if missing")
    sub.add_parser("status", help="print STATE.md")
    sub.add_parser("smoke", help="ledger coherence checks")
    sub.add_parser("next-milestone-id", help="print next unused M###")

    n = sub.add_parser("next", help="next open task")
    n.add_argument("--milestone", default=None)
    n.add_argument("--slice", dest="slice_id", default=None)
    n.add_argument("--task", dest="task_id", default=None)

    c = sub.add_parser("complete", help="mark a task done")
    c.add_argument("--milestone", required=True)
    c.add_argument("--slice", dest="slice_id", required=True)
    c.add_argument("--task", dest="task_id", required=True)

    s = sub.add_parser("set", help="update active pointer")
    s.add_argument("--active-milestone", default=None)
    s.add_argument("--active-slice", default=None)
    s.add_argument("--phase", default=None)

    ms = sub.add_parser("milestone-status", help="set milestone status")
    ms.add_argument("mid")
    ms.add_argument("status")

    mn = sub.add_parser("milestone-new", help="allocate M### and create stubs")
    mn.add_argument("--slug", required=True)

    d = sub.add_parser("decide", help="append a decisions row")
    d.add_argument("--scope", required=True)
    d.add_argument("--decision", required=True)
    d.add_argument("--choice", required=True)
    d.add_argument("--rationale", required=True)
    d.add_argument("--revisable", default="Yes")
    d.add_argument("--made-by", default="collaborative")
    d.add_argument("--when", default=None)

    cx = sub.add_parser("context-new", help="write a new CONTEXTvX.Y.md")
    g = cx.add_mutually_exclusive_group(required=True)
    g.add_argument("--major", action="store_true")
    g.add_argument("--minor", action="store_true")
    return p


def dispatch(args: argparse.Namespace) -> int:
    root = args.root.resolve() if args.root else find_repo_root()
    cmd = args.cmd
    if cmd == "init":
        return cmd_init(root)
    if cmd == "status":
        return cmd_status(root)
    if cmd == "smoke":
        return cmd_smoke(root)
    if cmd == "next":
        return cmd_next(root, args.milestone, args.slice_id, args.task_id)
    if cmd == "complete":
        return cmd_complete(root, args.milestone, args.slice_id, args.task_id)
    if cmd == "set":
        return cmd_set(root, args.active_milestone, args.active_slice, args.phase)
    if cmd == "milestone-status":
        return cmd_milestone_status(root, args.mid, args.status)
    if cmd == "next-milestone-id":
        return cmd_next_milestone_id(root)
    if cmd == "milestone-new":
        return cmd_milestone_new(root, args.slug)
    if cmd == "decide":
        return cmd_decide(
            root,
            args.scope,
            args.decision,
            args.choice,
            args.rationale,
            args.revisable,
            args.made_by,
            args.when,
        )
    if cmd == "context-new":
        return cmd_context_new(root, args.major, args.minor)
    raise W2CError(f"unknown command {cmd}")


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        return dispatch(args)
    except W2CError as e:
        print(f"error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
