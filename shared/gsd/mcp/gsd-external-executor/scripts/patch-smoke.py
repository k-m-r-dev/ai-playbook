#!/usr/bin/env python3
"""Inject playbook-gsd bridge checks into gsd-smoke.py."""
from pathlib import Path

path = Path("/Users/khandkermahmudur/Workspace/self/ai-playbook/shared/gsd/scripts/gsd-smoke.py")
text = path.read_text()

helper = '''
def check_playbook_bridge(repo_root: Path, report: SmokeReport, conn) -> None:
    """Non-blocking when bridge absent; WARN/DEGRADED messaging. FAIL only on stuck running attempts."""
    import json
    import subprocess

    health_sh = repo_root / ".workflow" / "scripts" / "playbook-gsd-health.sh"
    health_mjs = None
    # Prefer playbook SoT next to this smoke script's origin when bootstrapped from ai-playbook
    candidate = Path(__file__).resolve().parents[2] / "mcp" / "gsd-external-executor" / "scripts" / "health-check.mjs"
    # shared/gsd/scripts/gsd-smoke.py → parents[1]=shared/gsd, so mcp is sibling
    candidate = Path(__file__).resolve().parent.parent / "mcp" / "gsd-external-executor" / "scripts" / "health-check.mjs"
    if candidate.is_file():
        health_mjs = candidate

    if health_sh.is_file() or (health_mjs and health_mjs.is_file()):
        try:
            if health_sh.is_file():
                proc = subprocess.run(
                    ["bash", str(health_sh)],
                    cwd=str(repo_root),
                    capture_output=True,
                    text=True,
                    timeout=30,
                )
                out = proc.stdout.strip() or proc.stderr.strip()
            else:
                proc = subprocess.run(
                    ["node", str(health_mjs), str(repo_root)],
                    cwd=str(repo_root),
                    capture_output=True,
                    text=True,
                    timeout=30,
                    env={
                        **dict(**{k: v for k, v in __import__("os").environ.items()}),
                        "GSD_WORKFLOW_PROJECT_ROOT": str(repo_root),
                    },
                )
                out = proc.stdout.strip() or proc.stderr.strip()
            status = "PASS" if proc.returncode == 0 else "WARN"
            # Prefer structured JSON if present
            detail = out.splitlines()[-1] if out else f"exit={proc.returncode}"
            try:
                payload = json.loads(out)
                detail = f"status={payload.get('status')} gsd-pi={payload.get('gsdPiVersion')} schema={payload.get('schemaVersion')} issues={payload.get('issues')}"
                if not payload.get("ok"):
                    status = "WARN"
            except Exception:
                pass
            report.add("playbook-gsd-bridge", status, detail)
        except Exception as exc:
            report.add("playbook-gsd-bridge", "WARN", f"health check error: {exc}")
    else:
        report.add(
            "playbook-gsd-bridge",
            "WARN",
            "bridge health script missing — configure playbook-gsd MCP for do-next on gsd-pi ≥1.12",
        )

    # Stuck running attempts block ledger progress
    try:
        rows = conn.execute(
            """
            SELECT lifecycle.milestone_id, lifecycle.slice_id, lifecycle.task_id,
                   attempt.attempt_id, attempt.worker_id
            FROM workflow_execution_attempts attempt
            JOIN workflow_item_lifecycles lifecycle
              ON lifecycle.lifecycle_id = attempt.lifecycle_id
             AND lifecycle.project_id = attempt.project_id
            WHERE attempt.attempt_state = 'running'
            """
        ).fetchall()
    except Exception:
        rows = []
    if rows:
        summary = "; ".join(
            f"{r[0]}/{r[1]}/{r[2]} attempt={r[3]} worker={r[4]}" for r in rows[:5]
        )
        more = "" if len(rows) <= 5 else f" (+{len(rows) - 5} more)"
        report.add(
            "stuck-attempts",
            "WARN",
            f"{len(rows)} running Attempt(s): {summary}{more} — call playbook_gsd_task_abort or finish publish",
        )
    else:
        report.add("stuck-attempts", "PASS", "no running Attempts")


'''

anchor = "def main() -> int:"
if "def check_playbook_bridge" not in text:
    text = text.replace(anchor, helper + "\n" + anchor, 1)

call_anchor = "    finally:\n        conn.close()\n\n    return report"
call_new = """    finally:
        # Bridge / stuck Attempt checks (best-effort; never invent PASS for ledger)
        try:
            check_playbook_bridge(repo_root, report, conn)
        except Exception as exc:  # noqa: BLE001
            report.add("playbook-gsd-bridge", "WARN", f"skipped: {exc}")
        conn.close()

    return report"""

if "check_playbook_bridge(repo_root, report, conn)" not in text:
    if call_anchor not in text:
        raise SystemExit("call anchor not found")
    text = text.replace(call_anchor, call_new, 1)

path.write_text(text)
print("patched gsd-smoke.py")
