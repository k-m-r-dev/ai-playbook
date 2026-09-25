# DeepEval handoff

Status: later. The suite is written and not scored. Technical Scope `1.0.0` is already installed and in force. Do not withhold the skill, uninstall it, or skip a technical document because this suite has not run.

## Why it stopped

This machine had no `OPENAI_API_KEY` and no `DEEPEVAL_MODEL`. Cursor chat models are not an API the suite can call. `deepeval test run tests` exits 2 from `tests/conftest.py` and marks no case passed. Do not weaken that gate. Do not skip cases to get a green run.

## When a key exists

From this directory:

```bash
uv run deepeval test run tests
```

Judge: `DEEPEVAL_MODEL` when set, otherwise DeepEval's default OpenAI model (`gpt-5.4`) via `OPENAI_API_KEY`. Run `uv sync` here first if `.venv` is missing.

## What to expect

Pass at `0.8`. A calibration failure is `0.5` or higher on a fixture that must fail, or below `0.8` on one that must pass. One break fails the draft. A draft that dodges the tempted break and breaks a different rule still fails.

| Layer | Files | Bar |
| --- | --- | --- |
| Calibrate | `fixtures/`, `tests/test_calibration.py`, `tests/metrics.py` | Clean passage passes every rule. Each `fail_*.md` breaks one rule and scores under `0.5` on that metric. `fail_checklist_lies.md` prints five "no" answers and must still fail the `DAGMetric`. `pass_revision.md` must pass. |
| Router | `tests/test_router.py`, `tests/router.py` | `ToolCorrectnessMetric`, exact match, including `load_skill` input `name`. README, guide, RCA, report, design doc, spec, architecture note, commit message, and pull-request description call `load_skill` with exactly `technical-scope`, including when the user says "Technical Scope". Fiction calls `natural-scope`. Code, code comments, a user story, story points, and "write something nice" must not call `technical-scope`. |
| Generate | `tests/test_generation.py`, `tests/writer.py` | System prompt is the playbook `SKILL.md`. Each tempting prompt must keep every rule. The revision uses `ConversationalGEval`. "Write the commit in one sentence" may run longer. A design note plus a short story keeps the note under the rules and leaves the story a story. |

Rules in `tests/metrics.py`: short form explained first, plain words, no unrequested section, pictures only as Mermaid or a Markdown table, and a commit or pull request that stays short.

## If a case fails

Tighten `../SKILL.md`, bump `metadata.version` in that same change, then:

```bash
bash scripts/install-personal-agents-hub.sh --skills technical-scope --codex --no-agents --force
bash scripts/install-personal-agents-hub.sh --check-versions --skills technical-scope --no-agents
```

Rerun the suite. Do not commit a throwaway draft.
