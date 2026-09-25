"""Shared judge, skill text, and score normalization."""

import os
from pathlib import Path

SKILL_DIR = Path(__file__).resolve().parents[2]
FIXTURES = SKILL_DIR / "evals" / "fixtures"
PASS_AT = 0.8
FAIL_BELOW = 0.5


def model_name() -> str:
    return os.environ.get("DEEPEVAL_MODEL") or "gpt-5.4"


def skill_text() -> str:
    return (SKILL_DIR / "SKILL.md").read_text(encoding="utf-8")


def load_fixture(name: str) -> str:
    return (FIXTURES / name).read_text(encoding="utf-8")


def unit_score(metric) -> float:
    score = float(metric.score)
    if score > 1:
        score = score / 10
    return score
