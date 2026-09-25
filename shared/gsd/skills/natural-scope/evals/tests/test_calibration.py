"""Layer 1: the judge must pass a clean passage and fail a single break."""

import pytest
from deepeval.test_case import LLMTestCase

from judge import FAIL_BELOW, PASS_AT, load_fixture, unit_score
from metrics import finding_metrics, six_check_metric

_FAILS = {
    "fail_moral.md": "stated_lesson",
    "fail_single_track.md": "single_track",
    "fail_acceptance.md": "acceptance",
    "fail_body.md": "named_feeling",
    "fail_external.md": "named_reference",
    "fail_linear.md": "time_jump",
    "fail_clear_hero.md": "morally_ambiguous",
    "fail_claude.md": "claude_spine",
    "fail_gpt.md": "gpt_spine",
    "fail_gemini.md": "gemini_spine",
    "fail_deepseek.md": "deepseek_spine",
    "fail_kimi.md": "kimi_spine",
}


def _measure(metric, text: str) -> float:
    metric.measure(LLMTestCase(input="fixture", actual_output=text))
    return unit_score(metric)


def test_clean_passage_passes_every_finding():
    text = load_fixture("pass_clean.md")
    for name, metric in finding_metrics().items():
        score = _measure(metric, text)
        assert score >= PASS_AT, f"{name} scored {score}: {metric.reason}"


@pytest.mark.parametrize("fixture,finding", _FAILS.items())
def test_single_break_fails_only_that_finding(fixture, finding):
    metric = finding_metrics()[finding]
    score = _measure(metric, load_fixture(fixture))
    assert score < FAIL_BELOW, f"{finding} scored {score}: {metric.reason}"


def test_checklist_of_all_no_still_fails_when_prose_breaks():
    metric = six_check_metric()
    score = _measure(metric, load_fixture("fail_checklist_lies.md"))
    assert score < FAIL_BELOW, f"checklist lie scored {score}: {metric.reason}"


def test_revision_that_removes_the_break_passes():
    text = load_fixture("pass_revision.md")
    dag = six_check_metric()
    score = _measure(dag, text)
    assert score >= PASS_AT, f"revision checklist scored {score}: {dag.reason}"
    for name, metric in finding_metrics().items():
        score = _measure(metric, text)
        assert score >= PASS_AT, f"revision {name} scored {score}: {metric.reason}"
