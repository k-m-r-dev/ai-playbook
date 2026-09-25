# DeepEval handoff

Status: later. The suite is written and not scored. Natural Scope `1.0.0` is already installed and in force. Do not withhold the skill, uninstall it, or skip narrative writing because this suite has not run.

## Why it stopped

This machine had no `OPENAI_API_KEY` and no `DEEPEVAL_MODEL`. Cursor chat models are not an API the suite can call. `CURSOR_API_KEY` was unset. `deepeval test run tests` exited 2 from `tests/conftest.py` and marked no case passed. Do not weaken that gate. Do not skip cases to get a green run.

## When a key exists

From this directory:

```bash
uv run deepeval test run tests
```

Judge: `DEEPEVAL_MODEL` when set, otherwise DeepEval's default OpenAI model (`gpt-5.4`) via `OPENAI_API_KEY`. `uv sync` is already done in `.venv` (gitignored).

## What to expect

Pass at `0.8`. A calibration failure is `0.5` or higher on a fixture that must fail, or below `0.8` on one that must pass. One break fails the draft. A draft that dodges the tempted break and breaks a different finding still fails.

| Layer | Files | Bar |
| --- | --- | --- |
| Calibrate | `fixtures/`, `tests/test_calibration.py`, `tests/metrics.py` | Clean passage passes every finding. Each `fail_*.md` breaks one finding and scores under `0.5` on that metric. `fail_checklist_lies.md` prints six "no" answers and must still fail the `DAGMetric`. `pass_revision.md` must pass. |
| Router | `tests/test_router.py`, `tests/router.py` | `ToolCorrectnessMetric`, exact match, including `load_skill` input `name`. Fiction phrasings, and the words Natural Scope / natural-scope / storyscope, call `load_skill` with exactly `natural-scope`. Commit, code, design, plan, review, README, the paper, user story, story points, incident narrative, and "write something nice" must not. |
| Generate | `tests/test_generation.py`, `tests/writer.py` | System prompt is the playbook `SKILL.md`. Each tempting prompt must keep every finding. The revision uses `ConversationalGEval`. "Write it in one sentence" may run longer. A story plus a README keeps the story under the rules and leaves the README a README. |

Findings in `tests/metrics.py`: stated lesson, single track, acceptance ending, unnamed feeling, no named text/place/work, forward-only time, morally clear hero, and the five model spines (Claude, GPT, Gemini, DeepSeek, Kimi).

## If a case fails

Tighten `../SKILL.md`, bump `metadata.version` in that same change, then:

```bash
bash scripts/install-personal-agents-hub.sh --skills natural-scope --codex --force
bash scripts/install-personal-agents-hub.sh --check-versions --skills natural-scope --no-agents
```

Rerun the suite. Do not commit a throwaway story. Do not commit `docs/story_scope_paper_review.md` unless asked.
